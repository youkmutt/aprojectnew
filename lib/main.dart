import 'dart:convert';
import 'dart:io';
import 'package:aprojectnew/UpdateApp.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:package_info/package_info.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'controller/api.dart' as myAPI;
import 'home.dart';
import 'models/mas_authorize.dart' as mas_aut;
import 'package:global_configuration/global_configuration.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Kanit',
        primaryColor: Color(0xFFf58042),
        scaffoldBackgroundColor: Color(0xFFFFFFFF),
      ),
      home: MyHomePage(),
      builder: EasyLoading.init(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  ScrollController _scrollController = new ScrollController();

  String _platform = '';
  String _deviceName = '';
  String appName = '';
  String packageName = '';
  String version = '';
  String buildNumber = '';
  String appKey = '';
  dynamic mainRet;
  SharedPreferences prefs;

  @override
  void initState(){
    EasyLoading.show(status: 'loading...');
    initMethod();
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
    switch(state){
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.resumed:
        EasyLoading.dismiss();
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> initMethod() async {
    prefs = await SharedPreferences.getInstance();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appName = packageInfo.appName;
    packageName = packageInfo.packageName;
    version = packageInfo.version;
    buildNumber = packageInfo.buildNumber;
    appKey = md5.convert(utf8.encode(appName)).toString();

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        _platform = "android";
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        _deviceName = '${androidInfo.brand}' + ' ' + '${androidInfo.hardware}';
      } else if (Platform.isIOS) {
        _platform = "ios";
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        _deviceName = '${iosInfo.utsname.machine}';
      }
    } on PlatformException {
      _deviceName = 'Not Found';
      _platform = 'Not Found';
    }

    try {
      await GlobalConfiguration().loadFromAsset("app_settings");
      GlobalConfiguration cfg = new GlobalConfiguration();

      final result = await InternetAddress.lookup(cfg.getValue("ping_init"));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        mainRet = await authentication();
      }
    }on SocketException catch (_) {
      EasyLoading.dismiss();
      _showMyDialog(context,"Not Found Server");
    }
  }

  Future<dynamic> authentication() async {
    await GlobalConfiguration().loadFromAsset("app_settings");
    GlobalConfiguration cfg = new GlobalConfiguration();

    mas_aut.Authorize body = mas_aut.Authorize(Platform: _platform,App_Name: appName,App_Version: version,App_Key: appKey);

    try{
      var response = await myAPI.API().apiPost(cfg.getValue("api_init"),jsonEncode(body));

      if (response.statusCode == 200) {
        EasyLoading.dismiss();
        dynamic json = jsonDecode(response.body);

        if(json['data']['App_Version'] == version){
          Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder: (context) => LoginPage()),(e) => false);
        }else{
          EasyLoading.dismiss();
          prefs.remove('UpdateURL');
          prefs.setString('UpdateURL', json['data']['App_URL']);
          Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder: (context) => UpdateApp()),(e) => false);
          //_showMyDialog(context,'Version Not Match');

          //return {'status': 400,'message': 'Version Not Match'};
        }
      } else {
        EasyLoading.dismiss();
        _showMyDialog(context,'Login Failed');
        return {'status': 500,'message': 'Login Failed'};
      }
    }catch (ex){
      EasyLoading.dismiss();
      _showMyDialog(context,'Failed');
      return {'status': 502,'message': 'Failed'};
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: IgnorePointer(
          ignoring: false,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: new Column(
              children: <Widget>[

                new Padding(padding: EdgeInsets.only(top: 100.0)),

                Image.asset(
                  'assets/welcome.png',
                  width: MediaQuery.of(context).size.width*0.8,
                ),
                Image.asset(
                  'assets/bg.png',
                  width: MediaQuery.of(context).size.width,
                ),
                new Padding(padding: EdgeInsets.only(bottom: 50.0)),

                Text(mainRet == null ? '' : mainRet.toString()),
              ],
            ),
          ),
        ),
      ),
    );
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
              Text('Authentication Fail'),
              Text(message),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
