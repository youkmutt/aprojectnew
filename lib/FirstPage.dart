import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Assignment/Index.dart';
import 'Home/Calendar.dart';
import 'Home/Index.dart';
import 'Settings/Index.dart';
import 'ToDoList/Index.dart';
import 'main.dart';
import 'models/menuModels.dart';
import 'models/user.dart';
import 'utils/db_profile.dart';
import 'utils/db_menu.dart' as MenuProvider;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => new _HomePageState();
}

class Category {
  String name;
  IconData icon;
  Category(this.name, this.icon);
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {

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

  void asyncMethod() async {
    prefs = await SharedPreferences.getInstance();
    prefs.getDouble('FontSize') == null
        ? prefs.setDouble('FontSize', 16)
        : prefs.getDouble('FontSize');
    fontSize = prefs.getDouble('FontSize');
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
          color: Color(0xFFf58042),
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

  int _currentIndex = 0;

  final screen = [
    IndexPage(),
    Calendar(),
    ToDoIndexPage(),
    GranttChartScreen(),
    Settings_Index(),
  ];

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
        drawer: menuTheme(),
        body: IndexedStack(
          index: _currentIndex,
          children: screen,
        ),
        bottomNavigationBar:MediaQuery.of(context).orientation == Orientation.landscape ? null : BottomNavigationBar(
          currentIndex: _currentIndex,
          fixedColor: Color(0xFFf58042),
          unselectedItemColor: Color(0xFF7a7a7a),
          showUnselectedLabels: true,
          iconSize: 25,
          onTap: (int newIndex){
            setState(() {
              _currentIndex = newIndex;
            });
          },
          items: [
            BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.home),label: 'Home',),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined),label: 'Calendar',),
            BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.checkCircle),label: 'To Do List',),
            BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined),label: 'Assignment',),
            BottomNavigationBarItem(icon: Icon(Icons.settings),label: 'Settings',),
          ],
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