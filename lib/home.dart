import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:device_info/device_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'controller/api.dart' as myAPI;
import 'FirstPage.dart';
import 'models/menuModels.dart';
import 'utils/db_profile.dart';
import 'utils/db_menu.dart' as MenuProvider;
import 'models/user.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPage createState() => _LoginPage();
}

class _LoginPage extends State<LoginPage> with WidgetsBindingObserver {
  String ret = '';
  bool _isButtonDisabled;
  bool remember = false;
  TextEditingController user = new TextEditingController();
  TextEditingController password = new TextEditingController();
  ScrollController _scrollController = new ScrollController();
  User retUser;
  SharedPreferences prefs;
  double fontSize = 16;

  @override
  void initState() {
    _isButtonDisabled = false;
    ret = '';
    remember = false;

    super.initState();
    asyncMethod();
    EasyLoading.dismiss();
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
    switch(state){
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.resumed:
        _isButtonDisabled = false;
        ret = '';
        remember = false;
        EasyLoading.dismiss();
        asyncMethod();
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  void asyncMethod() async {
    prefs = await SharedPreferences.getInstance();
    prefs.getDouble('FontSize') == null ? prefs.setDouble('FontSize', 16) : prefs.getDouble('FontSize');
    fontSize = prefs.getDouble('FontSize');

    try{
      retUser = await DBProvider.db.getUser();
      if(retUser != null){
        if(retUser.remember == 1){
          dynamic menuList = await getMenu();
          if(menuList != null){
            try{
              var checkingDrop = await MenuProvider.DBProvider.db.deleteMenu();
              while (checkingDrop!=0){
                checkingDrop = await MenuProvider.DBProvider.db.deleteMenu();
              }
              int retInsert = 0;
              for(var item in menuList['Data']){

                var mapMenu = Menu(
                  Name: item['Name'],
                  MenuAction: item['MenuAction'],
                  MenuController: item['MenuController'],
                  MenuIcon: item['MenuIcon'],
                  Child: jsonEncode(item['Child']) ,
                );

                retInsert = await MenuProvider.DBProvider.db.newMenu(mapMenu);
              }
              retInsert > 0 ? Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder: (context) => HomePage()),(e) => false) : _showMyDialog(context,'Invalid Token');

            }catch(ex){
              _showMyDialog(context,'Invalid Token');
            }
          }
        }else{ clearEnvironment(); }
      }else{ clearEnvironment(); }
    }catch (ex){
      EasyLoading.dismiss();
    }
  }

  Future<dynamic> getMenu() async {
    EasyLoading.show(status: 'loading...');
    await GlobalConfiguration().loadFromAsset("app_settings");
    GlobalConfiguration cfg = new GlobalConfiguration();

    dynamic body = jsonEncode(<String, dynamic>{
      "module": "user",
      "target": "getMenu",
      "token": retUser.Token,
      "jsonStr": ""
    });

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        var response = await myAPI.API().apiPost(cfg.getValue("api_menu"),body);
        EasyLoading.dismiss();
        if (response.statusCode == 200) {
          dynamic json = jsonDecode(response.body);

          if(json['Status'] == 200){
            prefs.setString('Token', retUser.Token);
          }else{
            clearEnvironment();
          }
          return json;
        } else{
          clearEnvironment();
        }
      }
    }on SocketException catch (_) {
      showMyDialog(context,"Please Check Internet Connection");
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

    EasyLoading.dismiss();
  }

  String getWithoutSpaces(String s){
    String tmp = s.substring(0,s.length);
    while(tmp.startsWith(' ')){
      tmp = tmp.substring(1);
    }
    while(tmp.endsWith(' ')){
      tmp = tmp.substring(1,tmp.length);
    }
    String finaltemp = '';
    for(int i=0;i<tmp.length;i++){
      int charcode = tmp.codeUnitAt(i);
      if(charcode < 8000){
        finaltemp += tmp[i];
      }
    }

    return finaltemp;
  }

  String generateMd5(String input) {
    String utt = md5.convert(utf8.encode(input)).toString();
    return utt;
  }

  Future<dynamic> login(String username,String pass) async {
    await GlobalConfiguration().loadFromAsset("app_settings");
    GlobalConfiguration cfg = new GlobalConfiguration();

    String deviceN = "";

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceN = '${androidInfo.brand}' + ' ' + '${androidInfo.hardware}';
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceN = '${iosInfo.utsname.machine}';
      }
    } on PlatformException {

    }

    dynamic body = jsonEncode(<String, dynamic>{
      'username': username,
      'password': pass,
    });

    var response = await myAPI.API().apiPost(cfg.getValue("api_user"),body);

    dynamic json = jsonDecode(response.body);

    return json;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: Color(0xFFf58042),
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: Color(0xFFf58042),
            selectionColor: Color(0xFFf58042),
            selectionHandleColor: Color(0xFFf58042),
          ),
          fontFamily: 'Kanit',
        ),
        home: Scaffold(
            body: GestureDetector(
              onTap: () {
                FocusScope.of(context).requestFocus(new FocusNode());
              },
              child: IgnorePointer(
                  ignoring: _isButtonDisabled,
                  // ignoring: false,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      children: <Widget>[
                        new Padding(padding: EdgeInsets.only(top: 100.0)),

                        Image.asset(
                          'assets/welcome.png',
                          width: MediaQuery.of(context).size.width*0.9,
                        ),
                        new Padding(padding: EdgeInsets.only(top: 50.0)),

                        new Container(
                          padding: const EdgeInsets.all(15.0),
                          child: new TextFormField(
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(RegExp('[ ]')),
                            ],
                            controller: user,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: const BorderRadius.all(const Radius.circular(10.0),),
                              ) ,
                              labelText: 'Enter your username',
                              contentPadding: EdgeInsets.all(20.0),
                            ),
                          ),

                        ),

                        new Container(
                          padding: const EdgeInsets.all(15.0),
                          child: new TextFormField(
                            controller: password,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: const BorderRadius.all(const Radius.circular(10.0),),
                              ),
                              labelText: 'Enter your password',
                              contentPadding: EdgeInsets.all(20.0),
                            ),
                            obscureText: true,
                          ),
                        ),

                        new Container(
                          padding: const EdgeInsets.only(bottom: 15.0),
                          child: ListTile(
                            leading: Switch(
                              value: remember,
                              onChanged: (value) {
                                setState(() {
                                  remember = value;
                                });
                              },
                              activeTrackColor: Color(0xFFf58042),
                              activeColor: Color(0xFFff6c1f),
                            ),
                            title: Text('remember',
                              style: TextStyle(
                                  fontSize: fontSize+2,
                                  fontWeight: FontWeight.w500
                              ),
                            ),
                            onTap: () => {
                              setState(() {
                                remember = !remember;
                              })
                            },
                          ),
                        ),

                        new Container(
                            child: new TextButton(
                              style: TextButton.styleFrom(
                                primary: Colors.white, // foreground
                                backgroundColor: Color(0xFFf58042),
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                              ),
                              onPressed: () async {
                                String preuser = getWithoutSpaces(user.text.replaceAll(new RegExp(r"\s+\b|\b\s"), ""));
                                String prepass = getWithoutSpaces(password.text.replaceAll(new RegExp(r"\s+\b|\b\s"), ""));
                                // bool permission = await inPermission(context);
                                bool permission = true;
                                if(_isButtonDisabled == false && permission==true){
                                  _isButtonDisabled = true;
                                  EasyLoading.show(status: 'loading...');
                                  try{
                                    dynamic result = await login(preuser.replaceAll('?', ''),prepass);
                                    if(result['Status'] != 200){
                                      EasyLoading.dismiss();
                                      _isButtonDisabled = false;
                                      setState(() {});
                                      _showMyDialog(context,result['Message']);
                                    }else{
                                      EasyLoading.dismiss();
                                      _isButtonDisabled = false;
                                      setState(() {});

                                      try{
                                        var checkingDrop = await DBProvider.db.deleteUser();

                                        while (checkingDrop!=0){
                                          checkingDrop = await DBProvider.db.deleteUser();
                                        }

                                        var newUser = User(
                                          username: preuser.replaceAll('?', ''),
                                          password: prepass,
                                          remember: remember == true ? 1 : 0,
                                          ID: result['Data']['ID'],
                                          FirstName: result['Data']['FirstName'],
                                          LastName: result['Data']['LastName'],
                                          FullName: result['Data']['FullName'],
                                          RoleID: result['Data']['RoleID'],
                                          RoleName: result['Data']['RoleName'],
                                          UserProfileImage: result['Data']['UserProfileImage'],
                                          Email: result['Data']['Email'],
                                          Token: result['Data']['Token'],
                                          EmployeeID: result['Data']['EmployeeID'],
                                        );
                                        var retInsert = await DBProvider.db.newUser(newUser);
                                        retUser = await DBProvider.db.getUser();
                                        prefs.setString('Token', newUser.Token);

                                        int menuInsert = 0;
                                        dynamic menuList = await getMenu();
                                        if(menuList != null){
                                          var menuDrop = await MenuProvider.DBProvider.db.deleteMenu();
                                          while (menuDrop!=0){
                                            menuDrop = await MenuProvider.DBProvider.db.deleteMenu();
                                          }
                                          for(var item in menuList['Data']){
                                            var mapMenu = Menu(
                                              Name: item['Name'],
                                              MenuAction: item['MenuAction'],
                                              MenuController: item['MenuController'],
                                              MenuIcon: item['MenuIcon'],
                                              Child: jsonEncode(item['Child']) ,
                                            );
                                            menuInsert = await MenuProvider.DBProvider.db.newMenu(mapMenu);
                                          }
                                        }

                                        retInsert > 0 && menuInsert > 0 ? Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder: (context) => HomePage()),(e) => false) : _showMyDialog(context,'Invalid Token');
                                      }catch(ex){
                                        _showMyDialog(context,'Invalid Token');
                                      }
                                    }
                                  }catch(error){
                                    _isButtonDisabled = false;
                                    EasyLoading.dismiss();
                                    setState(() {});
                                    _showMyDialog(context,'Please Check Internet Connection\n'+ error.toString());
                                  }
                                }
                              },
                              child: Text('Sign In',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w400
                                ),
                              ),
                            )
                        ),

                        Image.asset(
                          'assets/bg.png',
                          width: MediaQuery.of(context).size.width,
                        ),

                        new Padding(padding: EdgeInsets.only(bottom: 50.0)),
                      ],
                    ),
                  )),
            )
    ),);
  }
}

void _showMyDialog(BuildContext context,String message) async {

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
              Text('Login Fail'),
              Text(message),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
