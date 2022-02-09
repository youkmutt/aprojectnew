import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:aprojectnew/Home/Calendar_Detail.dart';
import 'package:aprojectnew/utils/db_profile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../FirstPage.dart';
import '../controller/api.dart' as myAPI;
import '../utils/db_menu.dart' as MenuProvider;

class Calendar_View extends StatefulWidget {
  @override
  _Calendar_ViewState createState() => _Calendar_ViewState();
}

class _Calendar_ViewState extends State<Calendar_View> with WidgetsBindingObserver {

  SharedPreferences prefs;
  double fontSize = 16;
  String calendarID,calendarMode;
  dynamic selectActivityType,activityDetail,ddlProject;
  AddData addData = null;

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
    calendarID = prefs.getString('CalendarDetail') == null ? '' : prefs.getString('CalendarDetail');
    calendarMode = prefs.getString('CalendarMode') == null ? '' : prefs.getString('CalendarMode');
    getDDL();
    getDDLProject();
    showEvent();
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
            ddlProject = json['Data'];
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

  Future<dynamic> showEvent() async {
    EasyLoading.show(status: 'loading...');
    await GlobalConfiguration().loadFromAsset("app_settings");
    GlobalConfiguration cfg = new GlobalConfiguration();

    dynamic body = jsonEncode(<String, dynamic>{
      "module": "activity",
      "target": "detail",
      "token": prefs.getString('Token'),
      "jsonStr": jsonEncode(<String, dynamic>{
        'id': calendarID,
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
            activityDetail = json['Data'][0];
            addData = AddData(
                activityDetail['ID'],
                activityDetail['ActivityName'],
                activityDetail['ActivityTypeID'],
                activityDetail['StartDate'] ?? '-',
                activityDetail['EndDate'] ?? '-',
                activityDetail['StartHour'] ?? '-',
                activityDetail['EndHour'] ?? '-',
                activityDetail['StartMinute'] ?? '-',
                activityDetail['EndMinute'] ?? '-',
                activityDetail['ProjectID'],
                activityDetail['Description'],
                activityDetail['Member'],
                activityDetail['Issue'],
                activityDetail['Attachement'],
                activityDetail['IsCancel']
            );

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

  Future<dynamic> cancelData() async {
    EasyLoading.show(status: 'loading...');
    await GlobalConfiguration().loadFromAsset("app_settings");
    GlobalConfiguration cfg = new GlobalConfiguration();

    dynamic body = jsonEncode(<String, dynamic>{
      "module": "activity",
      "target": "cancel",
      "token": prefs.getString('Token'),
      "jsonStr": jsonEncode(<String, dynamic>{
        'id': addData.id,
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
            if(json['Data'][0]['Result'] == 200){
              await deleteData();
              await cancelEmail(json['Data'][0]['JsonData']);
            }else{
              showMyDialog(context,json['Data'][0]['Message'].toString());
            }
          }
        } else {
          showMyDialog(context,"Cancel Fail");
        }
      }
    } on SocketException catch (_) {
      EasyLoading.dismiss();
      showMyDialog(context,"Please Check Internet Connection");
    }
  }

  Future<dynamic> cancelEmail(dynamic json) async {
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
        var response = await myAPI.API().apiPost(cfg.getValue("UrlApi") + 'Calendar/DeleteEvent', body);
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

  Future<dynamic> deleteData() async {
    EasyLoading.show(status: 'loading...');
    await GlobalConfiguration().loadFromAsset("app_settings");
    GlobalConfiguration cfg = new GlobalConfiguration();

    dynamic body = jsonEncode(<String, dynamic>{
      "module": "activity",
      "target": "delete",
      "token": prefs.getString('Token'),
      "jsonStr": jsonEncode(<String, dynamic>{
        'id': addData.id,
      })
    });

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        var response = await myAPI.API().apiPost(cfg.getValue("api_menu"), body);
        EasyLoading.dismiss();
        if (response.statusCode == 200) {
          // dynamic json = jsonDecode(response.body);
          // if(json['Status']==401){
          //   clearEnvironment();
          // }else{
          //   if(json['Data'][0]['Result'] == 200){
          //     await cancelEmail(json['Data'][0]['JsonData']);
          //   }else{
          //     showMyDialog(context,json['Data'][0]['Message'].toString());
          //   }
          // }
        } else {
          showMyDialog(context,"Remove Fail");
        }
      }
    } on SocketException catch (_) {
      EasyLoading.dismiss();
      showMyDialog(context,"Please Check Internet Connection");
    }
  }

  void cancelActivityDialog(BuildContext context) async {

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          // title: Text('AlertDialog Title'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure to Cancel and Remove Activity'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                cancelData();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
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
        primaryColor: HexColor('#f58042'),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: HexColor('#f58042'),
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
          onTap: () {
            FocusScope.of(context).requestFocus(new FocusNode());
          },
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              title: Text(
                'View Activity',
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
                if(calendarMode == 'Edit' && (addData == null ? false : addData.IsCancel == null ? true : !addData.IsCancel))
                  IconButton(
                    icon: Icon(
                      FontAwesomeIcons.edit,
                      color: Colors.black,
                      size: 20,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(2);
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
                    new Container(
                      padding: const EdgeInsets.only(top:10.0,left:10.0),
                      alignment: Alignment.topLeft,
                      child:
                      Text(
                        'Activity Type',
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
                          if(!(calendarMode == 'Edit' && (addData == null ? false : addData.IsCancel == null ? true : !addData.IsCancel)))
                            ListTile(
                              title: Text(
                                addData == null || selectActivityType == null ? '' : selectActivityType.firstWhere((x) => x['ID'] == addData.type)['name'],
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w400,
                                  color: HexColor('#7a7a7a'),
                                ),
                              ),
                            ),

                          if(calendarMode == 'Edit' && (addData == null ? false : addData.IsCancel == null ? true : !addData.IsCancel))
                            ListTile(
                              title: Text(
                                addData == null || selectActivityType == null ? '' : selectActivityType.firstWhere((x) => x['ID'] == addData.type)['name'],
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w400,
                                  color: HexColor('#7a7a7a'),
                                ),
                              ),

                              trailing: IconButton(
                                icon: FaIcon(FontAwesomeIcons.trashAlt),
                                color: Color(0xFFF58042),
                                iconSize: 20.0,
                                tooltip: 'Cancel',
                                onPressed: () {
                                  cancelActivityDialog(context);
                                },
                              ),
                            ),


                        ],
                      ),
                    ),

                    new Divider(),

                    new Container(
                      padding: const EdgeInsets.only(top:10.0,left:10.0),
                      alignment: Alignment.topLeft,
                      child:
                      Text(
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
                              child: Text(
                                addData == null ? '' : addData.name ?? '-',
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
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
                            title: Align(
                              child: Text(
                                addData == null || ddlProject == null ?
                                '' :
                                addData.projectid == null ?
                                '-' :
                                ddlProject.firstWhere((x) => x['ID'] == addData.projectid, orElse:()=> null) == null ?
                                '-' :
                                ddlProject.firstWhere((x) => x['ID'] == addData.projectid)['ProjectName'],
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
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
                              'Start',
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w400,
                                color: HexColor('#7a7a7a'),
                              ),
                            ),
                            title: Align(
                              child: Text(
                                addData == null ? '' : DateFormat('dd MMM yyyy HH:mm').format(DateFormat('yyyy-MM-dd HH:mm').parse(addData.startdate + ' ' + addData.starthour + ':' + addData.startminute)),
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
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
                              'End',
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w400,
                                color: HexColor('#7a7a7a'),
                              ),
                            ),
                            title: Align(
                              child: Text(
                                addData == null ? '' : DateFormat('dd MMM yyyy HH:mm').format(DateFormat('yyyy-MM-dd HH:mm').parse(addData.enddate + ' ' + addData.endhour + ':' + addData.endminute)),
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
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
                              'Activity Description',
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w400,
                                color: HexColor('#7a7a7a'),
                              ),
                            ),
                            title: Align(
                              child: Text(
                                addData == null ? '' : addData.description ?? '-',
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black,
                                ),
                              ),
                              alignment: Alignment.centerRight,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if(addData != null)
                      if(addData.team.length == 0)
                        new Container(
                          padding: const EdgeInsets.only(top:10.0,left:10.0),
                          alignment: Alignment.topLeft,
                          child:
                          Text(
                            'Team Member',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: fontSize+2,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Kanit',
                            ),
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
                                title: Text(addData == null ? '' : addData.team.length > 0 ? '+' + addData.team.length.toString() : '',
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.w500,
                                    color: HexColor('#f58042'),
                                  ),
                                ),
                                children: <Widget>[
                                  for(int i=0;i< addData.team.length;i++)
                                    new Container(
                                      child: new Column(
                                        children: <Widget>[
                                          ListTile(
                                            leading: Text(
                                              (i+1).toString()+'.' + addData.team[i]['Name'],
                                              style: TextStyle(
                                                fontSize: fontSize,
                                                fontWeight: FontWeight.w500,
                                                color: HexColor('#7a7a7a'),
                                              ),
                                            ),
                                            title: Align(
                                              child: Text(
                                                addData.team[i]['Role'],
                                                style: TextStyle(
                                                  fontSize: fontSize,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              alignment: Alignment.centerRight,
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
                      if(addData.issue.length > 0)
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
                                                fontSize: fontSize,
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
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                    if(addData != null)
                      if(addData.attachment.length > 0)
                        new Container(
                          padding: const EdgeInsets.only(top:10.0,left:10.0),
                          alignment: Alignment.topLeft,
                          child: Text(
                            'Attachment File',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: fontSize+2,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Kanit',
                            ),
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
                                    (i+1).toString(),
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
                                  trailing: new IconButton(
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
}