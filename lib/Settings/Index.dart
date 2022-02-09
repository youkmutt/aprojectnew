import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../FirstPage.dart';

class Settings_Index extends StatefulWidget {
  @override
  _Settings_IndexState createState() => _Settings_IndexState();
}

class _Settings_IndexState extends State<Settings_Index> with WidgetsBindingObserver {

  SharedPreferences prefs;
  double _currentSliderValue = 16;

  @override
  void initState() {
    asyncMethod();
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> asyncMethod() async {
    prefs = await SharedPreferences.getInstance();
    prefs = await SharedPreferences.getInstance();
    prefs.getDouble('FontSize') == null
        ? prefs.setDouble('FontSize', 16)
        : prefs.getDouble('FontSize');
    _currentSliderValue = prefs.getDouble('FontSize');
    setState(() {});
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
        textTheme: TextTheme(bodyText2: TextStyle(fontSize: 16,fontWeight: FontWeight.w500,)),
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
            body: WillPopScope(
              onWillPop: _onBackPressed,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: <Widget>[
                    Padding(padding: EdgeInsets.all(20.0)),
                    new Container(
                      padding: const EdgeInsets.all(20.0),
                      alignment: Alignment.center,
                      child: Text(
                        'Font Size : ' + _currentSliderValue.toInt().toString(),
                        style: TextStyle(
                          fontSize: _currentSliderValue,
                          fontFamily: 'Kanit',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    new Container(
                      padding: const EdgeInsets.all(20.0),
                      alignment: Alignment.center,
                      child: Slider(
                        value: _currentSliderValue,
                        max: 22,
                        min: 10,
                        divisions: 12,
                        label: _currentSliderValue.round().toString(),
                        onChanged: (double value) {
                          setState(() {
                            _currentSliderValue = value;
                            prefs.setDouble('FontSize', _currentSliderValue);
                          });
                        },
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
