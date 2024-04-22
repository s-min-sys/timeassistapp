import 'package:flutter/material.dart';
import 'package:timeassistapp/components/alert.dart';
import 'package:timeassistapp/screens/model.dart';

class TimeRangeSetter extends StatefulWidget {
  const TimeRangeSetter({super.key});

  @override
  State<TimeRangeSetter> createState() => _TimeRangeSetterState();
}

class _TimeRangeSetterState extends State<TimeRangeSetter> {
  final monthController = TextEditingController();
  final weekInMonthController = TextEditingController();
  final dayInMonthController = TextEditingController();
  final dayInWeekController = TextEditingController();
  final hourController = TextEditingController();

  ValidTime validTime = ValidTime();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('时间范围设置'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '月选择',
                    hintText: '例如 1-3,4-13 代表 1月份2月份 和 4月份到12月份'),
                controller: monthController,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '周选择(单月中)',
                    hintText: '例如 0-3,4-7 代表 周日到周三 和 周四到周六'),
                controller: weekInMonthController,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '日选择(单月中)',
                    hintText: '例如 1-3,4-7 代表 从1号2号 和 4号到6号'),
                controller: dayInMonthController,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '日选择(单周中)',
                    hintText: '例如 1-3,4-7 代表 从1号2号 和 4号到6号'),
                controller: dayInWeekController,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '小时选择',
                    hintText: '例如 1-3,11-20 代表 从1点2点 和 11到19点'),
                controller: hourController,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                      onPressed: () => {confirm()},
                      icon: const Icon(Icons.timer_sharp),
                      label: const Text('确定')),
                  const SizedBox(width: 20),
                  ElevatedButton.icon(
                      onPressed: () => {Navigator.pop(context, null)},
                      icon: const Icon(Icons.cancel),
                      label: const Text('取消')),
                ],
              )
            ],
          ),
        ));
  }

  List<dynamic> process(String s) {
    List<dynamic> d = [];

    for (var kv in s.split(',')) {
      kv = kv.trim();
      final kvs = kv.split('-');
      if (kvs.length != 2) {
        return [];
      }
      d.add(
          {'start': int.parse(kvs[0].trim()), 'end': int.parse(kvs[1].trim())});
    }

    return d;
  }

  void confirm() {
    var d = {};

    var v = monthController.text;
    if (v.isNotEmpty) {
      d['valid_months_in_year'] = {};

      var curD = process(v);
      if (curD.isEmpty) {
        AlertUtils.alertDialog(context: context, content: '月选择 输入数据有误');

        return;
      }
      d['valid_months_in_year']['valid_ranges'] = curD;
    }

    v = weekInMonthController.text;
    if (v.isNotEmpty) {
      d['valid_weeks_in_month'] = {};

      var curD = process(v);
      if (curD.isEmpty) {
        AlertUtils.alertDialog(context: context, content: '周选择(单月中) 输入数据有误');

        return;
      }
      d['valid_weeks_in_month']['valid_ranges'] = curD;
    }

    v = dayInMonthController.text;
    if (v.isNotEmpty) {
      d['valid_days_in_month'] = {};

      var curD = process(v);
      if (curD.isEmpty) {
        AlertUtils.alertDialog(context: context, content: '日选择(单月中) 输入数据有误');

        return;
      }
      d['valid_days_in_month']['valid_ranges'] = curD;
    }

    v = dayInWeekController.text;
    if (v.isNotEmpty) {
      d['valid_days_in_week'] = {};

      var curD = process(v);
      if (curD.isEmpty) {
        AlertUtils.alertDialog(context: context, content: '日选择(单周中) 输入数据有误');

        return;
      }
      d['valid_days_in_week']['valid_ranges'] = curD;
    }

    v = hourController.text;
    if (v.isNotEmpty) {
      d['valid_hours_in_day'] = {};

      var curD = process(v);
      if (curD.isEmpty) {
        AlertUtils.alertDialog(context: context, content: '小时选择 输入数据有误');

        return;
      }
      d['valid_hours_in_day']['valid_ranges'] = curD;
    }

    Navigator.pop(context, d);
  }
}
