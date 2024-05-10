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

  final customServerURLController = TextEditingController();
  bool devMode = false;
  final proxyController = TextEditingController();

  @override
  void initState() {
    customServerURLController.addListener(() {
      setState(() {});
    });
    fetchTasksByToken(context);
    super.initState();
  }

  @override
  void dispose() {
    userNameController.dispose();
    passwordController.dispose();
    customServerURLController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      onDrawerChanged: (bool isOpened) {
        if (!isOpened) {
          String u = customServerURLController.text;
          if (u != '') {
            Global.customServerURL = u;
          } else {
            Global.customServerURL = '';
            Global.devMode = devMode;
          }

          String p = proxyController.text;
          if (p != '') {
            Global.proxy = p;
          } else {
            Global.proxy = '';
          }

          fetchTasksByToken(context);
        } else {
          String? customServerURL = Global.customServerURL;
          if (customServerURL != null) {
            customServerURLController.text = customServerURL;
          } else {
            devMode = Global.devMode;
          }

          String? p = Global.proxy;
          if (p != null && p != '') {
            proxyController.text = p;
          }
        }
      },
      drawer: Drawer(
          child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text('设置'),
          ),
          ListTile(
            title: TextField(
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '自定义服务地址',
                  hintText: '输入自定义服务地址'),
              controller: customServerURLController,
            ),
          ),
          Visibility(
            visible: customServerURLController.text == '',
            child: CheckboxListTile(
              title: const Text('预置本地服务地址'),
              onChanged: (bool? value) {
                setState(() {
                  devMode = value!;
                });
              },
              value: devMode,
            ),
          ),
          ListTile(
            title: TextField(
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '代理',
                  hintText: '输入HTTP或者HTTPS代理地址和端口号'),
              controller: proxyController,
            ),
          ),
        ],
      )),
      appBar: AppBar(
        title: const Text('登录'),
      ),
      body: SingleChildScrollView(
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
              ),
              const SizedBox(
                height: 130,
              ),
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
  NetUtils.requestHttp('/shows', method: NetUtils.getMethod, onSuccess: (data) {
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainWidget()),
        (route) => false);
  }, onError: (error) {});
}
