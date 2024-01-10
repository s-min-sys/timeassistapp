import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeassistapp/components/alert.dart';
import 'package:timeassistapp/components/netutils.dart';

class Task {
  final String id;
  final String title;
  final String subTitle;
  final bool alarmFlag;
  final int taskType;
  final String notifyID;

  const Task({
    required this.id,
    required this.title,
    required this.subTitle,
    required this.alarmFlag,
    required this.taskType,
    required this.notifyID,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    var subTitle = '';
    if (json.containsKey('sub_title')) {
      subTitle = json['sub_title'];
    }

    var alarmFlag = false;
    if (json.containsKey('alarm_flag')) {
      alarmFlag = json['alarm_flag'];
    }

    var taskType = 0;
    if (json.containsKey('vo_task_type')) {
      taskType = json['vo_task_type'];
    }

    var notifyID = '';
    if (json.containsKey('notify_id')) {
      notifyID = json['notify_id'];
    }

    return Task(
      id: json['id'],
      title: json['value'],
      subTitle: subTitle,
      alarmFlag: alarmFlag,
      taskType: taskType,
      notifyID: notifyID,
    );
  }
}

class TasksWidget extends StatefulWidget {
  const TasksWidget({super.key});

  @override
  State<TasksWidget> createState() => _TaskWidgetState();
}

var refreshCounterMax = 12.0;

class _TaskWidgetState extends State<TasksWidget> {
  List<Task> activatedTasks = [];
  Timer? _timer;
  double refreshCounter = refreshCounterMax;
  DateTime dateTime = DateTime.now();
  String notifyID = '';

  bool get isAndroid => !kIsWeb && Platform.isAndroid;

  fetchTasks() async {
    NetUtils.requestHttp('/tasks', method: NetUtils.getMethod, onSuccess: (data) {
      if (mounted) {
        setState(() {
          dateTime = DateTime.now();
        });
      }

      List responseJson = data;
      List<Task> tasks = responseJson.map((m) => Task.fromJson(m)).toList();

      for (var element in tasks) {
        if (element.notifyID == '') {
          continue;
        }

        SharedPreferences.getInstance().then((sp) {
          var k = 'notifyID_${element.id}';
          if (!sp.containsKey(k) || sp.getString(k) != element.notifyID) {
            sp.setString(k, element.notifyID);
          }
        });
      }

      setState(() {
        activatedTasks = tasks;
      });
    }, onError: (error) {
      AlertUtils.alertDialog(context: context, content: error);
    }, onFinally: () {
      setState(() {
        refreshCounter = refreshCounterMax;
      });

      return <Task>[];
    });
  }

  @override
  void initState() {
    super.initState();

    fetchTasks();
    startRefreshIfNoTimer();
  }

  @override
  void dispose() {
    stopRefrsh();
    super.dispose();
  }

  void startRefreshIfNoTimer() {
    if (_timer != null) {
      return;
    }

    startRefresh();
  }

  void startRefresh() {
    stopRefrsh();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer t) => setState(
        () {
          refreshCounter--;
          if (refreshCounter <= 0) {
            refreshCounter = refreshCounterMax;

            fetchTasks();
          }
        },
      ),
    );
  }

  void stopRefrsh() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('时间助手'),
            const SizedBox(
              width: 4,
            ),
            Expanded(
              child: Text(
                dateTime.toString().substring(0, 19),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.speaker,
                color: Colors.green,
              ),
              onPressed: () {},
              tooltip: '播报',
            )
          ],
        ),
      ),
      body: Center(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: refreshCounter / refreshCounterMax,
              color: Colors.red,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.separated(
                    itemCount: activatedTasks.length,
                    itemBuilder: (context, index) => ListTile(
                      onTap: () => {},
                      iconColor: Colors.blue,
                      textColor: activatedTasks[index].alarmFlag ? Colors.red : Colors.black,
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.reply,
                          color: Colors.green,
                        ),
                        onPressed: () async {
                          NetUtils.requestHttp('/tasks/${activatedTasks[index].id}/done', method: NetUtils.postMethod, onFinally: () {
                            fetchTasks();
                          });
                        },
                        tooltip: 'done',
                      ),
                      title: Row(
                        children: [
                          Visibility(
                            visible: activatedTasks[index].taskType == 1,
                            child: const Icon(
                              Icons.task_alt,
                            ),
                          ),
                          Visibility(
                            visible: activatedTasks[index].taskType == 2,
                            child: const Icon(
                              Icons.alarm,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              activatedTasks[index].title,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          const SizedBox(width: 30),
                          Expanded(
                            child: Text(
                              activatedTasks[index].subTitle,
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    separatorBuilder: (BuildContext context, int index) {
                      return const Divider(
                        color: Colors.grey,
                        height: 1,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    return Future.delayed(const Duration(microseconds: 100), () {
      fetchTasks();
    });
  }
}
