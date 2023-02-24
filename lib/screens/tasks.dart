import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:confirm_dialog/confirm_dialog.dart';

import 'global.dart';

class Task {
  final String id;
  final String title;
  final String subTitle;
  final bool alarmFlag;
  final int taskType;

  const Task({
    required this.id,
    required this.title,
    required this.subTitle,
    required this.alarmFlag,
    required this.taskType,
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

    return Task(
      id: json['id'],
      title: json['value'],
      subTitle: subTitle,
      alarmFlag: alarmFlag,
      taskType: taskType,
    );
  }
}

class TasksWidget extends StatefulWidget {
  const TasksWidget({super.key});

  @override
  State<TasksWidget> createState() => _TaskWidgetState();
}

class _TaskWidgetState extends State<TasksWidget> {
  late Future<List<Task>> futureAlbum;
  Timer? _timer;
  int refreshCounter = 12;
  DateTime dateTime = DateTime.now();

  Future<List<Task>> fetchTasks() async {
    final response = await http.get(
      Uri.parse('${dotenv.env['SERVER_DOMAIN']}/tasks'),
      headers: {
        'Authorization': 'Basic ${Global.token}',
      },
    );

    setState(() {
      refreshCounter = 10;
    });

    if (response.statusCode == 200) {
      if (mounted) {
        setState(() {
          dateTime = DateTime.now();
        });
      }
      List responseJson = json.decode(response.body);
      return responseJson.map((m) => Task.fromJson(m)).toList();
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      return List<Task>.empty();
    }
  }

  @override
  void initState() {
    super.initState();
    futureAlbum = fetchTasks();
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
            refreshCounter = 12;

            futureAlbum = fetchTasks();
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
            Text(
              dateTime.toString().substring(0, 19),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: refreshCounter / 12.0,
              color: Colors.red,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: FutureBuilder<List<Task>>(
                    future: futureAlbum,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        startRefreshIfNoTimer();

                        return ListView.separated(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) => ListTile(
                            iconColor: Colors.blue,
                            textColor: snapshot.data![index].alarmFlag
                                ? Colors.red
                                : Colors.black,
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.reply,
                                color: Colors.green,
                              ),
                              onPressed: () async {
                                if (await confirm(
                                  context,
                                  title: const Text('确认注意到了?'),
                                  content: Text(snapshot.data![index].title),
                                  textOK: const Text('我知道了'),
                                  textCancel: const Text('我再想想'),
                                )) {
                                  http.post(
                                    Uri.parse(
                                        '${dotenv.env['SERVER_DOMAIN']}/tasks/${snapshot.data?[index].id}/done'),
                                    headers: {
                                      'Authorization': 'Basic ${Global.token}',
                                    },
                                  ).then((value) => futureAlbum = fetchTasks());
                                } else if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Cancelled'),
                                        duration: Duration(seconds: 1)),
                                  );
                                }
                              },
                              tooltip: 'done',
                            ),
                            title: Row(
                              children: [
                                Visibility(
                                  visible: snapshot.data![index].taskType == 1,
                                  child: const Icon(
                                    Icons.task_alt,
                                  ),
                                ),
                                Visibility(
                                  visible: snapshot.data![index].taskType == 2,
                                  child: const Icon(
                                    Icons.alarm,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    snapshot.data![index].title,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Row(
                              children: [
                                const SizedBox(width: 30),
                                Text(
                                  snapshot.data![index].subTitle,
                                  style: const TextStyle(
                                    color: Colors.grey,
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
                        );
                      } else if (snapshot.hasError) {
                        stopRefrsh();

                        return IconButton(
                          icon: const Icon(Icons.network_check),
                          onPressed: () {
                            setState(() {
                              futureAlbum = fetchTasks();
                            });
                          },
                        );
                      }

                      // By default, show a loading spinner.
                      return const CircularProgressIndicator();
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
      setState(() {
        futureAlbum = fetchTasks();
      });
    });
  }
}
