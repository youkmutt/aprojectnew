import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'package:open_file/open_file.dart';

class UpdateApp extends StatefulWidget {
  @override
  _UpdateAppState createState() => new _UpdateAppState();
}

class _UpdateAppState extends State<UpdateApp> with WidgetsBindingObserver {

  String path;
  SharedPreferences prefs;

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
    return Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder: (context) => MyApp()),(e) => false);
  }

  Future<void> asyncMethod() async {
    // EasyLoading.show(status: 'loading...');
    //
    // EasyLoading.dismiss();
    prefs = await SharedPreferences.getInstance();
    _setPath();
    setState(() {});
  }

  void _setPath() async {
    Directory _path = await getApplicationDocumentsDirectory();
    String _localPath = _path.path + Platform.pathSeparator + 'Download';
    final savedDir = Directory(_localPath);
    bool hasExisted = await savedDir.exists();
    if (!hasExisted) {
      savedDir.create();
    }
    print('_localPath : ' + _localPath);
    path = _localPath;
    String url = prefs.getString('UpdateURL');

    File fileUpdated = await _downloadFile(url,'aprojectlite.apk');
    EasyLoading.dismiss();
    OpenFile.open(fileUpdated.path);
  }

  Future<File> _downloadFile(String url, String filename) async {
    EasyLoading.show(status: 'loading...');
    var httpClient = new HttpClient();
    var request = await httpClient.getUrl(Uri.parse(url));
    var response = await request.close();
    var bytes = await consolidateHttpClientResponseBytes(response);
    String dir = (await getApplicationDocumentsDirectory()).path;
    File file = new File('$dir/$filename');
    await file.writeAsBytes(bytes);
    EasyLoading.dismiss();
    return file;
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
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            'Update Task',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFFf58042),
            ),
          ),
          centerTitle: true,
          // leading: IconButton(
          //   icon: Icon(Icons.close, color: Colors.black),
          //   onPressed: () => Navigator.of(context).pop(),
          // ),
        ),
        body: WillPopScope(
          onWillPop: _onBackPressed,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              children: <Widget>[
                new Container(
                  padding: const EdgeInsets.all(10.0),
                  alignment: Alignment.topCenter,
                  child:
                  Text(
                    'Update',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Kanit',
                    ),
                  ),
                ),
              ],
            ),
          ),

        ),
      ),
    );
  }
}