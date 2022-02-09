import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controller/api.dart' as myAPI;

List<User123> users = [];
List<Project> projects = [];

class User123 {
  String id;
  String name;

  User123({this.id, this.name});
}

class Project {
  String id;
  String name;
  DateTime startTime;
  DateTime endTime;
  List<String> participants;

  Project({this.id, this.name, this.startTime, this.endTime, this.participants});
}

class GranttChartScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new GranttChartScreenState();
  }
}

class GranttChartScreenState extends State<GranttChartScreen> with TickerProviderStateMixin {
  AnimationController animationController;

  DateTime fromDate = DateTime(2021, 1, 1);
  DateTime toDate = DateTime(2023, 1, 1);

  List<User123> usersInChart;
  List<Project> projectsInChart;

  SharedPreferences prefs;

  @override
  void initState() {
    super.initState();

    animationController = new AnimationController(duration: Duration(microseconds: 2000), vsync: this);
    animationController.forward();

    projectsInChart = projects;
    usersInChart = users;

    asyncMethod();
  }

  Future<void> asyncMethod() async {
    prefs = await SharedPreferences.getInstance();
    await getData();
    setState(() {});
  }

  Future<dynamic> getData() async {
    EasyLoading.show(status: 'loading...');
    await GlobalConfiguration().loadFromAsset("app_settings");
    GlobalConfiguration cfg = new GlobalConfiguration();

    dynamic body = jsonEncode(<String, dynamic>{
      "module": "charter",
      "target": "detail",
      "token": prefs.getString('Token'),
      "jsonStr": jsonEncode(<String, dynamic>{
        'ProjectID': 'PRO2021100000000003',
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
            //clearEnvironment();
          }else{
            usersInChart = [];
            projectsInChart = [];


            users = [];
            projects = [];

            for(var i in json['Data']['TaskData']) {
              if(i["parent"] == '0'){
                users.add(User123(id: i['id'].toString(), name: i['text']),);
              }
              projects.add(
                Project(
                  id: '1',
                  name: i['text'],
                  startTime: DateFormat("dd-MM-yyyy HH:mm:ss").parse(i['start_date']),
                  endTime: DateFormat("dd-MM-yyyy HH:mm:ss").parse(i['end_date']),
                  participants: [i['id'],i['parent']],
                ),
              );
            }

            DateTime minDate = projects[0].startTime;
            DateTime maxDate = projects[0].endTime;
            projects.forEach((i){
              if(i.endTime.isAfter(maxDate)){
                maxDate=i.endTime;
              }
              if(i.startTime.isBefore(minDate)){
                minDate=i.startTime;
              }
            });


            setState(() {
              usersInChart = users;
              projectsInChart = projects;

              fromDate = minDate;
              toDate = maxDate;
            });

          }
        } else {
          //showMyDialog(context, "Please Try Again");
        }
      }
    } on SocketException catch (_) {
      EasyLoading.dismiss();
      //showMyDialog(context, "Please Check Internet Connection");
    }
  }

  Widget buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      title: Text(
        'Gantt',
        style: TextStyle(
          fontSize: 18,
          color: Color(0xFFf58042),
        ),
      ),
      centerTitle: true,
      actions: <Widget>[
        IconButton(
          icon: Icon(
            Icons.refresh,
            color: Colors.black,
          ),
          onPressed: () {
            setState(() {
              getData();
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MediaQuery.of(context).orientation == Orientation.landscape ? null : buildAppBar(),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(new FocusNode());
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if(MediaQuery.of(context).orientation == Orientation.landscape)
              SizedBox(height: 30.0,),
            // ElevatedButton(onPressed: (){getData();}, child: Text('Refresh')),

            Expanded(
              child: GanttChart(
                animationController: animationController,
                fromDate: fromDate,
                toDate: toDate,
                data: projectsInChart,
                usersInChart: usersInChart,
              ),
            ),

          ],
        ),
      ),
    );
  }

}

class GanttChart extends StatelessWidget {
  final AnimationController animationController;
  final DateTime fromDate;
  final DateTime toDate;
  final List<Project> data;
  final List<User123> usersInChart;

  int viewRange;
  int viewRangeToFitScreen = 6;
  Animation<double> width;

  GanttChart({
    this.animationController,
    this.fromDate,
    this.toDate,
    this.data,
    this.usersInChart,
  }) {
    viewRange = calculateNumberOfMonthsBetween(fromDate, toDate);
  }

  int calculateNumberOfMonthsBetween(DateTime from, DateTime to) {
    return to.month - from.month + 12 * (to.year - from.year) + 1;
  }

  int calculateDistanceToLeftBorder(DateTime projectStartedAt) {
    if (projectStartedAt.compareTo(fromDate) <= 0) {
      return 0;
    } else
      return calculateNumberOfMonthsBetween(fromDate, projectStartedAt) - 1;
  }

  int calculateRemainingWidth(DateTime projectStartedAt, DateTime projectEndedAt) {
    return projectEndedAt.difference(projectStartedAt).inDays +1;
  }

  List<Widget> buildChartBars(List<Project> data, double chartViewWidth, Color color) {
    List<Widget> chartBars = new List();

    for(int i = 0; i < data.length; i++) {
      var remainingWidth = calculateRemainingWidth(data[i].startTime, data[i].endTime);
      if (remainingWidth > 0) {
        chartBars.add(
          Container(
            decoration: BoxDecoration(
              color: color.withAlpha(100),
              borderRadius: BorderRadius.circular(10.0),
            ),
            height: 25.0,
            width: remainingWidth * chartViewWidth / viewRangeToFitScreen,
            margin: EdgeInsets.only(
              left: calculateDistanceToLeftBorder(data[i].startTime) * chartViewWidth / viewRangeToFitScreen,
              top: i == 0 ? 4.0 : 2.0,
              bottom: i == data.length - 1 ? 4.0 : 2.0,
            ),
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                data[i].name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.0),
              ),

            ),
          ),
        );
      }
    }

    return chartBars;
  }

  Widget buildHeader(double chartViewWidth, Color color) {
    List<Widget> headerItems = new List();

    DateTime tempDate = fromDate;

    viewRange = toDate.difference(fromDate).inDays + 1;

    headerItems.add(
      Container(
        width: chartViewWidth / viewRangeToFitScreen,
        child: new Text(
          'Task',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10.0,
          ),
        ),
      ),
    );

    for (int i = 0; i < viewRange; i++) {
      headerItems.add(
        Container(
          width: chartViewWidth / viewRangeToFitScreen,
          child: new Text(
            tempDate.day.toString() + '/' + tempDate.month.toString() + '/' + tempDate.year.toString(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.0,
            ),
          ),
        ),
      );
      tempDate = new DateTime(tempDate.year, tempDate.month, tempDate.day+1);
      //tempDate = Utils.nextMonth(tempDate);
    }

    return Container(
      height: 25.0,
      color: color.withAlpha(100),
      child: Row(
        children: headerItems,
      ),
    );
  }

  Widget buildGrid(double chartViewWidth) {
    List<Widget> gridColumns = new List();

    viewRange = toDate.difference(fromDate).inDays + 1;

    for (int i = 0; i <= viewRange; i++) {
      gridColumns.add(
        Container(
          width: chartViewWidth / viewRangeToFitScreen,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: Colors.grey.withAlpha(100), width: 1.0),
            ),
          ),
        ),
      );
    }

    return Row(
      children: gridColumns,
    );
  }

  Widget buildChartForEachUser(List<Project> userData, double chartViewWidth, User123 user) {
    Color color = Color.fromRGBO(Random().nextInt(256), Random().nextInt(256), Random().nextInt(256), 0.75);
    var chartBars = buildChartBars(userData, chartViewWidth, color);
    return Container(
      height: chartBars.length * 29.0 + 25.0 + 4.0,
      child: ListView(
        physics: new ClampingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          Stack(
            fit: StackFit.loose,
            children: <Widget>[
              buildGrid(chartViewWidth),
              buildHeader(chartViewWidth, color),
              Container(
                margin: EdgeInsets.only(top: 25.0),
                child: Container(
                  child: Column(
                    children: <Widget>[
                      Container(
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: chartViewWidth / viewRangeToFitScreen,
                              height: chartBars.length * 29.0 + 4.0,
                              color: color.withAlpha(100),
                              child: Center(
                                child: new RotatedBox(
                                  quarterTurns: chartBars.length * 29.0 + 4.0 > 50 ? 0 : 0,
                                  child: new Text(
                                    user.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Kanit',
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: chartBars,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> buildChartContent(double chartViewWidth) {
    List<Widget> chartContent = new List();

    usersInChart.forEach((user) {

      List<Project> projectsOfUser = new List();

      projectsOfUser = projects.where((project) => project.participants.indexOf(user.id) != -1).toList();

      if (projectsOfUser.length > 0) {
        chartContent.add(
          buildChartForEachUser(projectsOfUser, chartViewWidth, user),
        );
      }
    });

    return chartContent;
  }

  @override
  Widget build(BuildContext context) {
    var chartViewWidth = MediaQuery.of(context).size.width;
    var screenOrientation = MediaQuery.of(context).orientation;

    screenOrientation == Orientation.landscape ? viewRangeToFitScreen = 12 : viewRangeToFitScreen = 6;

    return Container(
      child: MediaQuery.removePadding(
        child: ListView(
            children: buildChartContent(chartViewWidth)
        ),
        removeTop: true,
        context: context,
      ),
    );
  }
}