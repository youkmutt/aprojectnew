import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:aprojectnew/FirstPage_UpdateTask.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aprojectnew/main.dart';
import 'package:aprojectnew/models/menuModels.dart';
import 'package:aprojectnew/models/user.dart';
import 'package:aprojectnew/utils/db_profile.dart';
import 'package:aprojectnew/controller/api.dart' as myAPI;
import 'package:aprojectnew/utils/db_menu.dart' as MenuProvider;

class IndexPage extends StatefulWidget {
  @override
  _IndexState createState() => new _IndexState();
}

class Category {
  String name;
  IconData icon;
  Category(this.name, this.icon);
}

class _IndexState extends State<IndexPage> with WidgetsBindingObserver {

  User retUser;
  List<Menu> menuList;
  dynamic taskList, listAllJobAssign;
  dynamic taskAssignProject,taskAssignList;
  dynamic listProject;
  dynamic projectList;
  TextEditingController txtRemark = new TextEditingController();
  SharedPreferences prefs;
  double fontSize = 16;

  MaterialColor white = const MaterialColor(
    0xFFFFFFFF,
    const <int, Color>{
      50: const Color(0xFFFFFFFF),
      100: const Color(0xFFFFFFFF),
      200: const Color(0xFFFFFFFF),
      300: const Color(0xFFFFFFFF),
      400: const Color(0xFFFFFFFF),
      500: const Color(0xFFFFFFFF),
      600: const Color(0xFFFFFFFF),
      700: const Color(0xFFFFFFFF),
      800: const Color(0xFFFFFFFF),
      900: const Color(0xFFFFFFFF),
    },
  );
  MaterialColor black = const MaterialColor(
    0xFF000000,
    const <int, Color>{
      50: const Color(0xFF000000),
      100: const Color(0xFF000000),
      200: const Color(0xFF000000),
      300: const Color(0xFF000000),
      400: const Color(0xFF000000),
      500: const Color(0xFF000000),
      600: const Color(0xFF000000),
      700: const Color(0xFF000000),
      800: const Color(0xFF000000),
      900: const Color(0xFF000000),
    },
  );

  List<Category> _categories = [
    Category('fas fa-home', FontAwesomeIcons.home),
    Category('far fa-circle', FontAwesomeIcons.circle),
    Category('far fa-bell', FontAwesomeIcons.bell),
    Category('fas fa-chart-line', FontAwesomeIcons.chartLine),
    Category('far fa-file-alt', FontAwesomeIcons.fileAlt),
    Category('fab fa-product-hunt', FontAwesomeIcons.productHunt),
    Category('fas fa-briefcase', FontAwesomeIcons.briefcase),
    Category('far fa-folder', FontAwesomeIcons.folder),
    Category('far fa-database', FontAwesomeIcons.database),
    Category('fas fa-cogs', FontAwesomeIcons.cogs),
    Category('fab fa-creative-commons-share', FontAwesomeIcons.creativeCommonsShare),
  ];

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

  Future<void> asyncMethod() async {
    EasyLoading.show(status: 'loading...');
    prefs = await SharedPreferences.getInstance();
    prefs.getDouble('FontSize') == null
        ? prefs.setDouble('FontSize', 16)
        : prefs.getDouble('FontSize');
    fontSize = prefs.getDouble('FontSize');

    retUser = await DBProvider.db.getUser();
    menuList = await MenuProvider.DBProvider.db.getMenu();

    getTaskList();
    getTaskAssign();
    getFavoriteProject();
    EasyLoading.dismiss();
    setState(() {});
  }

  Future<void> refreshMethod() async {
    EasyLoading.show(status: 'loading...');

    prefs = await SharedPreferences.getInstance();
    prefs.getDouble('FontSize') == null
        ? prefs.setDouble('FontSize', 16)
        : prefs.getDouble('FontSize');
    fontSize = prefs.getDouble('FontSize');

    await getTaskList();
    await getTaskAssign();
    await getFavoriteProject();
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

  Future<dynamic> getTaskList() async {
    EasyLoading.show(status: 'loading...');
    await GlobalConfiguration().loadFromAsset("app_settings");
    GlobalConfiguration cfg = new GlobalConfiguration();

    dynamic body = jsonEncode(<String, dynamic>{
      "module": "jobAssign",
      "target": "list",
      "token": retUser.Token,
      "jsonStr": ""
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
            listAllJobAssign = json['Data']['JobList'] != null ? json['Data']['JobList'] : [];
            taskList = json['Data']['InProgressJob'] != null ? json['Data']['InProgressJob'] : [];

            prefs.remove('listAllJobAssign');
            prefs.setString('listAllJobAssign', jsonEncode(listAllJobAssign));

            List<dynamic> disProject = [];
            for (var pp in taskList) {
              disProject.add(pp['ProjectID']);
            }
            listProject = disProject.toSet().toList();

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

  Future<dynamic> getTaskAssign() async {
    EasyLoading.show(status: 'loading...');
    await GlobalConfiguration().loadFromAsset("app_settings");
    GlobalConfiguration cfg = new GlobalConfiguration();

    dynamic body = jsonEncode(<String, dynamic>{
      "module": "user",
      "target": "getTaskAssign",
      "token": retUser.Token,
      "jsonStr": ""
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
            taskAssignList = json['Data'] != null ? json['Data'] : [];

            List<dynamic> disProject = [];
            for (var pp in taskAssignList) {
              disProject.add(pp['ProjectID']);
            }

            taskAssignProject = disProject.toSet().toList();
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

  Future<dynamic> getFavoriteProject() async {
    EasyLoading.show(status: 'loading...');
    await GlobalConfiguration().loadFromAsset("app_settings");
    GlobalConfiguration cfg = new GlobalConfiguration();

    dynamic body = jsonEncode(<String, dynamic>{
      "module": "user",
      "target": "getFavoriteProject",
      "token": retUser.Token,
      "jsonStr": ""
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
            projectList = json['Data'] != null ? json['Data'] : [];
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

  Future<dynamic> acceptAssign(dynamic item) async {
    EasyLoading.show(status: 'loading...');
    await GlobalConfiguration().loadFromAsset("app_settings");
    GlobalConfiguration cfg = new GlobalConfiguration();

    dynamic body = jsonEncode(<String, dynamic>{
      "module": "user",
      "target": "updateTaskAssign",
      "token": retUser.Token,
      "jsonStr": jsonEncode(<String, dynamic>{
        'ID': item['ID'],
        'Status': true
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
            refreshMethod();
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

  Future<dynamic> declineAssign(dynamic item) async {
    EasyLoading.show(status: 'loading...');
    await GlobalConfiguration().loadFromAsset("app_settings");
    GlobalConfiguration cfg = new GlobalConfiguration();

    dynamic body = jsonEncode(<String, dynamic>{
      "module": "user",
      "target": "updateTaskAssign",
      "token": retUser.Token,
      "jsonStr": jsonEncode(<String, dynamic>{
        'ID': item['ID'],
        'Status': false,
        'Remark': txtRemark.text,
      })
    });

    EasyLoading.dismiss();
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
            refreshMethod();
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

  Future<bool> _onBackPressed() {
    return showDialog(
      context: context,
      builder: (context) =>
      new AlertDialog(
        // title: Text('AlertDialog Title'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('Do you want to exit'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Yes'),
            onPressed: () async {
              exit(0);
            },
          ),
          TextButton(
            child: Text('No'),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
        ],
      ),
    ) ??
        false;
  }

  void assignDialog(BuildContext context,dynamic item) async {

    EasyLoading.dismiss();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          // title: Text('AlertDialog Title'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                // Text('Submit Fail'),
                Text('Accept Task'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                    color: Colors.black
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text(
                'OK',
              ),
              onPressed: () async {
                Navigator.pop(context);
                acceptAssign(item);
              },
            ),
          ],
        );
      },
    );
  }

  void declineDialog(BuildContext context,dynamic item) async {
    EasyLoading.dismiss();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          // title: Text('AlertDialog Title'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                // Text('Submit Fail'),
                Text('Decline Reason'),
                new Container(
                  padding: const EdgeInsets.all(15.0),
                  child: new TextFormField(
                    // inputFormatters: [
                    //   FilteringTextInputFormatter.deny(RegExp('[ ]')),
                    // ],
                    controller: txtRemark,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(const Radius.circular(10.0),),
                      ) ,
                      labelText: 'Reason',
                      //contentPadding: EdgeInsets.all(20.0),
                    ),
                  ),

                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                    color: Colors.black
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text(
                'OK',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);
                declineAssign(item);
              },
            ),
          ],
        );
      },
    );
  }

  Theme menuTheme(){
    return Theme(
      data: ThemeData(
        unselectedWidgetColor: Colors.white,
        primarySwatch: white,
        primaryColor: Color(0xFFf58042),
        canvasColor: Color(0xFFf58042),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Color(0xFFf58042),
          selectionColor: Color(0xFFf58042),
          selectionHandleColor: Color(0xFFf58042),
        ),
        fontFamily: 'Kanit',
      ),
      child: new Drawer(
        child: new ListView(
          children: <Widget> [
            ListTile(
              leading: Image.asset('assets/logo.png'),
              tileColor: Color(0xFFf58042),
              title: Text('AProjectLite',
                style: TextStyle(
                  fontSize: fontSize+2,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),),
              onTap: () => {
                //Navigator.of(context).pop()
              },
            ),

            if (menuList != null)
              for (var item in menuList)
                _buildMenu(item),

            new Container(
              color: Color(0xFFf58042),
              child: new ListTile(
                leading: FaIcon(FontAwesomeIcons.signOutAlt,color: Colors.white),
                title: Text('Logout',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                onTap: () => {
                  logoutDialog(context)
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu(Menu item) {
    if (item.Child != '[]') {
      List childMenu = jsonDecode(item.Child);
      return new Container(
        child: new Column(
          children: <Widget>[
            ExpansionTile(
              leading: FaIcon(_categories
                  .where((x) => x.name == item.MenuIcon)
                  .length == 0 ? FontAwesomeIcons.home : _categories
                  .firstWhere((x) => x.name == item.MenuIcon)
                  .icon, color: Colors.white),
              title: Text(item.Name,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              children: <Widget>[
                for(var subItem in childMenu)
                  ListTile(
                    title: Text(subItem['Name'],
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    leading: FaIcon(_categories
                        .where((x) => x.name == subItem['MenuIcon'])
                        .length == 0 ? FontAwesomeIcons.home : _categories
                        .firstWhere((x) => x.name == subItem['MenuIcon'])
                        .icon, color: Colors.white),
                    onTap: () => {
                      //Navigator.of(context).pop()
                    },
                  )
              ],
            ),
          ],
        ),
      );
    } else {
      if (item.Name == "Home") {
        return new Container(
          color: Color(0xFFff6c1f),
          child: ListTile(
            leading: FaIcon(_categories
                .where((x) => x.name == item.MenuIcon)
                .length == 0 ? FontAwesomeIcons.home : _categories
                .firstWhere((x) => x.name == item.MenuIcon)
                .icon, color: Colors.white),
            title: Text(item.Name,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            onTap: () => {
              //Navigator.of(context).pop()
            },
          ),
        );
      } else {
        return new Container(
          child: ListTile(
            leading: FaIcon(_categories
                .where((x) => x.name == item.MenuIcon)
                .length == 0 ? FontAwesomeIcons.home : _categories
                .firstWhere((x) => x.name == item.MenuIcon)
                .icon, color: Colors.white),
            title: Text(item.Name,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            onTap: () => {
              //Navigator.of(context).pop()
            },
          ),
        );
      }
    }
  }

  List<Widget> _buildTask() {
    List<Widget> widget = [];
    for (var Pro in listProject) {
      widget.add(
        new Container(
          child: new Column(
            children: <Widget>[
              ExpansionTile(
                title: Align(
                  child: Text(
                    taskList.firstWhere((x) => x['ProjectID'] == Pro)['ProjectName'],
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  alignment: Alignment(-0.85, 0),
                ),
                children: <Widget>[
                  if (taskList != null && taskList != [])
                    for (var subItem in taskList)
                      if (subItem['ProjectID'] == Pro)
                        new Container(
                          child: new ExpansionTile(
                            onExpansionChanged: (bool c){
                              HashMap<String,dynamic> updateTask = HashMap();
                              updateTask['taskID'] = subItem['ID'];
                              updateTask['progress'] = null;
                              updateTask['workDate'] = null;
                              updateTask['hour'] = null;
                              updateTask['minute'] = null;
                              updateTask['ProjectID'] = subItem['ProjectID'];
                              updateTask['projectName'] = subItem['ProjectName'];
                              updateTask['taskName'] = subItem['TaskName'];
                              updateTask['pmApprovePercent'] = 0;
                              updateTask['pmApproveDate'] = '-';
                              updateTask['previousProgress'] = 0;
                              updateTask['previousWorkDate'] = '-';
                              if (subItem['ApprovedData'] != null) {
                                dynamic jsonData = jsonDecode(subItem['ApprovedData']);
                                updateTask['pmApprovePercent'] = jsonData['Progress'];
                                updateTask['pmApproveDate'] = jsonData['ApprovedDate'];
                              }
                              if (subItem['PreviousData'] != null) {
                                var jsonData = jsonDecode(subItem['PreviousData']);
                                updateTask['previousProgress'] = jsonData['Progress'];
                                updateTask['previousWorkDate'] = jsonData['WorkDate'];
                              }

                              prefs.remove('UpdateTask');
                              prefs.setString('UpdateTask', jsonEncode(updateTask));
                              //Navigator.push(context,MaterialPageRoute(builder: (context) => UpdateTask()),);
                              Navigator.of(context).push(MaterialPageRoute(builder: (context) => UpdateTask(),)).then((value){
                                if(value == 1){refreshMethod();}
                              });
                            },
                            title: new Text(
                              subItem['TaskName'],
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: fontSize,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.left,
                            ),
                            trailing: new Container(
                              color: Colors.transparent,
                              child: RichText(
                                textAlign: TextAlign.right,
                                text: TextSpan(
                                  children: [
                                    WidgetSpan(
                                        child: Container(
                                          padding: EdgeInsets.symmetric(vertical: 2.0,horizontal: 30.0),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: new BorderRadius.only(
                                              topLeft: const Radius.circular(40.0),
                                              topRight: const Radius.circular(40.0),
                                              bottomLeft: const Radius.circular(40.0),
                                              bottomRight: const Radius.circular(40.0),
                                            ),
                                          ),
                                          child: IntrinsicWidth(
                                            child: Text(
                                              subItem['Status'],
                                              style: TextStyle(
                                                backgroundColor: Colors.red,
                                                color: Colors.white,
                                                fontSize: fontSize,
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                        )
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            subtitle: new Text(
                              subItem['TaskStartdateStr'] + ' - ' + subItem['TaskEnddateStr'],
                              style: TextStyle(
                                color: Color(0xFF999999),
                                fontSize: fontSize,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return widget;
  }

  List<Widget> _buildAssign() {
    List<Widget> widget = [];
    for (var Pro in taskAssignProject) {
      widget.add(
        new Container(
          child: new Column(
            children: <Widget>[
              ExpansionTile(
                title: Align(
                  child: Text(
                    taskAssignList.firstWhere((x) => x['ProjectID'] == Pro)['ProjectName'],
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  alignment: Alignment(-0.85, 0),
                ),
                children: <Widget>[
                  if (taskAssignList != null && taskAssignList != [])
                    for (var subItem in taskAssignList)
                      if (subItem['ProjectID'] == Pro)
                        ExpansionTile(
                          trailing: new Container(
                            color: Colors.transparent,
                            child: RichText(
                              textAlign: TextAlign.right,
                              text: TextSpan(
                                children: [
                                  WidgetSpan(
                                    child: TextButton(
                                      style: TextButton.styleFrom(
                                        primary: Colors.white, // foreground
                                        backgroundColor: Colors.transparent,
                                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                                      ),
                                      onPressed: () async {
                                        assignDialog(context,subItem);
                                      },
                                      child: FaIcon(FontAwesomeIcons.checkCircle,color: Colors.blue),
                                    ),
                                  ),
                                  WidgetSpan(
                                    child: TextButton(
                                      style: TextButton.styleFrom(
                                        primary: Colors.white, // foreground
                                        backgroundColor: Colors.transparent,
                                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                                      ),
                                      onPressed: () async {
                                        txtRemark.text = '';
                                        declineDialog(context,subItem);
                                      },
                                      child: FaIcon(FontAwesomeIcons.timesCircle,color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          title: Align(
                            child: Text(
                              subItem['TaskName'],
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                              ),
                            ),
                            alignment: Alignment(-0.85, 0),
                          ),
                          subtitle: Align(
                            child: Text(
                              subItem['TaskStartdate'] + ' - ' + subItem['TaskEnddate'],
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF999999),
                              ),
                            ),
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return widget;
  }

  List<Widget> _buildProject() {
    List<Widget> widget = [];
    for(int prjL =0; prjL < projectList.length; prjL++){
      widget.add(
          new ExpansionTile(
            title: Align(
              child: Text(
                projectList[prjL]['ProjectName'],
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              alignment: Alignment(-0.85, 0),
            ),
            trailing: Text(
              projectList[prjL]['ProjectManager'],
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            subtitle: Text(
              projectList[prjL]['PlanDate'],
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w400,
                color: Color(0xFF999999),
              ),
            ),
          )
      );
    }

    return widget;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        unselectedWidgetColor: Colors.black,
        primarySwatch: black,
        primaryColor: Color(0xFFf58042),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Color(0xFFf58042),
          selectionColor: Color(0xFFf58042),
          selectionHandleColor: Color(0xFFf58042),
        ),
        fontFamily: 'Kanit',
      ),
      home: new Scaffold(
        appBar: new AppBar(
          automaticallyImplyLeading: false,
          leading: Builder(
            builder: (context) => IconButton(
              icon: FaIcon(FontAwesomeIcons.bars,color: Colors.white,),
              onPressed: () => {
                Scaffold.of(context).openDrawer(),
              },
            ),
          ),
          title: new Text(retUser == null ? '' : retUser.FullName,
            style: TextStyle(
                fontSize: fontSize+2,
                fontWeight: FontWeight.w600,
                color: Colors.white
            ),
          ),
          actions: <Widget>[
            // IconButton(
            //   icon: Icon(
            //     FontAwesomeIcons.calendarAlt,
            //     color: Colors.white,
            //     size: 20,
            //   ),
            //   onPressed: () {
            //     Navigator.of(context).push(MaterialPageRoute(builder: (context) => Calendar(),)).then((value){
            //       //if(value == 1){refreshMethod();}
            //     });
            //   },
            // ),
            IconButton(
              icon: Icon(
                FontAwesomeIcons.bell,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {

              },
            ),
          ],
        ),
        drawer: menuTheme(),
        body: WillPopScope(
          onWillPop: _onBackPressed,
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).requestFocus(new FocusNode());
            },
            // ignoring: false,
            child: RefreshIndicator(
              onRefresh: refreshMethod,
              color: Color(0xFFf58042),
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: <Widget>[
                    new Container(
                      padding: const EdgeInsets.all(15.0),
                      alignment: Alignment.centerLeft,
                      child: new Text(
                        'TASK',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: fontSize+2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if(listProject == null || listProject.length == 0)
                      new Container(
                        padding: const EdgeInsets.only(left: 15.0,right: 15.0,bottom: 15.0),
                        alignment: Alignment.centerLeft,
                        child: new Text(
                          'No Data',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: fontSize,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    if(listProject != null && listProject != [] && listProject.length > 0)
                      for(int r =0;r<_buildTask().length;r++)
                        _buildTask()[r],

                    new Container(
                      padding: const EdgeInsets.all(15.0),
                      alignment: Alignment.centerLeft,
                      child: new Text(
                        'ASSIGNMENT',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: fontSize+2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if(taskAssignList == null || taskAssignList.length == 0)
                      new Container(
                        padding: const EdgeInsets.only(left: 15.0,right: 15.0,bottom: 15.0),
                        alignment: Alignment.centerLeft,
                        child: new Text(
                          'No Data',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: fontSize,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if(taskAssignProject != null && taskAssignProject != [] && taskAssignProject.length > 0)
                      for(int r =0;r<_buildAssign().length;r++)
                        _buildAssign()[r],

                    new Container(
                      padding: const EdgeInsets.all(15.0),
                      alignment: Alignment.centerLeft,
                      child: new Text(
                        'PROJECT',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: fontSize+2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (projectList != null && projectList != [])
                      _buildProject().isNotEmpty ? _buildProject()[0] :
                      new Container(
                        padding: const EdgeInsets.only(left: 15.0,right: 15.0,bottom: 15.0),
                        alignment: Alignment.centerLeft,
                        child: new Text(
                          'No Data',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: fontSize,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void showMyDialog(BuildContext context,String message) async {

  EasyLoading.dismiss();

  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        // title: Text('AlertDialog Title'),
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

void logoutDialog(BuildContext context) async {

  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        // title: Text('AlertDialog Title'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('Are you sure to Logout your current session.'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Yes'),
            onPressed: () async {
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
              Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder: (context) => MyHomePage()),(e) => false);
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

void tokenDialog(BuildContext context) async {

  EasyLoading.dismiss();

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: Text('Invalid Token'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder: (context) => MyHomePage()),(e) => false),
              child: Text('Go To Login'),
            ),
          ],
        ),
      );
    },
  );
}