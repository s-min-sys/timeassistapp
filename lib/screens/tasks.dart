import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'global.dart';

Future<List<Task>> fetchTasks() async {
  print('XXX ${Global.token}');
  final response = await http.get(
    Uri.parse('${dotenv.env['SERVER_DOMAIN']}/tasks'),
    headers: {
      'Authorization': 'Basic ${Global.token}',
    },
  );

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    List responseJson = json.decode(response.body);
    return responseJson.map((m) => Task.fromJson(m)).toList();
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    return List<Task>.empty();
  }
}

class Task {
  final String id;
  final String title;

  const Task({
    required this.id,
    required this.title,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['value'],
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
      const Duration(seconds: 2),
      (Timer t) => setState(
        () {
          futureAlbum = fetchTasks();
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
    return Center(
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: FutureBuilder<List<Task>>(
                future: futureAlbum,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    startRefreshIfNoTimer();

                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) => ListTile(
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.done,
                            color: Colors.green,
                          ),
                          onPressed: () {
                            http.post(
                              Uri.parse(
                                  '${dotenv.env['SERVER_DOMAIN']}/tasks/${snapshot.data![index].id}/done'),
                              headers: {
                                'Authorization': 'Basic ${Global.token}',
                              },
                            ).then((value) => futureAlbum = fetchTasks());
                          },
                          tooltip: 'done',
                        ),
                        title: Text(
                          snapshot.data![index].title,
                        ),
                      ),
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
        ],
      ),
    );
  }
}
