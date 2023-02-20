import 'package:flutter/material.dart';
import 'package:timeassistapp/screens/tasks.dart';

class MainWidget extends StatelessWidget {
  const MainWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('时间助手'),
      ),
      body: const Center(
        child: TasksWidget(),
      ),
    );
  }
}
