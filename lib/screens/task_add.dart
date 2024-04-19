import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:timeassistapp/components/alert.dart';
import 'package:timeassistapp/components/netutils.dart';
import 'package:timeassistapp/screens/alarm_add.dart';
import 'package:timeassistapp/screens/model.dart';

class TaskAdd extends StatefulWidget {
  const TaskAdd({super.key});

  @override
  State<TaskAdd> createState() => _TaskAddState();
}

class _TaskAddState extends State<TaskAdd> {
  final List<AlarmTypeModel> alarmTypeModels = [
    AlarmTypeModel(typeS: '单次', type: TimeType.once),
    AlarmTypeModel(typeS: '年循环', type: TimeType.recycleYear),
    AlarmTypeModel(typeS: '月循环', type: TimeType.recycleMonth),
    AlarmTypeModel(typeS: '周循环', type: TimeType.recycleWeek),
    AlarmTypeModel(typeS: '天循环', type: TimeType.recycleDay),
    AlarmTypeModel(typeS: '时循环', type: TimeType.recycleHour),
    AlarmTypeModel(typeS: '分循环', type: TimeType.recycleMinute),
  ];
  AlarmTypeModel alarmTypeModel = AlarmTypeModel.empty();
  bool lunarFlag = false;
  bool autoFlag = false;
  final textController = TextEditingController();
  final valueController = TextEditingController();

  void addNewTask() {
    var taskText = textController.text;
    if (taskText == '') {
      AlertUtils.alertDialog(context: context, content: '任务内容为空');
      return;
    }

    var valueText = valueController.text;
    int value = 0;
    if (alarmTypeModel.type != TimeType.once) {
      if (valueText == '') {
        value = 1;
      } else {
        var valueT = int.tryParse(valueText);
        if (valueT == null) {
          AlertUtils.alertDialog(context: context, content: '任务周期只能是自然数');
          return;
        }

        value = valueT;
      }
    }

    NetUtils.requestHttp('/add/task',
        method: NetUtils.postMethod,
        data: {
          't_type': timeType2Submit(alarmTypeModel.type),
          'lunar_flag': lunarFlag,
          'text': taskText,
          'value': value,
          'time_zone': DateTime.now().timeZoneOffset.inMinutes ~/ 60,
          'auto': autoFlag,
        },
        onSuccess: (resp) =>
            {AlertUtils.alertDialog(context: context, content: '添加任务成功')},
        onError: (error) =>
            {AlertUtils.alertDialog(context: context, content: error)});
  }

  @override
  Widget build(BuildContext context) {
    if (alarmTypeModel.typeS == '') {
      alarmTypeModel = alarmTypeModels.first;
    }

    if (valueController.text == '') {
      valueController.text = '1';
    }

    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('添加任务'),
        ),
        body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownSearch<AlarmTypeModel>(
                        items: alarmTypeModels,
                        selectedItem: alarmTypeModel,
                        onChanged: (AlarmTypeModel? data) => setState(() {
                          if (data != null) {
                            alarmTypeModel = data;
                          }
                        }),
                        dropdownDecoratorProps: const DropDownDecoratorProps(
                          dropdownSearchDecoration:
                              InputDecoration(labelText: "任务类型"),
                        ),
                      ),
                    ),
                    const Text('阴历'),
                    Switch(
                      value: lunarFlag,
                      onChanged: (bool value) {
                        setState(() {
                          lunarFlag = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: '任务内容',
                      hintText: '输入任务内容'),
                  controller: textController,
                ),
              ),
              Visibility(
                visible: alarmTypeModel.type != TimeType.once,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '跨越周期数',
                        hintText: '比如选择了天循环，2就代表任务过期时间为2天'),
                    controller: valueController,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const Text('自动替换过期任务'),
                    Switch(
                      value: autoFlag,
                      onChanged: (bool value) {
                        setState(() {
                          autoFlag = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                      onPressed: () => {addNewTask()},
                      icon: const Icon(Icons.add_task),
                      label: const Text('添加任务'))
                ],
              )
            ])));
  }
}
