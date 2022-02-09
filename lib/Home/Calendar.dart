import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../utils/db_profile.dart';
import '../controller/api.dart' as myAPI;
import '../utils/db_menu.dart' as MenuProvider;
import 'package:aprojectnew/FirstPage.dart';

import 'Calendar_Add.dart';
import 'Calendar_Detail.dart';
import 'Calendar_View.dart';

class Calendar extends StatefulWidget {
  @override
  _CalendarState createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> with WidgetsBindingObserver {

  SharedPreferences prefs;
  double fontSize = 16;
  List<Meeting> meetingList = <Meeting>[];
  CalendarController _controller = CalendarController();

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
    getData();

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

    getData();

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

  Future<dynamic> getData() async {
    EasyLoading.show(status: 'loading...');
    await GlobalConfiguration().loadFromAsset("app_settings");
    GlobalConfiguration cfg = new GlobalConfiguration();

    dynamic body = jsonEncode(<String, dynamic>{
      "module": "activity",
      "target": "list",
      "token": prefs.getString('Token'),
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
            dynamic Owner = json['Data']['Owner'];
            dynamic Member = json['Data']['Member'];
            dynamic Task = json['Data']['Task'];
            dynamic Todo = json['Data']['Todo'];
            meetingList = <Meeting>[];
            for(var i in Owner) {
              meetingList.add(
                Meeting(
                  i['ID'].toString(),
                  i['name'],
                  DateFormat("yyyy-MM-ddTHH:mm:ss").parse(i['start']),
                  DateFormat("yyyy-MM-ddTHH:mm:ss").parse(i['end']),
                  HexColor(i['color']),
                  i['color'],
                  false,
                  i['activityID'].toString(),
                  i['mode'],
                ),
              );
            }
            for(var i in Member) {
              meetingList.add(
                Meeting(
                  i['ID'].toString(),
                  i['name'],
                  DateFormat("yyyy-MM-ddTHH:mm:ss").parse(i['start']),
                  DateFormat("yyyy-MM-ddTHH:mm:ss").parse(i['end']),
                  HexColor(i['color']),
                  i['color'],
                  false,
                  i['activityID'].toString(),
                  i['mode'],
                ),
              );
            }
            for(var i in Task) {
              meetingList.add(
                Meeting(
                  i['ID'].toString(),
                  i['name'],
                  DateFormat("yyyy-MM-ddTHH:mm:ss").parse(i['start']),
                  DateFormat("yyyy-MM-ddTHH:mm:ss").parse(i['end']),
                  HexColor(i['color']),
                  i['color'],
                  false,
                  i['activityID'].toString(),
                  i['mode'],
                ),
              );
            }
            for(var i in Todo) {
              meetingList.add(
                Meeting(
                  i['ID'].toString(),
                  i['name'],
                  DateFormat("yyyy-MM-ddTHH:mm:ss").parse(i['start']),
                  DateFormat("yyyy-MM-ddTHH:mm:ss").parse(i['end']),
                  HexColor(i['color']),
                  i['color'],
                  false,
                  i['activityID'] == null ? null : i['activityID'].toString(),
                  i['mode'],
                ),
              );
            }

            setState(() { });
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
      home: new Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            'Calendar',
            style: TextStyle(
              fontSize: fontSize+2,
              color: Color(0xFFf58042),
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            //icon: Icon(_controller.view == CalendarView.month ? Icons.close : Icons.arrow_back, color: Colors.black),
            icon: Icon(_controller.view != CalendarView.month ? Icons.arrow_back : null , color: Colors.black),
            onPressed: () {
              _controller.view = CalendarView.month;
              setState(() {});
            },
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(
                Icons.refresh,
                color: Colors.black,
              ),
              onPressed: () {
                setState(() {
                  refreshMethod();
                });
              },
            ),
          ],
        ),
        body: WillPopScope(
          onWillPop: () async {
            return true;
          },
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).requestFocus(new FocusNode());
            },
            child: SfCalendar(
              view: CalendarView.month,
              onViewChanged: (ViewChangedDetails details) {
                Timer(Duration(milliseconds: 100), () { setState(() {}); });
              },
              allowedViews: [
                CalendarView.month,
                CalendarView.week,
                CalendarView.day,
                CalendarView.timelineDay,
                CalendarView.timelineWeek,
              ],
              controller: _controller,
              showDatePickerButton: true,
              showCurrentTimeIndicator: true,
              dataSource: MeetingDataSource(meetingList),
              monthViewSettings: const MonthViewSettings(
                appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
                appointmentDisplayCount: 6,
              ),
              onTap: (CalendarTapDetails details) {
                if (_controller.view == CalendarView.month && details.targetElement == CalendarElement.calendarCell) {
                  _controller.view = CalendarView.day;
                } else if ((_controller.view == CalendarView.week || _controller.view == CalendarView.workWeek) && details.targetElement == CalendarElement.viewHeader) {
                  _controller.view = CalendarView.day;
                }

                if(details.targetElement == CalendarElement.appointment){
                  if(details.appointments[0].activityID != null && details.appointments[0].activityID != ''){
                    prefs.remove('CalendarDetail');
                    prefs.remove('CalendarMode');
                    prefs.setString('CalendarDetail', details.appointments[0].id);
                    prefs.setString('CalendarMode', details.appointments[0].mode);
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) => Calendar_View(),)).then((value){
                      if(value == 1){
                        refreshMethod();
                      }else if(value ==2){
                        //Navigator.push(context, MaterialPageRoute(builder: (context) => Calendar_Detail()));
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => Calendar_Detail(),)).then((subvalue){
                          if(subvalue == 1){
                            refreshMethod();
                          }
                        });
                      }
                    });
                  }
                }

                setState(() {});
              },
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor:  Color(0xFFf58042),
          onPressed: () {
            prefs.remove('CalendarDetail');
            prefs.remove('CalendarMode');
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => Calendar_Add(),)).then((subvalue){
              if(subvalue == 1){
                refreshMethod();
              }
            });
          },
          tooltip: 'Increment',
          child: Icon(Icons.add),
        ),

      ),
    );
  }

}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Meeting> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return _getMeetingData(index).from;
  }

  @override
  DateTime getEndTime(int index) {
    return _getMeetingData(index).to;
  }

  @override
  String getSubject(int index) {
    return _getMeetingData(index).eventName;
  }

  @override
  Color getColor(int index) {
    return _getMeetingData(index).background;
  }

  @override
  bool isAllDay(int index) {
    return _getMeetingData(index).isAllDay;
  }

  Meeting _getMeetingData(int index) {
    final dynamic meeting = appointments[index];
    Meeting meetingData;
    if (meeting is Meeting) {
      meetingData = meeting;
    }

    return meetingData;
  }

}

class Meeting {
  Meeting(this.id ,this.eventName, this.from, this.to, this.background, this.backgroundStr,this.isAllDay,this.activityID,this.mode);
  String id;
  String eventName;
  DateTime from;
  DateTime to;
  Color background;
  String backgroundStr;
  bool isAllDay;
  String activityID;
  String mode;

  Map<String, String> toJson(){
    return {
      "id": this.id,
      "eventName": this.eventName,
      "from": this.from.toString(),
      "to": this.to.toString(),
      "background": this.backgroundStr,
      "backgroundStr": this.backgroundStr,
      "activityID": this.activityID,
      "mpde": this.mode,
    };
  }
}