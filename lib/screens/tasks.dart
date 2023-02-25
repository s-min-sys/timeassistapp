import 'dart:async';
import 'dart:convert';

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'global.dart';

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
  late Future<List<Task>> futureAlbum;
  Timer? _timer;
  double refreshCounter = refreshCounterMax;
  DateTime dateTime = DateTime.now();
  late FlutterTts flutterTts;
  String notifyID = '';

  bool get isAndroid => !kIsWeb && Platform.isAndroid;

  Future<List<Task>> fetchTasks() async {
    final response = await http.get(
      Uri.parse('${dotenv.env['SERVER_DOMAIN']}/tasks'),
      headers: {
        'Authorization': 'Basic ${Global.token}',
      },
    );

    setState(() {
      refreshCounter = refreshCounterMax;
    });

    if (response.statusCode == 200) {
      if (mounted) {
        setState(() {
          dateTime = DateTime.now();
        });
      }
      List responseJson = json.decode(response.body);
      var l = responseJson.map((m) => Task.fromJson(m)).toList();

      for (var element in l) {
        if (element.notifyID == '') {
          continue;
        }

        SharedPreferences.getInstance().then((sp) {
          var k = 'notifyID_${element.id}';
          if (!sp.containsKey(k) || sp.getString(k) != element.notifyID) {
            if (mounted) {
              _speak(element.title).then((value) => null);
            }

            sp.setString(k, element.notifyID);
          }
        });
      }

      return l;
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      return List<Task>.empty();
    }
  }

  @override
  void initState() {
    super.initState();
    initTts();

    futureAlbum = fetchTasks();
  }

  Future<void> initTts() async {
    flutterTts = FlutterTts();

    if (isAndroid) {
      await flutterTts.getDefaultEngine;
      await flutterTts.getDefaultVoice;
    }

    flutterTts.setErrorHandler((msg) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 10)),
      );
    });
  }

  @override
  void dispose() {
    stopRefrsh();
    flutterTts.stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    await flutterTts.setVolume(1);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
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
              onPressed: () {
                _speak('当前时间为:${DateTime.now().toString().substring(0, 19)}');
              },
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
                                Expanded(
                                  child: Text(
                                    snapshot.data![index].subTitle,
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
