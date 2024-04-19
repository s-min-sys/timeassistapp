import 'dart:async';
import 'dart:io' show Platform;
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeassistapp/components/alert.dart';
import 'package:timeassistapp/components/netutils.dart';
import 'package:timeassistapp/screens/alarm_add.dart';
import 'package:timeassistapp/screens/alarms_detail.dart';
import 'package:timeassistapp/screens/task_add.dart';

class Task {
  final String id;
  final String title;
  final String subTitle;
  final bool alarmFlag;
  final int taskType;
  final String notifyID;
  final String leftTime;

  const Task({
    required this.id,
    required this.title,
    required this.subTitle,
    required this.alarmFlag,
    required this.taskType,
    required this.notifyID,
    required this.leftTime,
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

    var leftTime = ''; // left_time_s
    if (json.containsKey('left_time_s')) {
      leftTime = json['left_time_s'];
    }

    return Task(
      id: json['id'],
      title: json['value'],
      subTitle: subTitle,
      alarmFlag: alarmFlag,
      taskType: taskType,
      notifyID: notifyID,
      leftTime: leftTime,
    );
  }
}

class TasksWidget extends StatefulWidget {
  const TasksWidget({super.key});

  @override
  State<TasksWidget> createState() => _TaskWidgetState();
}

var refreshCounterMax = 120.0;

class _TaskWidgetState extends State<TasksWidget> {
  List<Task> activatedTasks = [];
  Timer? _timer;
  double refreshCounter = refreshCounterMax;
  DateTime dateTime = DateTime.now();
  String notifyID = '';

  bool get isAndroid => !kIsWeb && Platform.isAndroid;

  refreshTasks() async {
    NetUtils.requestHttp('/tasks', method: NetUtils.getMethod,
        onSuccess: (data) {
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

    refreshTasks();
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

            refreshTasks();
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
                Icons.add_alarm,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AlarmAdd()),
                );
              },
              tooltip: '新增闹钟',
            ),
            IconButton(
              icon: const Icon(
                Icons.details,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AlarmDetail()),
                );
              },
              tooltip: '当前闹钟详情',
            ),
            IconButton(
              icon: const Icon(
                Icons.add_task,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TaskAdd()),
                );
              },
              tooltip: '新增任务',
            ),
            IconButton(
              icon: const Icon(
                Icons.refresh_outlined,
              ),
              onPressed: () {
                refreshTasks();
              },
              tooltip: '刷新',
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
                    itemBuilder: (context, index) => Dismissible(
                      key: Key(activatedTasks[index].id),
                      background: Container(
                          color: Colors.red,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: DefaultTextStyle(
                                  style: const TextStyle(
                                    fontSize: 20.0,
                                  ),
                                  child: AnimatedTextKit(
                                    animatedTexts: [
                                      WavyAnimatedText('左滑彻底删除该闹钟'),
                                    ],
                                    isRepeatingAnimation: true,
                                  ),
                                ),
                              )
                            ],
                          )),
                      confirmDismiss: (DismissDirection direction) async {
                        if (direction != DismissDirection.endToStart) {
                          return Future(() => false);
                        }
                        return await AlertUtils.alertDialog(
                            context: context, content: '确定要彻底删除这个闹钟么？');
                      },
                      onDismissed: (direction) {
                        final title = activatedTasks[index].title;
                        NetUtils.requestHttp('/remove/alarm',
                            parameters: {
                              'id': activatedTasks[index].id,
                            },
                            method: NetUtils.postMethod,
                            onSuccess: (p0) => {
                                  AlertUtils.alertDialog(
                                      context: context,
                                      content: '删除 [$title] 成功')
                                },
                            onError: (error) => {
                                  AlertUtils.alertDialog(
                                      context: context,
                                      content: '删除 [$title] 失败 $error')
                                });
                        activatedTasks.removeAt(index);
                        setState(() {});
                      },
                      child: ListTile(
                        onTap: () => {},
                        iconColor: Colors.blue,
                        textColor: activatedTasks[index].alarmFlag
                            ? Colors.red
                            : Colors.green,
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.done_all_outlined,
                            color: Colors.green,
                          ),
                          onPressed: () async {
                            NetUtils.requestHttp(
                                '/tasks/${activatedTasks[index].id}/done',
                                method: NetUtils.postMethod, onFinally: () {
                              refreshTasks();
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
                              child: Row(
                                children: [
                                  Text(
                                    activatedTasks[index].title,
                                  ),
                                  const Text('       '),
                                  Visibility(
                                    visible: !activatedTasks[index].alarmFlag,
                                    child: Text(
                                      activatedTasks[index].leftTime,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
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
      refreshTasks();
    });
  }
}
