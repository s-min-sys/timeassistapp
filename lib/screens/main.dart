import 'package:flutter/material.dart';
import 'package:timeassistapp/screens/tasks.dart';

class MainWidget extends StatelessWidget {
  const MainWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: TasksWidget(),
      ),
    );
  }
}
