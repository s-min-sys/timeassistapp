import 'package:flutter/material.dart';
import 'package:timeassistapp/components/alert.dart';
import 'package:timeassistapp/components/netutils.dart';
import 'package:timeassistapp/screens/model.dart';

class TasksDetail extends StatefulWidget {
  const TasksDetail({super.key});

  @override
  State<TasksDetail> createState() => _TasksDetailState();
}

class _TasksDetailState extends State<TasksDetail> {
  List<AlarmDetailModel> alarms = [];

  void refreshList() {
    NetUtils.requestHttp('/task/detail',
        method: NetUtils.getMethod,
        onSuccess: (resp) => {
              setState(() {
                alarms = (resp as List)
                    .map((e) => AlarmDetailModel.fromJson(e))
                    .toList();
              })
            },
        onError: (error) =>
            {AlertUtils.alertDialog(context: context, content: error)});
  }

  @override
  void initState() {
    super.initState();

    refreshList();
  }

  String alarmDetailTitle(AlarmDetailModel detail) {
    return '${detail.text} [${detail.value}] ${detail.aValue}  ${detail.leftTime}';
  }

  List<Widget> subTitlePiece(String text1, text2) {
    return [
      Text(
        text1,
        style: TextStyle(
          fontSize: 14,
          foreground: Paint()
            ..style = PaintingStyle.fill
            ..strokeWidth = 5
            ..color = Colors.green,
          shadows: const [
            Shadow(
              blurRadius: 10,
              color: Colors.black12,
              offset: Offset(0, 0),
            ),
            Shadow(
              blurRadius: 20,
              color: Colors.black26,
              offset: Offset(0, 0),
            ),
          ],
        ),
      ),
      const SizedBox(width: 2),
      Text(
        text2,
        style: TextStyle(
            fontSize: 10,
            foreground: Paint()
              ..style = PaintingStyle.fill
              ..strokeWidth = 5
              ..color = Colors.grey,
            shadows: const [
              Shadow(
                blurRadius: 12,
                color: Colors.black12,
                offset: Offset(0, 0),
              ),
              Shadow(
                blurRadius: 20,
                color: Colors.black26,
                offset: Offset(0, 0),
              ),
            ]),
      ),
      const SizedBox(width: 10),
    ];
  }

  Widget alarmDetailSubTitle(AlarmDetailModel detail) {
    return Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
      ...subTitlePiece('下次检测时刻', detail.checkAtS),
      ...subTitlePiece('开始显示时刻', detail.showAtS),
      ...subTitlePiece('过期时刻', detail.expireAtS),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('激活的任务详情'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: RefreshIndicator(
          onRefresh: refresh,
          child: ListView.separated(
            itemCount: alarms.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(alarmDetailTitle(alarms[index])),
              subtitle: alarmDetailSubTitle(alarms[index]),
            ),
            separatorBuilder: (BuildContext context, int index) {
              return const Divider();
            },
          ),
        ),
      ),
    );
  }

  Future<void> refresh() async {
    return Future.delayed(const Duration(microseconds: 10), () {
      refreshList();
    });
  }
}
