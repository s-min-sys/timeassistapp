import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeassistapp/components/global.dart';
import 'package:timeassistapp/components/netutils.dart';
import 'package:timeassistapp/screens/main.dart';
import 'package:http/http.dart' as http;

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final userNameController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    fetchTasksByToken(context);
    super.initState();
  }

  @override
  void dispose() {
    userNameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(80.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              TextFormField(
                controller: userNameController,
                decoration: const InputDecoration(
                  hintText: 'Username',
                ),
              ),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(
                  hintText: 'Password',
                ),
                obscureText: true,
              ),
              const SizedBox(
                height: 24,
              ),
              ElevatedButton(
                onPressed: () {
                  fetchTasks(context, userNameController.text,
                      passwordController.text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                ),
                child: const Text('ENTER'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> explainResponse(
    BuildContext context, http.Response response, String token) async {
  if (response.statusCode == 200) {
    Global.token = token;
    SharedPreferences.getInstance().then((sp) => sp.setString('token', token));
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainWidget()),
        (route) => false);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response.statusCode.toString())),
    );
  }
}

void fetchTasks(BuildContext context, String user, String pass) {
  Global.token = base64.encode(latin1.encode('$user:$pass'));
  fetchTasksByToken(context);
}

void fetchTasksByToken(BuildContext context) {
  NetUtils.requestHttp('/tasks', method: NetUtils.getMethod, onSuccess: (data) {
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainWidget()),
        (route) => false);
  }, onError: (error) {});
}
