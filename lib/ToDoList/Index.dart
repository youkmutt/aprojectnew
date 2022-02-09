import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:slimy_card/slimy_card.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:wave/config.dart';
import 'package:wave/wave.dart';
import '../FirstPage.dart';
import '../controller/api.dart' as myAPI;
import '../utils/db_menu.dart' as MenuProvider;
import 'package:aprojectnew/utils/db_profile.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:select_dialog/select_dialog.dart';

class ToDoIndexPage extends StatefulWidget {
  @override
  _ToDoIndexState createState() => _ToDoIndexState();
}

class _ToDoIndexState extends State<ToDoIndexPage> with WidgetsBindingObserver {

  SharedPreferences prefs;
  double fontSize = 16;

  bool enableFab = false;
  bool addFab = false;
  dynamic toDo = [],taskList=[];
  List<Color> gradientBackGround = [
    Colors.blue[500],
    Colors.blue[400],
    Colors.blue[300],
    Colors.blue[200],
  ];

  final double _initFabHeight = 120.0;
  double _fabHeight = 10;
  double _panelHeightOpen = 0;
  double _panelHeightClosed = 95.0;
  DateTime workDate;
  TextEditingController txtWorkDate = new TextEditingController();
  PanelController _pc = new PanelController();
  PanelController _pc2 = new PanelController();

  TextEditingController txtDescription = new TextEditingController();
  DateTime addDate;
  TextEditingController txtAddDate = new TextEditingController();
  String addTask = null;
  String edtTask = "No value selected";

  Map<String,dynamic> add = {
    'ID': null,
    'Description': null,
    'TaskID': null,
    'TodoDate': null,
  };

  TextEditingController edtDescription = new TextEditingController();
  DateTime edtDate;
  TextEditingController txtEdtDate = new TextEditingController();

  @override
  void initState() {
    asyncMethod();
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void clearEnvironment() async {
    EasyLoading.show(status: 'loading...');
    var checkingDrop = await DBProvider.db.deleteUser();
    while (checkingDrop!=0){
      checkingDrop = await DBProvider.db.deleteUser();
    }

    var menuDrop = await MenuProvider.DBProvider.db.deleteMenu();
    while (menuDrop!=0){
      menuDrop = await MenuProvider.DBProvider.db.deleteMenu();
    }

    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.clear();

    EasyLoading.dismiss();
    tokenDialog(context);
  }

  Future<void> asyncMethod() async {
    EasyLoading.show(status: 'loading...');

    prefs = await SharedPreferences.getInstance();
    prefs.getDouble('FontSize') == null
        ? prefs.setDouble('FontSize', 16)
        : prefs.getDouble('FontSize');
    fontSize = prefs.getDouble('FontSize');
    workDate = DateTime.now();
    txtWorkDate.text = DateFormat('yyyy-MM-dd').format(workDate);

    addDate = DateTime.now();
    txtAddDate.text = DateFormat('dd MMM yyyy').format(addDate);

    await getDDL();
    await getData();

    EasyLoading.dismiss();
    setState(() {});
  }

  Future<dynamic> getData() async {
    EasyLoading.show(status: 'loading...');

    prefs = await SharedPreferences.getInstance();
    prefs.getDouble('FontSize') == null
        ? prefs.setDouble('FontSize', 16)
        : prefs.getDouble('FontSize');
    fontSize = prefs.getDouble('FontSize');

    await GlobalConfiguration().loadFromAsset("app_settings");
    GlobalConfiguration cfg = new GlobalConfiguration();

    dynamic body = jsonEncode(<String, dynamic>{
      "module": "todo",
      "target": "list",
      "token": prefs.getString('Token'),
      "jsonStr": jsonEncode(<String, dynamic>{
        'StartDate': DateFormat('yyyy-MM-dd').format(workDate),
        'EndDate': DateFormat('yyyy-MM-dd').format(workDate),
      })
    });

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        var response = await myAPI.API().apiPost(cfg.getValue("api_menu"), body);
        EasyLoading.dismiss();
        if (response.statusCode == 200) {
          dynamic json = jsonDecode(response.body);
          if(json['Status']==401){
            clearEnvironment();
          }else{
            toDo = [];

            if(enableFab){
              setState(() {
                _pc.close();
                enableFab = !enableFab;

                Future.delayed(const Duration(milliseconds: 100), () {
                  setState(() {
                    _fabHeight = 10;
                  });
                });
              });
            }

            if(addFab){
              setState(() {
                addFab = !addFab;
                _pc2.close();

                Future.delayed(const Duration(milliseconds: 100), () {
                  setState(() {
                    _fabHeight = 10;
                  });
                });
              });
            }

            setState(() {
              toDo = json['Data'] ?? [];
            });
          }
        } else {
          showMyDialog(context, "Please Try Again");
        }
      }
    } on SocketException catch (_) {
      EasyLoading.dismiss();
      showMyDialog(context, "Please Check Internet Connection");
    }
  }

  Future<dynamic> getDDL() async {
    EasyLoading.show(status: 'loading...');
    await GlobalConfiguration().loadFromAsset("app_settings");
    GlobalConfiguration cfg = new GlobalConfiguration();

    dynamic body = jsonEncode(<String, dynamic>{
      "module": "jobAssign",
      "target": "list",
      "token": prefs.getString('Token'),
      "jsonStr": "",
    });

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        var response = await myAPI.API().apiPost(cfg.getValue("api_menu"), body);
        EasyLoading.dismiss();
        if (response.statusCode == 200) {
          dynamic json = jsonDecode(response.body);
          if(json['Status']==401){
            clearEnvironment();
          }else{
            setState(() {taskList = json['Data']['InProgressJob'] ?? [];});
          }
        } else {
          showMyDialog(context, "Please Try Again");
        }
      }
    } on SocketException catch (_) {
      EasyLoading.dismiss();
      showMyDialog(context, "Please Check Internet Connection");
    }
  }

  Future<dynamic> addTodoList() async {
    EasyLoading.show(status: 'loading...');
    await GlobalConfiguration().loadFromAsset("app_settings");
    GlobalConfiguration cfg = new GlobalConfiguration();

    add['Description'] = txtDescription.text;

    if(add['Description'] == null || add['Description'] == ''){
      return showMyDialog(context, "Please Input Description");
    }

    dynamic body = jsonEncode(<String, dynamic>{
      "module": "todo",
      "target": "save",
      "token": prefs.getString('Token'),
      "jsonStr": jsonEncode(add)
    });

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        var response = await myAPI.API().apiPost(cfg.getValue("api_menu"), body);
        EasyLoading.dismiss();
        if (response.statusCode == 200) {
          dynamic json = jsonDecode(response.body);
          if(json['Status']==401){
            clearEnvironment();
          }else if(json['Data']['Result'] != 200){
            showMyDialog(context, json['Data']['Message']);
          }else{
            setState(() {
              txtDescription.text = "";
              addTask = null;
              addDate = DateTime.now();
              txtAddDate.text = DateFormat('dd MMM yyyy').format(addDate);

              add = {
                'ID': null,
                'Description': null,
                'TaskID': null,
                'TodoDate': null,
              };

              addFab = !addFab;

              _pc2.close();
              getData();
              Future.delayed(const Duration(milliseconds: 100), () {
                setState(() {
                  _fabHeight = 10;
                });
              });
            });
          }
        } else {
          showMyDialog(context, "Please Try Again");
        }
      }
    } on SocketException catch (_) {
      EasyLoading.dismiss();
      showMyDialog(context, "Please Check Internet Connection");
    }
  }

  Future<dynamic> updateTodoList() async {
    EasyLoading.show(status: 'loading...');
    await GlobalConfiguration().loadFromAsset("app_settings");
    GlobalConfiguration cfg = new GlobalConfiguration();

    add['Description'] = edtDescription.text;

    if(add['Description'] == null || add['Description'] == ''){
      return showMyDialog(context, "Please Input Description");
    }

    dynamic body = jsonEncode(<String, dynamic>{
      "module": "todo",
      "target": "update",
      "token": prefs.getString('Token'),
      "jsonStr": jsonEncode(add)
    });
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        var response = await myAPI.API().apiPost(cfg.getValue("api_menu"), body);
        EasyLoading.dismiss();
        if (response.statusCode == 200) {
          dynamic json = jsonDecode(response.body);
          if(json['Status']==401){
            clearEnvironment();
          }else if(json['Data']['Result'] != 200){
            showMyDialog(context, json['Data']['Message']);
          }else{
            await getData();
            setState(() {
              edtDescription.text = "";
              addTask = null;
              edtDate = DateTime.now();
              txtEdtDate.text = DateFormat('dd MMM yyyy').format(addDate);

              add = {
                'ID': null,
                'Description': null,
                'TaskID': null,
                'TodoDate': null,
              };

              enableFab = !enableFab;
              addTask = null;
              _pc.close();
              getData();
              Future.delayed(const Duration(milliseconds: 100), () {
                setState(() {
                  _fabHeight = 10;
                });
              });
            });

          }
        } else {
          showMyDialog(context, "Please Try Again");
        }
      }
    } on SocketException catch (_) {
      EasyLoading.dismiss();
      showMyDialog(context, "Please Check Internet Connection");
    }
  }

  Future<dynamic> updateCompleteTodoList(dynamic item) async {
    EasyLoading.show(status: 'loading...');
    await GlobalConfiguration().loadFromAsset("app_settings");
    GlobalConfiguration cfg = new GlobalConfiguration();

    item['IsComplete'] = !item['IsComplete'];
    dynamic body = jsonEncode(<String, dynamic>{
      "module": "todo",
      "target": "update",
      "token": prefs.getString('Token'),
      "jsonStr": jsonEncode(item)
    });
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        var response = await myAPI.API().apiPost(cfg.getValue("api_menu"), body);
        EasyLoading.dismiss();
        if (response.statusCode == 200) {
          dynamic json = jsonDecode(response.body);
          if(json['Status']==401){
            clearEnvironment();
          }else if(json['Data']['Result'] != 200){
            showMyDialog(context, json['Data']['Message']);
          }else{
            await getData();
          }
        } else {
          showMyDialog(context, "Please Try Again");
        }
      }
    } on SocketException catch (_) {
      EasyLoading.dismiss();
      showMyDialog(context, "Please Check Internet Connection");
    }
  }

  Future<dynamic> deleteTodoList(dynamic item) async {
    EasyLoading.show(status: 'loading...');
    await GlobalConfiguration().loadFromAsset("app_settings");
    GlobalConfiguration cfg = new GlobalConfiguration();

    item['SystemFlag'] = 0;
    dynamic body = jsonEncode(<String, dynamic>{
      "module": "todo",
      "target": "update",
      "token": prefs.getString('Token'),
      "jsonStr": jsonEncode(item)
    });
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        var response = await myAPI.API().apiPost(cfg.getValue("api_menu"), body);
        EasyLoading.dismiss();
        if (response.statusCode == 200) {
          dynamic json = jsonDecode(response.body);
          if(json['Status']==401){
            clearEnvironment();
          }else if(json['Data']['Result'] != 200){
            showMyDialog(context, json['Data']['Message']);
          }else{
            await getData();
          }
        } else {
          showMyDialog(context, "Please Try Again");
        }
      }
    } on SocketException catch (_) {
      EasyLoading.dismiss();
      showMyDialog(context, "Please Check Internet Connection");
    }
  }

  @override
  Widget build(BuildContext context) {
    _panelHeightOpen = MediaQuery.of(context).size.height * .80;

    return Scaffold(
      body: Stack(
        children: <Widget>[
          AnimatedPositioned(
            duration: Duration(milliseconds: 500),
            curve: Curves.easeOutQuad,
            child: WaveWidget(
              config: CustomConfig(
                colors: [
                  Colors.white,
                  Colors.white70,
                  Colors.white60,
                ],
                durations: [35000, 19440, 10800],
                heightPercentages: [0.15, 0.10, 0.05],
                blur: null,
              ),
              backgroundColor: Color(0xfff58042),
              size: Size(double.infinity, double.infinity),
              waveAmplitude: 2,
            ),
          ),
          StreamBuilder(
            initialData: false,
            stream: slimyCard.stream, //Stream of SlimyCard
            builder: ((BuildContext context, AsyncSnapshot snapshot) {
              return ListView(
                padding: EdgeInsets.all(10),
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  if(toDo != null && toDo.length > 0)
                    for(var item in toDo)
                      Container(
                        padding: EdgeInsets.all(10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [

                            SlimyCard(
                              topCardWidget: topCardWidget(item),
                              color:item['IsComplete'] == true ? Colors.greenAccent : Colors.blue[200],
                              bottomCardWidget: bottomCardWidget(item),
                            ),
                          ],
                        ),
                      ),
                ],
              );
            }),
          ),

          Container(
            padding: const EdgeInsets.only(left: 15.0,right: 15.0,top: 15.0,),
            child: Row(
              children:  [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      DatePicker.showDatePicker(context,
                          showTitleActions: true,
                          minTime:new DateTime(DateTime.now().year - 1, 1, 1),
                          //maxTime: DateTime.now(),
                          onConfirm: (date) {
                            workDate = date;
                            txtWorkDate.text = DateFormat('dd MMM yyyy').format(workDate);
                            setState(() { getData(); });
                          },
                          currentTime: workDate, locale: LocaleType.th
                      );
                    },
                    child: new TextFormField(
                      style: TextStyle(
                        fontSize: fontSize,
                        fontFamily: 'Kanit',
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      readOnly: true,
                      controller: txtWorkDate,
                      decoration: InputDecoration(
                        labelText: 'Date',
                      ),
                      obscureText: false,
                      onTap: () {
                        FocusScope.of(context).requestFocus(new FocusNode());
                        DatePicker.showDatePicker(context,
                            showTitleActions: true,
                            minTime:new DateTime(DateTime.now().year - 1, 1, 1),
                            //maxTime: DateTime.now(),
                            onConfirm: (date) {
                              workDate = date;
                              txtWorkDate.text = DateFormat('dd MMM yyyy').format(workDate);
                              setState(() { getData(); });
                            },
                            currentTime: workDate, locale: LocaleType.th
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          if(enableFab)
            SlidingUpPanel(
              maxHeight: _panelHeightOpen,
              minHeight: _panelHeightClosed,
              controller: _pc,
              parallaxEnabled: true,
              parallaxOffset: .5,
              //body: _body(),
              panelBuilder: (sc) => _panel(sc),
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18.0),
                  topRight: Radius.circular(18.0)),
              onPanelSlide: (double pos) => setState(() {
                _fabHeight = pos * (_panelHeightOpen - _panelHeightClosed) + _initFabHeight;
              }),
            ),

          if(addFab)
            SlidingUpPanel(
              maxHeight: _panelHeightOpen,
              minHeight: _panelHeightClosed,
              controller: _pc2,
              parallaxEnabled: true,
              parallaxOffset: .5,
              //body: _body(),
              panelBuilder: (sc) => _panelAdd(sc),
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18.0),
                  topRight: Radius.circular(18.0)),
              onPanelSlide: (double pos) => setState(() {
                _fabHeight = pos * (_panelHeightOpen - _panelHeightClosed) + _initFabHeight;
              }),
            ),

          if(!enableFab)
            Positioned(
              right: 20.0,
              bottom: _fabHeight,
              child: new FloatingActionButton(
                heroTag: "btn1",
                tooltip: 'Add',
                backgroundColor:  Color(0xFFf58042),
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    if(!addFab){
                      if(!enableFab){
                        add['ID'] = null;
                        add['Description'] = null;
                        add['TaskID'] = null;
                        add['SystemFlag'] = 1;
                        add['IsComplete'] = 0;
                        add['TodoDate'] = DateFormat('yyyy-MM-dd').format(addDate);


                        addFab = true;
                        _fabHeight = _initFabHeight;

                        txtDescription.text = "";
                        addTask = null;

                        Future.delayed(const Duration(milliseconds: 100), () {
                          setState(() {
                            _pc2.open();
                          });
                        });
                      }
                    }
                  });
                },
              ),
            ),

        ],
      ),
    );
  }

  Widget topCardWidget(dynamic item) {
    return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            stops: [0.1, 0.5, 0.7, 0.9],
            colors: gradientBackGround,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
      child:  ListView(
        padding: EdgeInsets.all(10),
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.edit),
                color: Colors.white,
                iconSize: 20.0,
                tooltip: 'edit',
                onPressed: () => {
                  setState(() {
                    if(!addFab){
                      enableFab=true;
                      edtDescription.text = item['Description'];
                      edtDate = DateFormat("yyyy-MM-ddTHH:mm:ss").parse(item['TodoDate']);
                      txtEdtDate.text =  DateFormat('dd MMM yyyy').format(edtDate);

                      var matching = taskList.firstWhere((e) => e['ID'] == item['TaskID'], orElse:()=> null);
                      addTask = matching == null ? null : jsonEncode(matching);

                      add['ID'] = item['ID'];
                      add['Description'] = item['Description'];
                      add['TaskID'] = item['TaskID'];
                      add['SystemFlag'] = item['SystemFlag'];
                      add['IsComplete'] = item['IsComplete'];
                      add['TodoDate'] = DateFormat('yyyy-MM-dd').format(edtDate);

                      Future.delayed(const Duration(milliseconds: 100), () {
                        setState(() {
                          _pc.open();
                        });
                      });
                    }
                  })
                },
              ),
              IconButton(
                icon: Icon(Icons.check_circle_outline),
                color: item['IsComplete']==true ? Colors.greenAccent : Colors.white,
                iconSize: 20.0,
                tooltip: 'complete',
                onPressed: () async => {
                  await updateCompleteTodoList(item)
                },
              ),
              IconButton(
                icon: Icon(Icons.delete_outline),
                color: Colors.white,
                iconSize: 20.0,
                tooltip: 'delete',
                onPressed: () async => {
                  await deleteTodoList(item)
                },
              ),
            ],
          ),
          SizedBox(height: 15),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                item['Description'],
                style: TextStyle(color: Colors.white, fontSize: fontSize),
              ),
            ],
          ),
          SizedBox(height: 15),
        ],
      ),
    );

  }

  Widget bottomCardWidget(dynamic item) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          stops: [0.1, 0.5, 0.7, 0.9],
          colors: gradientBackGround,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListView(
        padding: EdgeInsets.all(10),
        children: <Widget>[
          Text(
            item['TaskName'] ?? '',
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _panel(ScrollController sc) {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: ListView(
        controller: sc,
        children: <Widget>[
          SizedBox(height: 12.0,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              new TextButton(
                style: TextButton.styleFrom(
                  //primary: Colors.red,
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(side: BorderSide(
                      color: Color(0xFFf58042),
                      width: 1,
                      style: BorderStyle.solid
                  ), borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: Color(0xFFf58042),
                    fontSize: fontSize,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                onPressed: () async {
                  if(!addFab){
                    setState(() {
                      enableFab = !enableFab;
                      _pc.close();

                      Future.delayed(const Duration(milliseconds: 100), () {
                        setState(() {
                          _fabHeight = 10;
                        });
                      });
                    });
                  }
                },
              ),
              new TextButton(
                style: TextButton.styleFrom(
                  //primary: Colors.red,
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(side: BorderSide(
                      color: Color(0xFFf58042),
                      width: 1,
                      style: BorderStyle.solid
                  ), borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Save',
                  style: TextStyle(
                    color: Color(0xFFf58042),
                    fontSize: fontSize,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                onPressed: () async {
                  if(enableFab){
                    await updateTodoList();
                  }
                },
              ),
            ],
          ),
          SizedBox(height: 18.0,),
          Container(
            padding: const EdgeInsets.only(top: 10.0,left: 15.0,right: 15.0,bottom: 15.0),
            child: new TextFormField(
              style: TextStyle(
                fontSize: fontSize,
                fontFamily: 'Kanit',
                fontWeight: FontWeight.w500,
              ),
              controller: edtDescription,
              decoration: InputDecoration(
                labelText: 'Description',
              ),
              obscureText: false,
              keyboardType: TextInputType.text,
            ),
          ),
          ListTile(
            leading: Text(
              'Project - Task',
              style: TextStyle(
                color: Colors.black,
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                fontFamily: 'Kanit',
              ),
            ),
            title: new Container(
              child: new TextButton(
                onPressed: () {
                  SelectDialog.showModal<String>(
                    context,
                    label: "Project Name",
                    titleStyle: TextStyle(color: Colors.black),
                    showSearchBox: true,
                    searchHint: 'Project Name',
                    selectedValue: addTask,
                    backgroundColor: Colors.white,
                    items: List<String>.generate(
                      taskList.length,(i) => jsonEncode(taskList[i]),
                    ),
                    itemBuilder: (context, item, isSelected) {
                      dynamic detailItem = jsonDecode(item);
                      return ListTile(
                        trailing: isSelected ? Icon(Icons.check) : null,
                        title: Text(detailItem['ProjectName']),
                        subtitle: Text(detailItem['TaskName'].toString()),
                        selected: isSelected,
                      );
                    },
                    onChange: (String selected) {
                      setState(() {
                        addTask = selected;
                        dynamic choosedItem = jsonDecode(selected.toString());
                        add['TaskID'] = choosedItem['ID'];
                      });
                    },
                  );
                },
                child: Align(
                  child: Text(
                    addTask == null ? "No value selected" : jsonDecode(addTask)['ProjectName'] + ' - ' + jsonDecode(addTask)['TaskName'],
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFf58042),
                    ),
                  ),
                  alignment: Alignment.centerRight,
                ),
              ),
            ),
            trailing: FaIcon(FontAwesomeIcons.angleRight),
          ),
          Container(
            padding: const EdgeInsets.only(top: 10.0,left: 15.0,right: 15.0,bottom: 15.0),
            child: TextButton(
              onPressed: () {
                DatePicker.showDatePicker(context,
                    showTitleActions: true,
                    minTime:new DateTime(DateTime.now().year - 1, 1, 1),
                    //maxTime: DateTime.now(),
                    onConfirm: (date) {
                      setState(() {
                        edtDate = date;
                        txtEdtDate.text = DateFormat('dd MMM yyyy').format(edtDate);
                        add['TodoDate'] = DateFormat('yyyy-MM-dd').format(edtDate);
                      });
                    },
                    currentTime: edtDate, locale: LocaleType.th
                );
              },
              child: new TextFormField(
                style: TextStyle(
                  fontSize: fontSize,
                  fontFamily: 'Kanit',
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                readOnly: true,
                controller: txtEdtDate,
                decoration: InputDecoration(
                  labelText: 'Date',
                ),
                obscureText: false,
                onTap: () {
                  FocusScope.of(context).requestFocus(new FocusNode());
                  DatePicker.showDatePicker(context,
                      showTitleActions: true,
                      minTime:new DateTime(DateTime.now().year - 1, 1, 1),
                      //maxTime: DateTime.now(),
                      onConfirm: (date) {
                        setState(() {
                          edtDate = date;
                          txtEdtDate.text = DateFormat('dd MMM yyyy').format(edtDate);
                          add['TodoDate'] = DateFormat('yyyy-MM-dd').format(edtDate);
                        });
                      },
                      currentTime: edtDate, locale: LocaleType.th
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panelAdd(ScrollController sc) {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: ListView(
        controller: sc,
        children: <Widget>[
          SizedBox(height: 12.0,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              new TextButton(
                style: TextButton.styleFrom(
                  //primary: Colors.red,
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(side: BorderSide(
                      color: Color(0xFFf58042),
                      width: 1,
                      style: BorderStyle.solid
                  ), borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Close',
                  style: TextStyle(
                    color: Color(0xFFf58042),
                    fontSize: fontSize,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                onPressed: () {
                  if(!enableFab){
                    setState(() {
                      addFab = !addFab;
                      _pc2.close();

                      Future.delayed(const Duration(milliseconds: 100), () {
                        setState(() {
                          _fabHeight = 10;
                        });
                      });
                    });
                  }

                },
              ),
              new TextButton(
                style: TextButton.styleFrom(
                  //primary: Colors.red,
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(side: BorderSide(
                      color: Color(0xFFf58042),
                      width: 1,
                      style: BorderStyle.solid
                  ), borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Save',
                  style: TextStyle(
                    color: Color(0xFFf58042),
                    fontSize: fontSize,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                onPressed: () async {
                  if(!enableFab){
                    await addTodoList();
                  }
                },
              ),
            ],
          ),
          SizedBox(height: 18.0,),
          Container(
            padding: const EdgeInsets.only(top: 10.0,left: 15.0,right: 15.0,bottom: 15.0),
            child: new TextFormField(
              style: TextStyle(
                fontSize: fontSize,
                fontFamily: 'Kanit',
                fontWeight: FontWeight.w500,
              ),
              controller: txtDescription,
              decoration: InputDecoration(
                labelText: 'Description',
              ),
              obscureText: false,
              keyboardType: TextInputType.text,
            ),
          ),
          ListTile(
            leading: Text(
              'Project - Task',
              style: TextStyle(
                color: Colors.black,
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                fontFamily: 'Kanit',
              ),
            ),
            title: new Container(
              child: new TextButton(
                onPressed: () {
                  SelectDialog.showModal<String>(
                    context,
                    label: "Project Name",
                    titleStyle: TextStyle(color: Colors.black),
                    showSearchBox: true,
                    searchHint: 'Project Name',
                    selectedValue: addTask,
                    backgroundColor: Colors.white,
                    items: List<String>.generate(
                      taskList.length,(i) => jsonEncode(taskList[i]),
                    ),
                    itemBuilder: (context, item, isSelected) {
                      dynamic detailItem = jsonDecode(item);
                      return ListTile(
                        trailing: isSelected ? Icon(Icons.check) : null,
                        title: Text(detailItem['ProjectName']),
                        subtitle: Text(detailItem['TaskName'].toString()),
                        selected: isSelected,
                      );
                    },
                    onChange: (String selected) {
                      setState(() {
                        addTask = selected;
                        dynamic choosedItem = jsonDecode(selected.toString());
                        add['TaskID'] = choosedItem['ID'];
                      });
                    },
                  );
                },
                child: Align(
                  child: Text(
                    addTask == null ? "No value selected" : jsonDecode(addTask)['ProjectName'] + ' - ' + jsonDecode(addTask)['TaskName'],
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFf58042),
                    ),
                  ),
                  alignment: Alignment.centerRight,
                ),
              ),
            ),
            trailing: FaIcon(FontAwesomeIcons.angleRight),
          ),
          Container(
            padding: const EdgeInsets.only(top: 10.0,left: 15.0,right: 15.0,bottom: 15.0),
            child: TextButton(
              onPressed: () {
                DatePicker.showDatePicker(context,
                    showTitleActions: true,
                    minTime:new DateTime(DateTime.now().year - 1, 1, 1),
                    //maxTime: DateTime.now(),
                    onConfirm: (date) {
                      setState(() {
                        addDate = date;
                        txtAddDate.text = DateFormat('dd MMM yyyy').format(addDate);
                        add['TodoDate'] = DateFormat('yyyy-MM-dd').format(addDate);
                      });
                    },
                    currentTime: addDate, locale: LocaleType.th
                );
              },
              child: new TextFormField(
                style: TextStyle(
                  fontSize: fontSize,
                  fontFamily: 'Kanit',
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                readOnly: true,
                controller: txtAddDate,
                decoration: InputDecoration(
                  labelText: 'Date',
                ),
                obscureText: false,
                onTap: () {
                  FocusScope.of(context).requestFocus(new FocusNode());
                  DatePicker.showDatePicker(context,
                      showTitleActions: true,
                      minTime:new DateTime(DateTime.now().year - 1, 1, 1),
                      //maxTime: DateTime.now(),
                      onConfirm: (date) {
                        setState(() {
                          addDate = date;
                          txtAddDate.text = DateFormat('dd MMM yyyy').format(addDate);
                          add['TodoDate'] = DateFormat('yyyy-MM-dd').format(addDate);
                        });
                      },
                      currentTime: addDate, locale: LocaleType.th
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

}
