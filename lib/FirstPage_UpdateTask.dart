import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:aprojectnew/utils/db_profile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'FirstPage.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:intl/intl.dart';
import 'controller/api.dart' as myAPI;
import 'utils/db_menu.dart' as MenuProvider;

class UpdateTask extends StatefulWidget {
  @override
  _UpdateTaskState createState() => _UpdateTaskState();
}

class _UpdateTaskState extends State<UpdateTask> with WidgetsBindingObserver {

  SharedPreferences prefs;
  double fontSize = 16;
  dynamic task;
  TextEditingController progress = new TextEditingController();
  TextEditingController txtHour = new TextEditingController();
  TextEditingController txtMinute = new TextEditingController();
  TextEditingController txtDescription = new TextEditingController();
  DateTime workDate;
  TextEditingController txtWorkDate = new TextEditingController();

  Map<String,String> AssignStatus = {
    'Draft':'A01',
    'WaitingForApprove':'A02',
  };

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

    workDate = DateTime.now();
    txtWorkDate.text = DateFormat('yyyy-MM-dd').format(workDate);
    progress.text = '0';
    txtMinute.text = '0';
    txtHour.text = '0';
    prefs = await SharedPreferences.getInstance();
    task = jsonDecode(prefs.getString('UpdateTask'));
    prefs.getDouble('FontSize') == null
        ? prefs.setDouble('FontSize', 16)
        : prefs.getDouble('FontSize');
    fontSize = prefs.getDouble('FontSize');

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

  Future<dynamic> updateTaskProgress(String status) async {
    EasyLoading.show(status: 'loading...');
    await GlobalConfiguration().loadFromAsset("app_settings");
    GlobalConfiguration cfg = new GlobalConfiguration();

    var listAllJobAssign = jsonDecode(prefs.getString('listAllJobAssign'));

    var isDuplicateWorkDate = listAllJobAssign.firstWhere((x) => x['ApproveStatusName'] != 'Rejected'
        && x['ID'] !=  task['ID']
        && x['TaskID'] == task['taskID']
        && x['WorkDate'] == task['workDate']
        ,orElse: () => null
    );

    if (isDuplicateWorkDate != null) {
      showMyDialog(context,"Duplicate Work Date", "This date already has progress. Please choose another date.");
      return null;
    }

    if(progress.text == '' || txtWorkDate.text == ''){
      showMyDialog(context,"Required", "Please Input Required");
      return null;
    }

    task['progress'] = progress.text == '' ? 0 : int.parse(progress.text);
    task['workDate'] = txtWorkDate.text == '' ? null : DateFormat('yyyy-MM-dd').format(workDate);
    task['hour'] = txtHour.text == '' ? 0 : int.parse(txtHour.text) * 60;
    task['minute'] = txtMinute.text == '' ? 0 : int.parse(txtMinute.text);
    task['remark'] = txtDescription.text;

    if(task['hour'] + task['minute'] == 0){
      showMyDialog(context,"Required", "Hour and Minute must not be 0");
      return null;
    }

    if (status == 'A') task['status'] = AssignStatus['WaitingForApprove'];
    if (status == 'D') task['status'] = AssignStatus['Draft'];

    dynamic body = jsonEncode(<String, dynamic>{
      "module": "jobAssign",
      "target": "updateProgress",
      "token": prefs.getString('Token'),
      "jsonStr": jsonEncode(task)
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
            if(json['Data']['Result'] == 200){
              successDialog(context);
            }else{
              showMyDialog(context,'Fail',json['Data']['Message'].toString());
            }
          }
        } else {
          showMyDialog(context,'Fail',"Please Try Again");
        }
      }
    } on SocketException catch (_) {
      EasyLoading.dismiss();
      showMyDialog(context,'Fail',"Please Check Internet Connection");
    }
  }

  void successDialog(BuildContext context) async {
    EasyLoading.dismiss();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: Text('Success'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () async {
                  EasyLoading.dismiss();
                  Navigator.pop(context);
                  Navigator.of(context).pop(1);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        backgroundColor: Colors.white,
        primaryColor: Color(0xFFf58042),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Color(0xFFf58042),
        ),
        fontFamily: 'Kanit',
        textTheme: TextTheme(bodyText2: TextStyle(fontSize: fontSize,fontWeight: FontWeight.w500,)),
      ),
      home:  GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(new FocusNode());
          },
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              title: Text(
                'Update Task',
                style: TextStyle(
                  fontSize: fontSize+2,
                  color: Color(0xFFf58042),
                ),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: Icon(Icons.close, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(0),
              ),
            ),
            body: WillPopScope(
              onWillPop: _onBackPressed,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: <Widget>[

                    new Container(
                      padding: const EdgeInsets.only(top:10.0,left:10.0),
                      alignment: Alignment.topLeft,
                      child: Text(
                        task == null ? '' : task['projectName'] + ' - ' + task['taskName'],
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: fontSize+2,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Kanit',
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.only(left: 15.0,right: 15.0),
                      child: Row(
                        children:  [
                          Expanded(
                            child: new TextFormField(
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w400,
                              ),
                              controller: progress,
                              decoration: InputDecoration(
                                labelText: 'Progress',
                              ),
                              obscureText: false,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              keyboardType: TextInputType.number,
                              onChanged: (String str){
                                int num = int.parse(str == '' ? '0' : str);
                                num > 100 ? progress.text = '100' : progress.text = num.toString();
                                progress.selection = TextSelection.fromPosition(TextPosition(offset: progress.text.length));
                              },
                            ),
                          ),
                          SizedBox(
                            width: 20,
                          ),
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                DatePicker.showDatePicker(context,
                                    showTitleActions: true,
                                    minTime:new DateTime(DateTime.now().year - 1, 1, 1),
                                    maxTime: DateTime.now(),
                                    onConfirm: (date) {
                                      workDate = date;
                                      setState(() { });
                                    },
                                    currentTime: workDate, locale: LocaleType.th
                                );
                              },
                              child: new TextFormField(
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w400,
                                ),
                                readOnly: true,
                                controller: txtWorkDate,
                                decoration: InputDecoration(
                                  labelText: 'WorkDate',
                                ),
                                obscureText: false,
                                onTap: () {
                                  FocusScope.of(context).requestFocus(new FocusNode());
                                  DatePicker.showDatePicker(context,
                                      showTitleActions: true,
                                      minTime:new DateTime(DateTime.now().year - 1, 1, 1),
                                      maxTime: DateTime.now(),
                                      onConfirm: (date) {
                                        workDate = date;
                                        txtWorkDate.text = DateFormat('dd MMM yyyy').format(workDate);
                                        setState(() { });
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

                    Container(
                      padding: const EdgeInsets.only(left: 15.0,right: 15.0),
                      child: Row(
                        children:  [
                          Expanded(
                            child: new TextFormField(
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w400,
                              ),
                              controller: txtHour,
                              decoration: InputDecoration(
                                labelText: 'Hour',
                              ),
                              obscureText: false,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              keyboardType: TextInputType.number,
                              onChanged: (String str){
                                int num = int.parse(str == '' ? '0' : str);
                                num > 23 ? txtHour.text = '23' : txtHour.text = num.toString();
                                txtHour.selection = TextSelection.fromPosition(TextPosition(offset: txtHour.text.length));
                              },
                            ),
                          ),
                          SizedBox(
                            width: 20,
                          ),
                          Expanded(
                            child: new TextFormField(
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w400,
                              ),
                              controller: txtMinute,
                              decoration: InputDecoration(
                                labelText: 'Minute',
                              ),
                              obscureText: false,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              keyboardType: TextInputType.number,
                              onChanged: (String str){
                                int num = int.parse(str == '' ? '0' : str);
                                num > 59 ? txtMinute.text = '59' : txtMinute.text = num.toString();
                                txtMinute.selection = TextSelection.fromPosition(TextPosition(offset: txtMinute.text.length));
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.only(top: 10.0,left: 15.0,right: 15.0,bottom: 15.0),
                      child: new TextFormField(
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w400,
                        ),
                        controller: txtDescription,
                        decoration: InputDecoration(
                          labelText: 'Description',
                        ),
                        obscureText: false,
                        keyboardType: TextInputType.text,
                      ),
                    ),

                    Divider(),

                    new Container(
                      child: new Column(
                        children: <Widget>[
                          ListTile(
                            title: Text(
                              'PM Approve(%)',
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFFf58042),
                              ),
                            ),
                            trailing: new Container(
                              color: Colors.transparent,
                              child: Text(
                                task == null ? '' : task['pmApprovePercent'].toString(),
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    new Container(
                      child: new Column(
                        children: <Widget>[
                          ListTile(
                            title: Text(
                              'Approve Date',
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF7a7a7a),
                              ),
                            ),
                            trailing: new Container(
                              color: Colors.transparent,
                              child: Text(
                                task == null ? '' : task['pmApproveDate'].toString(),
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    new Container(
                      child: new Column(
                        children: <Widget>[
                          ListTile(
                            title: Text(
                              'Previous Progress(%)',
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF7a7a7a),
                              ),
                            ),
                            trailing:  new Container(
                              color: Colors.transparent,
                              child: Text(
                                task == null ? '' : task['previousProgress'].toString(),
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    new Container(
                      child: new Column(
                        children: <Widget>[
                          ListTile(
                            title: Text(
                              'Previous WorkDate',
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF7a7a7a),
                              ),
                            ),
                            trailing: new Container(
                              color: Colors.transparent,
                              child: Text(
                                task == null ? '' : task['previousWorkDate'].toString(),
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Divider(),

                    Container(
                      padding: const EdgeInsets.only(left: 15.0,right: 15.0),
                      child: Row(
                        children:  [
                          Expanded(
                            child: new TextButton(
                              style: TextButton.styleFrom(
                                primary: Colors.white, // foreground
                                backgroundColor: Color(0xFFf58042),
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                              ),
                              child: Text('Save Draft',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              onPressed: () async {
                                updateTaskProgress('D');
                              },
                            ),
                          ),
                          SizedBox(width: 10,),
                          Expanded(
                            child: new TextButton(
                              style: TextButton.styleFrom(
                                primary: Colors.red,
                                backgroundColor: Colors.transparent,
                                shape: RoundedRectangleBorder(side: BorderSide(
                                    color: Color(0xFFf58042),
                                    width: 1,
                                    style: BorderStyle.solid
                                ), borderRadius: BorderRadius.circular(10)),
                                //shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                              ),
                              child: Text('Send To Approve ',
                                style: TextStyle(
                                  color: Color(0xFFf58042),
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              onPressed: () async {
                                updateTaskProgress('A');
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                  ],
                ),
              ),

            ),
          )),
    );
  }

}


void showMyDialog(BuildContext context,String title,String message) async {

  EasyLoading.dismiss();

  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              // Text('Submit Fail'),
              Text(message),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () async {
              EasyLoading.dismiss();
              Navigator.pop(context);
            },
          ),
        ],
      );
    },
  );
}