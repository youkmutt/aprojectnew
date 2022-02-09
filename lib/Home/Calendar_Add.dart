import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:aprojectnew/utils/db_profile.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:select_dialog/select_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../FirstPage.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:intl/intl.dart';
import '../controller/api.dart' as myAPI;
import '../utils/db_menu.dart' as MenuProvider;
import 'package:http/http.dart' as http;

class Calendar_Add extends StatefulWidget {
  @override
  _Calendar_AddState createState() => _Calendar_AddState();
}

class _Calendar_AddState extends State<Calendar_Add> with WidgetsBindingObserver {

  SharedPreferences prefs;
  double fontSize = 16;
  dynamic selectActivityType,activityDetail,ddlProject,ddlEmp,ddlIssue;
  AddData addData = null;
  List<String> tempMember = [];
  List<String> tempIssue = [];
  String activityType = "No value selected",txtProjectName = "No value selected";

  TextEditingController activityName = new TextEditingController();
  TextEditingController projectName = new TextEditingController();
  DateTime startDate;
  TextEditingController txtStartDate = new TextEditingController();
  DateTime endDate;
  TextEditingController txtEndDate = new TextEditingController();
  TextEditingController activityDescription= new TextEditingController();

  List<int> hour = [];
  List<int> minute = [];
  int startHour =0,startMinute =0;
  int endHour =0,endMinute =0;

  List<File>  attachedFile;

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<bool> _onBackPressed() {
    return Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder: (context) => HomePage()),(e) => false);
  }

  Future<void> asyncMethod() async {
    EasyLoading.show(status: 'loading...');

    prefs = await SharedPreferences.getInstance();
    prefs.getDouble('FontSize') == null
        ? prefs.setDouble('FontSize', 16)
        : prefs.getDouble('FontSize');
    fontSize = prefs.getDouble('FontSize');

    for(int i=0;i<60;i++){
      if(i<24){
        hour.add(i);
      }
      minute.add(i);
    }
    addData = AddData(
        null,
        null,
        null,
        null,
        null,
        '00',
        '00',
        '00',
        '00',
        null,
        null,
        [],
        [],
        [],
        null
    );

    await getDDL();
    await getDDLProject();
    await getDDLMember();

    EasyLoading.dismiss();
    setState(() {});
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

  Future<dynamic> getDDL() async {
    EasyLoading.show(status: 'loading...');
    await GlobalConfiguration().loadFromAsset("app_settings");
    GlobalConfiguration cfg = new GlobalConfiguration();

    dynamic body = jsonEncode(<String, dynamic>{
      "module": "activityType",
      "target": "list",
      "token": prefs.getString('Token'),
      "jsonStr": jsonEncode(<String, dynamic>{
        'code': null,
        'name': null,
      })
    });

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        var response = await myAPI.API().apiPost(
            cfg.getValue("api_menu"), body);
        EasyLoading.dismiss();
        if (response.statusCode == 200) {
          dynamic json = jsonDecode(response.body);
          if(json['Status']==401){
            clearEnvironment();
          }else{
            selectActivityType = json['Data'];
            setState(() {});
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

  Future<dynamic> getDDLProject() async {
    EasyLoading.show(status: 'loading...');
    await GlobalConfiguration().loadFromAsset("app_settings");
    GlobalConfiguration cfg = new GlobalConfiguration();

    dynamic body = jsonEncode(<String, dynamic>{
      "module": "master",
      "target": "project",
      "token": prefs.getString('Token'),
      "jsonStr": "",
    });

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        var response = await myAPI.API().apiPost(
            cfg.getValue("api_menu"), body);
        EasyLoading.dismiss();
        if (response.statusCode == 200) {
          dynamic json = jsonDecode(response.body);
          if(json['Status']==401){
            clearEnvironment();
          }else{

            dynamic temp = json['Data'];
            List<dynamic> disProject = [];
            for (var pp in temp) {
              disProject.add(pp['ID']);
            }
            var listProject = disProject.toSet().toList();

            ddlProject = [];
            for(var i in listProject){
              ddlProject.add(temp.firstWhere((e) => e['ID'] == i));
            }

            setState(() {});
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

  Future<dynamic> getDDLMember() async {
    EasyLoading.show(status: 'loading...');
    await GlobalConfiguration().loadFromAsset("app_settings");
    GlobalConfiguration cfg = new GlobalConfiguration();

    dynamic body = jsonEncode(<String, dynamic>{
      "module": "activity",
      "target": "emplist",
      "token": prefs.getString('Token'),
      "jsonStr": "",
    });

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        var response = await myAPI.API().apiPost(
            cfg.getValue("api_menu"), body);
        EasyLoading.dismiss();
        if (response.statusCode == 200) {
          dynamic json = jsonDecode(response.body);
          if(json['Status']==401){
            clearEnvironment();
          }else{
            ddlEmp = [];
            for(var i in json['Data']){
              ddlEmp.add(<String, String>
              {
                'ID' : null,
                'EmployeeID' : i['EmployeeID'],
                'Name' : i['Name'],
                'Role' : i['Role'],
                'delete' : null,
              });
            }

            setState(() {});
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

  Future<dynamic> getDDLIssue() async {
    EasyLoading.show(status: 'loading...');
    await GlobalConfiguration().loadFromAsset("app_settings");
    GlobalConfiguration cfg = new GlobalConfiguration();

    dynamic body = jsonEncode(<String, dynamic>{
      "module": "activity",
      "target": "issue",
      "token": prefs.getString('Token'),
      "jsonStr": jsonEncode(<String, dynamic>{
        'projectid': addData.projectid,
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
          }else {
            ddlIssue = [];
            tempIssue = [];
            addData.issue = [];
            for(var i in json['Data']){
              ddlIssue.add(<String, String>
              {
                'ID' : null,
                'IssueID' : i['IssueID'],
                'IssueType' : i['IssueType'],
                'ReportBy' : i['ReportBy'],
                'Description' : i['Description'],
                'AssignTo' : i['AssignTo'],
                'CreatedDate' : i['CreatedDate'],
                'Status' : i['Status'],
              });
            }

            setState(() {});
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

  Future<void> download(dynamic item) async {
    await GlobalConfiguration().loadFromAsset("app_settings");
    GlobalConfiguration cfg = new GlobalConfiguration();

    String url = cfg.getValue("api_menu") + '?UrlFileUpload=' + item['UrlFileUpload'] + '&fileName=' + item['FileName'];
    if (await canLaunch(url) != null)
      await launch(url);
    else
      throw "Could not launch $url";
  }

  Future<dynamic> postFile() async {
    EasyLoading.show(status: 'loading...');
    await GlobalConfiguration().loadFromAsset("app_settings");
    GlobalConfiguration cfg = new GlobalConfiguration();

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        var request = http.MultipartRequest('POST', Uri.https('aprojectlitetest.ar.co.th', '/Service/api/FileUpload/ActivityUpload'))
          ..fields['token'] = prefs.getString('Token')
          ..fields['isMobile'] = 'true';

        for (int i = 0; i < attachedFile.length; i++) {
          request.files.add(await http.MultipartFile.fromPath('files[' + i.toString() + ']', attachedFile[i].path));
        }

        try{
          var response = await request.send();
          response.stream.transform(utf8.decoder).listen((value) async {
            EasyLoading.dismiss();
            if (response.statusCode == 200) {
              dynamic json = jsonDecode(value);
              if(json['Status']==401){
                clearEnvironment();
              }else{
                setState(() {
                  for(int i =0;i<json['Data'].length;i++){
                    addData.attachment.add(json['Data'][i]);
                  }
                  attachedFile = null;
                });
              }
            } else {
              showMyDialog(context, "Please Try Again");
            }
          });
        }catch (ex){
          EasyLoading.dismiss();
          showMyDialog(context,"Internet Not Stable");
        }
      }
    } on SocketException catch (_) {
      EasyLoading.dismiss();
      showMyDialog(context, "Please Check Internet Connection");
    }
  }

  Future<dynamic> insertData() async {
    if(addData.type == null){
      showMyDialog(context,"Please select Activity Type");
      return null;
    }
    if(addData.name == null || addData.name == ''){
      showMyDialog(context,"Activity Name is required");
      return null;
    }

    if(addData.startdate == null || addData.starthour == null || addData.startminute == null){
      showMyDialog(context,"Please Input Start");
      return null;
    }
    if(addData.enddate == null || addData.endhour == null || addData.endminute == null){
      showMyDialog(context,"Please Input End");
      return null;
    }

    DateTime dateFrom = DateFormat('yyyy-MM-dd HH:mm').parse(addData.startdate + ' ' + addData.starthour + ':' + addData.startminute);
    DateTime dateTo = DateFormat('yyyy-MM-dd HH:mm').parse(addData.enddate + ' ' + addData.endhour + ':' + addData.endminute);

    if (dateTo.isAtSameMomentAs(dateFrom) || dateTo.isBefore(dateFrom)) {
      showMyDialog(context,"Start DateTime cannot more than End DateTime");
      return null;
    }
    if(attachedFile != null){
      showMyDialog(context,"Please click Upload");
      return null;
    }

    EasyLoading.show(status: 'loading...');
    await GlobalConfiguration().loadFromAsset("app_settings");
    GlobalConfiguration cfg = new GlobalConfiguration();

    dynamic body = jsonEncode(<String, dynamic>{
      "module": "activity",
      "target": "save",
      "token": prefs.getString('Token'),
      "jsonStr": json.encode(addData.toJson())
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
          }else if(json['Status']==401){
            showMyDialog(context, "Save Completed but " + json['Message'].toString());
          } else{
            await addEmail(json['Data']['JsonData']);
            setState(() {});
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

  Future<dynamic> addEmail(dynamic json) async {
    EasyLoading.show(status: 'loading...');
    await GlobalConfiguration().loadFromAsset("app_settings");
    GlobalConfiguration cfg = new GlobalConfiguration();

    dynamic body = jsonEncode(<String, dynamic>{
      "token": prefs.getString('Token'),
      "jsonStr": json
    });

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        var response = await myAPI.API().apiPost(cfg.getValue("UrlApi") + 'Calendar/CreateEvent', body);
        EasyLoading.dismiss();

        if (response.statusCode == 200) {
          dynamic json = jsonDecode(response.body);
          if(json['Status']==401){
            clearEnvironment();
          }else if(json['Status'] == 200){
            Navigator.of(context).pop(1);
          }else{
            showMyDialog(context,'Save Completed but ' + json['Data']['Message'].toString());
          }
        } else {
          showMyDialog(context,"Error " + response.statusCode.toString() + ' ' + response.reasonPhrase.toString());
        }
      }
    } on SocketException catch (_) {
      EasyLoading.dismiss();
      showMyDialog(context,"Please Check Internet Connection");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        backgroundColor: Colors.white,
        primaryColor: HexColor('#f58042'),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: HexColor('#f58042'),
          selectionColor: HexColor('#f58042'),
          selectionHandleColor: HexColor('#f58042'),
        ),
        fontFamily: 'Kanit',
        textTheme: TextTheme(bodyText2: TextStyle(fontSize: fontSize,fontWeight: FontWeight.w500,)),
        unselectedWidgetColor: Color(0xFFF58042),
        primarySwatch: const MaterialColor(
          0xFF000000,
          const <int, Color>{
            50: const Color(0xFFF58042),
            100: const Color(0xFFF58042),
            200: const Color(0xFFF58042),
            300: const Color(0xFFF58042),
            400: const Color(0xFFF58042),
            500: const Color(0xFFF58042),
            600: const Color(0xFFF58042),
            700: const Color(0xFFF58042),
            800: const Color(0xFFF58042),
            900: const Color(0xFFF58042),
          },
        ),

      ),
      home:  GestureDetector(
          onTap: () { FocusScope.of(context).requestFocus(new FocusNode()); },
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              title: Text(
                'Add Activity',
                style: TextStyle(
                  fontSize: fontSize+2,
                  color: HexColor('#f58042'),
                ),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: Icon(Icons.close, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(0),
              ),
              actions: <Widget>[
                TextButton(
                  style: TextButton.styleFrom(
                    primary: Colors.red,
                    backgroundColor: Colors.transparent,
                  ),
                  child: Text('Save',
                    style: TextStyle(
                      color: HexColor('#F58042'),
                      fontSize: fontSize,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Kanit',
                    ),
                  ),
                  onPressed: () async {
                    await insertData();
                  },
                ),
              ],
            ),
            body: WillPopScope(
              onWillPop: _onBackPressed,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: <Widget>[
                    if(selectActivityType != null && selectActivityType != [])
                      ListTile(
                        leading: Text(
                          'Activity Type',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: fontSize+2,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Kanit',
                          ),
                        ),
                        title: new Container(
                          child: new TextButton(
                            onPressed: () {
                              SelectDialog.showModal<String>(
                                context,
                                label: "Activity Type",
                                titleStyle: TextStyle(color: Colors.black),
                                showSearchBox: true,
                                searchHint: 'Activity Type',
                                selectedValue: activityType,
                                backgroundColor: Colors.white,
                                items: List<String>.generate(selectActivityType.length,(i) => selectActivityType[i]['name'],),
                                onChange: (String selected) {
                                  setState(() {
                                    activityType = selected;
                                    addData.type = selectActivityType.firstWhere((e) => e['name'] == selected)['ID'];
                                  });
                                },
                              );
                            },
                            child: Align(
                              child: Text(
                                addData == null || ddlProject == null ?
                                '' :
                                addData.type == null ? activityType :
                                selectActivityType.firstWhere((x) => x['ID'] == addData.type, orElse:()=> null) == null ?
                                '-' :
                                selectActivityType.firstWhere((x) => x['ID'] == addData.type)['name'],
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w500,
                                  color: HexColor('#f58042'),
                                ),
                              ),
                              alignment: Alignment.centerRight,
                            ),
                          ),
                        ),
                        trailing: FaIcon(FontAwesomeIcons.angleRight),
                      ),

                    new Divider(),

                    new Container(
                      padding: const EdgeInsets.only(top:10.0,left:10.0),
                      alignment: Alignment.topLeft,
                      child: Text(
                        'Activity Detail',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: fontSize+2,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Kanit',
                        ),
                      ),
                    ),
                    new Container(
                      child: new Column(
                        children: <Widget>[
                          ListTile(
                            leading: Text(
                              'Activity Name',
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w400,
                                color: HexColor('#7a7a7a'),
                              ),
                            ),
                            title: Align(
                              child: new TextFormField(
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontFamily: 'Kanit',
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.right,
                                controller: activityName,
                                textAlignVertical: TextAlignVertical.center,
                                obscureText: false,
                                keyboardType: TextInputType.multiline,
                                maxLines: null,
                                onChanged: (String str){
                                  addData.name = str;
                                },
                              ),
                              alignment: Alignment.centerRight,
                            ),
                          ),
                        ],
                      ),
                    ),

                    new Container(
                      child: new Column(
                        children: <Widget>[
                          ListTile(
                            leading: Text(
                              'Project Name',
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w400,
                                color: HexColor('#7a7a7a'),
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
                                    selectedValue: txtProjectName,
                                    backgroundColor: Colors.white,
                                    items: List<String>.generate(ddlProject.length,(i) => ddlProject[i]['ProjectName'].toString(),),
                                    onChange: (String selected) {
                                      setState(() {
                                        txtProjectName = selected;
                                        addData.projectid = ddlProject.firstWhere((e) => e['ProjectName'] == selected)['ID'];
                                        getDDLIssue();
                                      });
                                    },
                                  );
                                },
                                child: Align(
                                  child: Text(
                                    addData == null || ddlProject == null ?
                                    '' :
                                    addData.projectid == null ?
                                    txtProjectName :
                                    ddlProject.firstWhere((x) => x['ID'] == addData.projectid, orElse:()=> null) == null ?
                                    '-' :
                                    ddlProject.firstWhere((x) => x['ID'] == addData.projectid)['ProjectName'],
                                    style: TextStyle(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.w500,
                                      color: HexColor('#f58042'),
                                    ),
                                  ),
                                  alignment: Alignment.centerRight,
                                ),
                              ),
                            ),
                            trailing: FaIcon(FontAwesomeIcons.angleRight),
                          ),
                        ],
                      ),
                    ),

                    new Container(
                      padding: const EdgeInsets.only(left: 15.0,right: 15.0),
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
                                      startDate = date;
                                      setState(() { });
                                    },
                                    currentTime: startDate, locale: LocaleType.th
                                );
                              },
                              child: new TextFormField(
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontFamily: 'Kanit',
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.right,
                                readOnly: true,
                                controller: txtStartDate,
                                decoration: InputDecoration(
                                  labelText: 'Start',
                                ),
                                obscureText: false,
                                onTap: () {
                                  FocusScope.of(context).requestFocus(new FocusNode());
                                  DatePicker.showDatePicker(context,
                                      showTitleActions: true,
                                      minTime:new DateTime(DateTime.now().year - 1, 1, 1),
                                      //maxTime: DateTime.now(),
                                      onConfirm: (date) {
                                        startDate = date;
                                        txtStartDate.text = DateFormat('dd MMM yyyy').format(startDate);
                                        addData.startdate = DateFormat('yyyy-MM-dd').format(startDate);
                                        setState(() { });
                                      },
                                      currentTime: startDate, locale: LocaleType.th
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox( width: 20, ),
                          Expanded(
                            child: DropdownButtonFormField(
                              decoration: InputDecoration(
                                labelText: 'Hour',
                                labelStyle: TextStyle(
                                  fontSize: fontSize,
                                  fontFamily: 'Kanit',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              value: startHour,
                              elevation: 16,
                              onChanged: (int newValue) {
                                setState(() {
                                  startHour = newValue;
                                  addData.starthour = startHour < 10 ? '0' + startHour.toString() : startHour.toString();
                                });
                              },
                              items: hour.map<DropdownMenuItem<int>>((int value) {
                                return DropdownMenuItem<int>(
                                  value: value,
                                  child: Text(
                                    value < 10 ? '0' + value.toString() : value.toString(),
                                    style: TextStyle(
                                      fontSize: fontSize,
                                      fontFamily: 'Kanit',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          SizedBox(width: 20,),
                          Expanded(
                            child: DropdownButtonFormField(
                              decoration: InputDecoration(
                                labelText: 'Minute',
                                labelStyle: TextStyle(
                                  fontSize: fontSize,
                                  fontFamily: 'Kanit',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              value: startMinute,
                              elevation: 16,
                              onChanged: (int newValue) {
                                setState(() {
                                  startMinute = newValue;
                                  addData.startminute = startMinute < 10 ? '0' + startMinute.toString() : startMinute.toString();
                                });
                              },
                              items: minute.map<DropdownMenuItem<int>>((int value) {
                                return DropdownMenuItem<int>(
                                  value: value,
                                  child: Text(
                                    value < 10 ? '0' + value.toString() : value.toString(),
                                    style: TextStyle(
                                      fontSize: fontSize,
                                      fontFamily: 'Kanit',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    new Container(
                      padding: const EdgeInsets.only(left: 15.0,right: 15.0),
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
                                      endDate = date;
                                      setState(() { });
                                    },
                                    currentTime: endDate, locale: LocaleType.th
                                );
                              },
                              child: new TextFormField(
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontFamily: 'Kanit',
                                  fontWeight: FontWeight.w500,
                                ),
                                readOnly: true,
                                controller: txtEndDate,
                                decoration: InputDecoration(
                                  labelStyle: TextStyle(
                                    fontSize: fontSize,
                                    fontFamily: 'Kanit',
                                    fontWeight: FontWeight.w500,
                                  ),
                                  labelText: 'End',
                                ),
                                obscureText: false,
                                onTap: () {
                                  FocusScope.of(context).requestFocus(new FocusNode());
                                  DatePicker.showDatePicker(context,
                                      showTitleActions: true,
                                      minTime:new DateTime(DateTime.now().year - 1, 1, 1),
                                      //maxTime: DateTime.now(),
                                      onConfirm: (date) {
                                        endDate = date;
                                        txtEndDate.text = DateFormat('dd MMM yyyy').format(endDate);
                                        addData.enddate = DateFormat('yyyy-MM-dd').format(endDate);
                                        setState(() { });
                                      },
                                      currentTime: endDate, locale: LocaleType.th
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(width: 20,),
                          Expanded(
                            child:DropdownButtonFormField(
                              decoration: InputDecoration(
                                labelText: 'Hour',
                                labelStyle: TextStyle(
                                  fontSize: fontSize,
                                  fontFamily: 'Kanit',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              value: endHour,
                              elevation: 16,
                              onChanged: (int newValue) {
                                setState(() {
                                  endHour = newValue;
                                  addData.endhour = endHour < 10 ? '0' + endHour.toString() : endHour.toString();
                                });
                              },
                              items: hour.map<DropdownMenuItem<int>>((int value) {
                                return DropdownMenuItem<int>(
                                  value: value,
                                  child: Text(
                                    value < 10 ? '0' + value.toString() : value.toString(),
                                    style: TextStyle(
                                      fontSize: fontSize,
                                      fontFamily: 'Kanit',
                                      fontWeight: FontWeight.w500,
                                    ),),
                                );
                              }).toList(),
                            ),
                          ),
                          SizedBox(width: 20,),
                          Expanded(
                            child: DropdownButtonFormField(
                              decoration: InputDecoration(
                                labelText: 'Minute',
                                labelStyle: TextStyle(
                                  fontSize: fontSize,
                                  fontFamily: 'Kanit',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              value: endMinute,
                              elevation: 16,
                              onChanged: (int newValue) {
                                setState(() {
                                  endMinute = newValue;
                                  addData.endminute = endMinute < 10 ? '0' + endMinute.toString() : endMinute.toString();
                                });
                              },
                              items: minute.map<DropdownMenuItem<int>>((int value) {
                                return DropdownMenuItem<int>(
                                  value: value,
                                  child: Text(
                                    value < 10 ? '0' + value.toString() : value.toString(),
                                    style: TextStyle(
                                      fontSize: fontSize,
                                      fontFamily: 'Kanit',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    new Container(
                      child: new Column(
                        children: <Widget>[
                          ListTile(
                            leading: Text(
                              'Activity Description',
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w400,
                                color: HexColor('#7a7a7a'),
                              ),
                            ),
                            title: Align(
                              child: new TextFormField(
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontFamily: 'Kanit',
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.right,
                                controller: activityDescription,
                                textAlignVertical: TextAlignVertical.center,
                                obscureText: false,
                                keyboardType: TextInputType.multiline,
                                maxLines: null,
                                onChanged: (String str){
                                  addData.description = str;
                                },
                              ),
                              alignment: Alignment.centerRight,
                            ),

                            // Align(
                            //   child: Text(
                            //     addData == null ? '' : addData.description ?? '-',
                            //     style: TextStyle(
                            //       fontSize: fontSize,
                            //       fontWeight: FontWeight.w400,
                            //       color: Colors.black,
                            //     ),
                            //   ),
                            //   alignment: Alignment.centerRight,
                            // ),


                          ),
                        ],
                      ),
                    ),

                    new Divider(),

                    new Container(
                      padding: const EdgeInsets.only(top:10.0,left:10.0),
                      alignment: Alignment.topLeft,
                      child: new TextButton(
                        style: TextButton.styleFrom(
                          primary: Colors.red,
                          backgroundColor: Colors.transparent,
                          shape: RoundedRectangleBorder(side: BorderSide(
                              color: HexColor('#F58042'),
                              width: 1,
                              style: BorderStyle.solid
                          ), borderRadius: BorderRadius.circular(10)),
                          //shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                        ),
                        child: Text('+ Add Team Member',
                          style: TextStyle(
                            color: HexColor('#F58042'),
                            fontSize: fontSize-2,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Kanit',
                          ),
                        ),
                        onPressed: () async {
                          SelectDialog.showModal<String>(
                            context,
                            label: "Add Team Member",
                            showSearchBox: true,
                            searchHint: 'Team Member',
                            multipleSelectedValues: tempMember,
                            items: List<String>.generate(
                              ddlEmp.length,(i) => jsonEncode(ddlEmp[i]),
                            ),
                            itemBuilder: (context, item, isSelected) {
                              dynamic detailItem = jsonDecode(item);
                              return ListTile(
                                trailing: isSelected ? Icon(Icons.check) : null,
                                title: Text(detailItem['Name']),
                                subtitle: Text(detailItem['Role'].toString()),
                                selected: isSelected,
                              );
                            },
                            onMultipleItemsChange: (List<String> selected) {
                              setState(() {
                                tempMember = selected;
                                addData.team = jsonDecode(selected.toString());
                              });
                            },
                            okButtonBuilder: (context, onPressed) {
                              return Align(
                                alignment: Alignment.centerRight,
                                child: FloatingActionButton(
                                  onPressed: onPressed,
                                  child: Icon(Icons.check),
                                  mini: true,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    if(addData != null)
                      if(addData.team.length > 0)
                        new Container(
                          padding: const EdgeInsets.only(top:10.0),
                          alignment: Alignment.topLeft,
                          child: new Column(
                            children: <Widget>[
                              ExpansionTile(
                                leading: Text(
                                  'Team Member',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: fontSize+2,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Kanit',
                                  ),
                                ),
                                title: Text(addData == null ? '' : addData.team.where((e) => e['delete'] != 'true').length > 0 ? '+' + addData.team.where((e) => e['delete'] != 'true').length.toString() : '',
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.w500,
                                    color: HexColor('#f58042'),
                                  ),
                                ),
                                children: <Widget>[
                                  for(int i=0;i< addData.team.length;i++)
                                    if(addData.team[i]['delete'] != 'true')
                                      new Container(
                                        child: new Column(
                                          children: <Widget>[
                                            ListTile(
                                              title: Text(
                                                (i+1).toString()+'. ' + addData.team[i]['Name'],
                                                style: TextStyle(
                                                  fontSize: fontSize,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              subtitle: Text(
                                                addData.team[i]['Role'],
                                                style: TextStyle(
                                                  fontSize: fontSize,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              trailing: IconButton(
                                                icon: FaIcon(FontAwesomeIcons.trashAlt),
                                                color: Color(0xFFF58042),
                                                iconSize: 20.0,
                                                tooltip: 'Delete',
                                                onPressed: () {
                                                  setState(() {
                                                    addData.team.removeAt(i);
                                                    tempMember = [];
                                                    tempMember = List<String>.generate(addData.team.length,(i) => jsonEncode(addData.team[i]),);
                                                  });
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                ],
                              ),
                            ],
                          ),
                        ),

                    if(addData != null)
                      if(addData.projectid != null)
                        new Container(
                          padding: const EdgeInsets.only(top:10.0,left:10.0),
                          alignment: Alignment.topLeft,
                          child: new TextButton(
                            style: TextButton.styleFrom(
                              primary: Colors.red,
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(side: BorderSide(
                                  color: HexColor('#F58042'),
                                  width: 1,
                                  style: BorderStyle.solid
                              ), borderRadius: BorderRadius.circular(10)),
                              //shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                            ),
                            child: Text('+ Add Issue',
                              style: TextStyle(
                                color: HexColor('#F58042'),
                                fontSize: fontSize-2,
                                fontWeight: FontWeight.w400,
                                fontFamily: 'Kanit',
                              ),
                            ),
                            onPressed: () async {
                              SelectDialog.showModal<String>(
                                context,
                                label: "Add Issue",
                                showSearchBox: true,
                                searchHint: 'Issue',
                                multipleSelectedValues: tempIssue,
                                items: List<String>.generate(
                                  ddlIssue.length,(i) => jsonEncode(ddlIssue[i]),
                                ),
                                itemBuilder: (context, item, isSelected) {
                                  dynamic detailItem = jsonDecode(item);
                                  return ListTile(
                                    trailing: isSelected ? Icon(Icons.check) : null,
                                    title: Text(detailItem['Description']),
                                    subtitle: Text(detailItem['IssueType'].toString()),
                                    selected: isSelected,
                                  );
                                },
                                onMultipleItemsChange: (List<String> selected) {
                                  setState(() {
                                    tempIssue = selected;
                                    addData.issue = jsonDecode(selected.toString());
                                  });
                                },
                                okButtonBuilder: (context, onPressed) {
                                  return Align(
                                    alignment: Alignment.centerRight,
                                    child: FloatingActionButton(
                                      onPressed: onPressed,
                                      child: Icon(Icons.check),
                                      mini: true,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),

                    if(addData != null)
                      if(addData.projectid != null && addData.issue.length > 0)
                        if(ddlProject.firstWhere((e) => e['ID'] == addData.projectid)['ProjectName'] != '')
                          new Container(
                            padding: const EdgeInsets.only(top:10.0),
                            alignment: Alignment.topLeft,
                            child: new Column(
                              children: <Widget>[
                                ExpansionTile(
                                  leading: Text(
                                    'Issue Center',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: fontSize+2,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Kanit',
                                    ),
                                  ),
                                  title: Text(addData == null ? '' : addData.issue.length > 0 ? '+' + addData.issue.length.toString() : '',
                                    style: TextStyle(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.w500,
                                      color: HexColor('#f58042'),
                                    ),
                                  ),
                                  children: <Widget>[
                                    for(int i=0;i< addData.issue.length;i++)
                                      new Container(
                                        child: new Column(
                                          children: <Widget>[
                                            ListTile(
                                              leading: Text(
                                                'No.',
                                                style: TextStyle(
                                                  fontSize: fontSize,
                                                  fontWeight: FontWeight.w500,
                                                  color: HexColor('#7a7a7a'),
                                                ),
                                              ),
                                              title: Align(
                                                child: Text(
                                                  (i+1).toString()+'.',
                                                  style: TextStyle(
                                                    fontSize: fontSize,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                alignment: Alignment.centerRight,
                                              ),
                                            ),
                                            ListTile(
                                              leading: Text(
                                                'Issue Type Name',
                                                style: TextStyle(
                                                  fontSize: fontSize,
                                                  fontWeight: FontWeight.w500,
                                                  color: HexColor('#7a7a7a'),
                                                ),
                                              ),
                                              title: Align(
                                                child: Text(
                                                  addData.issue[i]['IssueType'],
                                                  style: TextStyle(
                                                    fontSize: fontSize,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                alignment: Alignment.centerRight,
                                              ),
                                            ),
                                            ListTile(
                                              leading: Text(
                                                'Report By',
                                                style: TextStyle(
                                                  fontSize: fontSize,
                                                  fontWeight: FontWeight.w500,
                                                  color: HexColor('#7a7a7a'),
                                                ),
                                              ),
                                              title: Align(
                                                child: Text(
                                                  addData.issue[i]['ReportBy'],
                                                  style: TextStyle(
                                                    fontSize: fontSize,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                alignment: Alignment.centerRight,
                                              ),
                                            ),
                                            ListTile(
                                              leading: Text(
                                                'Description',
                                                style: TextStyle(
                                                  fontSize: fontSize,
                                                  fontWeight: FontWeight.w500,
                                                  color: HexColor('#7a7a7a'),
                                                ),
                                              ),
                                              title: Align(
                                                child: Text(
                                                  addData.issue[i]['Description'],
                                                  style: TextStyle(
                                                    fontSize: fontSize,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                alignment: Alignment.centerRight,
                                              ),
                                            ),
                                            ListTile(
                                              leading: Text(
                                                'Assign To',
                                                style: TextStyle(
                                                  fontSize: fontSize,
                                                  fontWeight: FontWeight.w500,
                                                  color: HexColor('#7a7a7a'),
                                                ),
                                              ),
                                              title: Align(
                                                child: Text(
                                                  addData.issue[i]['AssignTo'],
                                                  style: TextStyle(
                                                    fontSize: fontSize,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                alignment: Alignment.centerRight,
                                              ),
                                            ),
                                            ListTile(
                                              leading: Text(
                                                'Create Date',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: HexColor('#7a7a7a'),
                                                ),
                                              ),
                                              title: Align(
                                                child: Text(
                                                  addData.issue[i]['CreatedDate'],
                                                  style: TextStyle(
                                                    fontSize: fontSize,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                alignment: Alignment.centerRight,
                                              ),
                                            ),
                                            ListTile(
                                              leading: Text(
                                                'Status',
                                                style: TextStyle(
                                                  fontSize: fontSize,
                                                  fontWeight: FontWeight.w500,
                                                  color: HexColor('#7a7a7a'),
                                                ),
                                              ),
                                              title: Align(
                                                child: Text(
                                                  addData.issue[i]['Status'],
                                                  style: TextStyle(
                                                    fontSize: fontSize,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                alignment: Alignment.centerRight,
                                              ),
                                            ),
                                            ListTile(
                                              leading: Text(
                                                'Action',
                                                style: TextStyle(
                                                  fontSize: fontSize,
                                                  fontWeight: FontWeight.w500,
                                                  color: HexColor('#7a7a7a'),
                                                ),
                                              ),
                                              title: Align(
                                                child: IconButton(
                                                  icon: FaIcon(FontAwesomeIcons.trashAlt),
                                                  color: Color(0xFFF58042),
                                                  iconSize: 20.0,
                                                  tooltip: 'Delete',
                                                  onPressed: () {
                                                    setState(() {
                                                      addData.issue.removeAt(i);
                                                      tempIssue = [];
                                                      tempIssue = List<String>.generate(addData.issue.length,(i) => jsonEncode(addData.issue[i]),);
                                                    });
                                                  },
                                                ),
                                                alignment: Alignment.centerRight,
                                              ),
                                            ),
                                            if(i<addData.issue.length-1)
                                              new Divider(),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                    new Container(
                      padding: const EdgeInsets.only(top:10.0,left:10.0),
                      alignment: Alignment.topLeft,
                      child:
                      Text(
                        'Attachment File',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: fontSize+2,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Kanit',
                        ),
                      ),
                    ),

                    if(attachedFile != null)
                      for(int i=0;i< attachedFile.length;i++)
                        new Container(
                          child: new Column(
                            children: <Widget>[
                              ListTile(
                                leading: Text(
                                  attachedFile == null ? '' : (i+1).toString()+'.',
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.w500,
                                    color: HexColor('#f58042'),
                                  ),
                                ),
                                title: Text(
                                  attachedFile == null ? '' : attachedFile[i].path.split('/').last,
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.w500,
                                    color: HexColor('#f58042'),
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: FaIcon(FontAwesomeIcons.trashAlt),
                                  color: Color(0xFFF58042),
                                  iconSize: 20.0,
                                  tooltip: 'Delete',
                                  onPressed: () {
                                    setState(() {
                                      i == 0 ? attachedFile = null : attachedFile.removeAt(i);
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                    new Container(
                      padding: const EdgeInsets.only(left: 15.0,right: 15.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: new TextButton(
                              style: TextButton.styleFrom(
                                primary: Colors.red,
                                backgroundColor: Colors.transparent,
                                shape: RoundedRectangleBorder(side: BorderSide(
                                    color: HexColor('#F58042'),
                                    width: 1,
                                    style: BorderStyle.solid
                                ), borderRadius: BorderRadius.circular(10)),
                                //shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                              ),
                              child: Text('+ Select File',
                                style: TextStyle(
                                  color: HexColor('#F58042'),
                                  fontSize: fontSize-2,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'Kanit',
                                ),
                              ),
                              onPressed: () async {
                                FilePickerResult result = await FilePicker.platform.pickFiles(allowMultiple: true);

                                if(result != null) {
                                  setState(() {
                                    attachedFile = result.paths.map((path) => File(path)).toList();
                                  });
                                }
                              },
                            ),
                          ),

                          if(attachedFile != null && attachedFile != [])
                            SizedBox(width: 40,),
                          if(attachedFile != null && attachedFile != [])
                            Expanded(
                              child: new TextButton(
                                style: TextButton.styleFrom(
                                  primary: Colors.red,
                                  backgroundColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(side: BorderSide(
                                      color: HexColor('#F58042'),
                                      width: 1,
                                      style: BorderStyle.solid
                                  ), borderRadius: BorderRadius.circular(10)),
                                  //shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                                ),
                                child: Text('Upload',
                                  style: TextStyle(
                                    color: HexColor('#F58042'),
                                    fontSize: fontSize-2,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: 'Kanit',
                                  ),
                                ),
                                onPressed: () async {
                                  await postFile();
                                },
                              ),
                            ),
                        ],
                      ),
                    ),

                    if(addData != null)
                      if(addData.attachment.length > 0)
                        for(int i=0;i< addData.attachment.length;i++)
                          new Container(
                            child: new Column(
                              children: <Widget>[
                                ListTile(
                                  leading: Text(
                                    (i+1).toString()+'.',
                                    style: TextStyle(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.w500,
                                      color: HexColor('#7a7a7a'),
                                    ),
                                  ),
                                  title: Text(
                                    addData.attachment[i]['FileName'],
                                    style: TextStyle(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.w500,
                                      color: HexColor('#7a7a7a'),
                                    ),
                                  ),
                                  trailing: RichText(
                                    textAlign: TextAlign.right,
                                    text: TextSpan(
                                      children: [
                                        WidgetSpan(
                                          child: IconButton(
                                            icon: FaIcon(FontAwesomeIcons.cloudDownloadAlt),
                                            color: Color(0xFFF58042),
                                            iconSize: 20.0,
                                            tooltip: 'Download',
                                            onPressed: () async {
                                              await GlobalConfiguration().loadFromAsset("app_settings");
                                              GlobalConfiguration cfg = new GlobalConfiguration();

                                              String url = cfg.getValue("download_file") + '?UrlFileUpload=' + addData.attachment[i]['UrlFileUpload'] + '&fileName=' + addData.attachment[i]['FileName'];
                                              if (await canLaunch(url) != null)
                                                await launch(url);
                                              else
                                                throw "Could not launch $url";
                                            },
                                          ),
                                        ),
                                        WidgetSpan(
                                          child: IconButton(
                                            icon: FaIcon(FontAwesomeIcons.trashAlt),
                                            color: Color(0xFFF58042),
                                            iconSize: 20.0,
                                            tooltip: 'Delete',
                                            onPressed: () {
                                              setState(() {
                                                addData.attachment.removeAt(i);
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                ),
                              ],
                            ),
                          ),

                    new Divider(),

                  ],
                ),
              ),

            ),
          )),
    );
  }

}

class AddData {

  AddData(
      this.id ,this.name, this.type, this.startdate, this.enddate, this.starthour, this.endhour,
      this.startminute,this.endminute ,this.projectid, this.description, this.team, this.issue, this.attachment,this.IsCancel
      );

  String id;
  String name;
  int type;
  String startdate;
  String enddate;
  String starthour;
  String endhour;
  String startminute;
  String endminute;
  String projectid;
  String description;
  List<dynamic> team;
  List<dynamic> issue;
  List<dynamic> attachment;
  bool IsCancel;

  // Map toJson() => {
  //   'name': name,
  //   'age': age,
  // };

  Map toJson() =>
      {
        'id': id,
        'name': name,
        'type': type,
        'startdate': startdate,
        'enddate': enddate,
        'starthour': starthour,
        'endhour': endhour,
        'startminute': startminute,
        'endminute': endminute,
        'projectid': projectid,
        'description': description,
        'team': team,
        'issue': issue,
        'attachment': attachment,
        'IsCancel': IsCancel,
      };

}