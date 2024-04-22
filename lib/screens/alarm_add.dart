import 'dart:convert';
import 'dart:developer';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pickers/pickers.dart';
import 'package:timeassistapp/components/alert.dart';
import 'package:timeassistapp/components/netutils.dart';
import 'package:timeassistapp/screens/model.dart';
import 'package:timeassistapp/screens/time_range_setter.dart';

enum TimeType {
  once,
  recycleYear,
  recycleMonth,
  recycleWeek,
  recycleDay,
  recycleHour,
  recycleMinute
}

int timeType2Submit(TimeType type) {
  if (type == TimeType.once) {
    return 1;
  }

  if (type == TimeType.recycleYear) {
    return 2;
  }

  if (type == TimeType.recycleMonth) {
    return 3;
  }

  if (type == TimeType.recycleWeek) {
    return 4;
  }

  if (type == TimeType.recycleDay) {
    return 5;
  }

  if (type == TimeType.recycleHour) {
    return 6;
  }

  if (type == TimeType.recycleMinute) {
    return 7;
  }

  return 0;
}

class AlarmAdd extends StatefulWidget {
  const AlarmAdd({super.key});

  @override
  State<AlarmAdd> createState() => _AlarmAddState();
}

class _AlarmAddState extends State<AlarmAdd> {
  final years = [for (var i = 2024; i < 2024 + 10; i++) i];
  final months = [
    '一月',
    '二月',
    '三月',
    '四月',
    '五月',
    '六月',
    '七月',
    '八月',
    '九月',
    '十月',
    '十一月',
    '十二月'
  ];
  final monthsLunar = [
    '一月(正月)',
    '二月(杏月)',
    '三月(桃月)',
    '四月(梅月)',
    '五月(榴月)',
    '六月(荷月)',
    '七月(瓜月)',
    '八月(桂月)',
    '九月(菊月)',
    '十月(阳月)',
    '十一月(冬月)',
    '十二月(腊月)'
  ];
  final days = List.generate(31, (index) => (index + 1)).toList();
  final daysLunar = [
    '初一',
    '初二',
    '初三',
    '初四',
    '初五',
    '初六',
    '初七',
    '初八',
    '初九',
    '初十',
    '十一',
    '十二',
    '十三',
    '十四',
    '十五',
    '十六',
    '十七',
    '十八',
    '十九',
    '二十',
    '廿一',
    '廿二',
    '廿三',
    '廿四',
    '廿五',
    '廿六',
    '廿七',
    '廿八',
    '廿九',
    '三十'
  ];
  final weekDays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
  final hours = List.generate(24, (index) => (index)).toList();
  final minutes = List.generate(60, (index) => (index)).toList();
  final seconds = List.generate(60, (index) => (index)).toList();
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
  String selectedDateValue = '';
  dynamic validTime;
  String validTimeS = '';

  final alarmTextController = TextEditingController();
  final alarmDateValueController = TextEditingController();
  final alarmEarlyShowMinutesController = TextEditingController();

  void updateDateValue(List<dynamic> ps, List<int> positions) {
    log('$ps - $positions');

    final alarmType = alarmTypeModel.type;

    String v = '';

    if (alarmType == TimeType.once ||
        alarmType == TimeType.recycleYear ||
        alarmType == TimeType.recycleMonth) {
      v += lunarFlag ? 'L' : 'S';
    }

    int idx = 0;
    if (alarmType == TimeType.once) {
      v += years[positions[idx++]].toString().padLeft(4, '0');
    }

    if (alarmType == TimeType.once || alarmType == TimeType.recycleYear) {
      v += (positions[idx++] + 1).toString().padLeft(2, '0');
    }

    if (alarmType == TimeType.once ||
        alarmType == TimeType.recycleYear ||
        alarmType == TimeType.recycleMonth) {
      v += (positions[idx++] + 1).toString().padLeft(2, '0');
    }

    if (alarmType == TimeType.recycleWeek) {
      v += positions[idx++].toString().padLeft(2, '0');
    }

    if (alarmType == TimeType.once ||
        alarmType == TimeType.recycleYear ||
        alarmType == TimeType.recycleMonth ||
        alarmType == TimeType.recycleWeek ||
        alarmType == TimeType.recycleDay) {
      v += positions[idx++].toString().padLeft(2, '0');
    }

    if (alarmType == TimeType.once ||
        alarmType == TimeType.recycleYear ||
        alarmType == TimeType.recycleMonth ||
        alarmType == TimeType.recycleWeek ||
        alarmType == TimeType.recycleDay ||
        alarmType == TimeType.recycleHour) {
      v += positions[idx++].toString().padLeft(2, '0');
    }

    if (alarmType == TimeType.once ||
        alarmType == TimeType.recycleYear ||
        alarmType == TimeType.recycleMonth ||
        alarmType == TimeType.recycleWeek ||
        alarmType == TimeType.recycleDay ||
        alarmType == TimeType.recycleHour ||
        alarmType == TimeType.recycleMinute) {
      v += positions[idx++].toString().padLeft(2, '0');
    }

    alarmDateValueController.text = v;

    setState(() {
      selectedDateValue = v;
    });
  }

  void showSelector(TimeType type, bool lunarFlag) {
    List<String> suffix = [];
    List<List> data = [];

    if (type == TimeType.once) {
      data.add([for (var i = 2024; i < 2024 + 10; i++) i]);
      suffix.add('年');
    }

    if (type == TimeType.once || type == TimeType.recycleYear) {
      if (lunarFlag) {
        data.add(monthsLunar);
        suffix.add('');
      } else {
        data.add(months);
        suffix.add('');
      }
    }

    if (type == TimeType.once ||
        type == TimeType.recycleYear ||
        type == TimeType.recycleMonth) {
      if (lunarFlag) {
        data.add(daysLunar);
        suffix.add('');
      } else {
        data.add(days);
        suffix.add('号');
      }
    }

    if (type == TimeType.recycleWeek) {
      data.add(weekDays);
      suffix.add('');
    }

    if (type == TimeType.once ||
        type == TimeType.recycleYear ||
        type == TimeType.recycleMonth ||
        type == TimeType.recycleWeek ||
        type == TimeType.recycleDay) {
      data.add(hours);
      suffix.add('时');
    }

    if (type == TimeType.once ||
        type == TimeType.recycleYear ||
        type == TimeType.recycleMonth ||
        type == TimeType.recycleWeek ||
        type == TimeType.recycleDay ||
        type == TimeType.recycleHour) {
      data.add(minutes);
      suffix.add('分');
    }

    if (type == TimeType.once ||
        type == TimeType.recycleYear ||
        type == TimeType.recycleMonth ||
        type == TimeType.recycleWeek ||
        type == TimeType.recycleDay ||
        type == TimeType.recycleHour ||
        type == TimeType.recycleMinute) {
      data.add(seconds);
      suffix.add('秒');
    }

    Pickers.showMultiPicker(
      context,
      data: data,
      suffix: suffix,
      onConfirm: (p, position) {
        updateDateValue(p, position);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (alarmTypeModel.typeS == '') {
      alarmTypeModel = alarmTypeModels.first;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('添加闹钟'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: DropdownSearch<AlarmTypeModel>(
                items: alarmTypeModels,
                selectedItem: alarmTypeModel,
                onChanged: (AlarmTypeModel? data) => setState(() {
                  if (data != null) {
                    alarmTypeModel = data;
                    int earlyShowMinutes = 0;

                    if (alarmTypeModel.type == TimeType.recycleYear) {
                      earlyShowMinutes = 60 * 24 * 30;
                    } else if (alarmTypeModel.type == TimeType.recycleMonth) {
                      earlyShowMinutes = 60 * 24;
                    } else if (alarmTypeModel.type == TimeType.recycleWeek) {
                      earlyShowMinutes = 60 * 24;
                    } else if (alarmTypeModel.type == TimeType.recycleDay) {
                      earlyShowMinutes = 60;
                    } else if (alarmTypeModel.type == TimeType.recycleHour) {
                      earlyShowMinutes = 10;
                    } else if (alarmTypeModel.type == TimeType.recycleMinute) {
                      earlyShowMinutes = 1;
                    } else {
                      earlyShowMinutes = 0;
                    }

                    alarmEarlyShowMinutesController.text =
                        earlyShowMinutes.toString();
                  }
                }),
                dropdownDecoratorProps: const DropDownDecoratorProps(
                  dropdownSearchDecoration:
                      InputDecoration(labelText: "Alarm类型"),
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
          ]),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: TextField(
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '闹钟内容',
                  hintText: '输入闹钟内容'),
              controller: alarmTextController,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: TextField(
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '闹钟时间',
                        hintText: '选择闹钟时间'),
                    controller: alarmDateValueController,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                    onPressed: () {
                      showSelector(alarmTypeModel.type, lunarFlag);
                    },
                    child: const Text('选择')),
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: TextField(
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '提前出现(分钟)',
                  hintText: '输入闹钟提前出现的分钟'),
              controller: alarmEarlyShowMinutesController,
            ),
          ),
          Text(validTimeS),
          ElevatedButton(
              onPressed: () async {
                validTime = await Navigator.push(
                  context,
                  // Create the SelectionScreen in the next step.
                  MaterialPageRoute(
                      builder: (context) => const TimeRangeSetter()),
                );
                setState(() {
                  validTimeS = jsonEncode(validTime);
                });
              },
              child: const Text('选择时间段')),
          Row(
            children: [
              ElevatedButton.icon(
                  onPressed: () => {
                        NetUtils.requestHttp('/alarm/add',
                            method: NetUtils.postMethod,
                            data: {
                              'a_type': timeType2Submit(alarmTypeModel.type),
                              'text': alarmTextController.text,
                              'value': alarmDateValueController.text,
                              'timeZone':
                                  DateTime.now().timeZoneOffset.inMinutes ~/ 60,
                              'early_show_minute': int.tryParse(
                                      alarmEarlyShowMinutesController.text) ??
                                  0,
                              'valid_time': validTime,
                            },
                            onSuccess: (resp) => {
                                  AlertUtils.alertDialog(
                                      context: context, content: '添加闹钟成功')
                                },
                            onError: (error) => {
                                  AlertUtils.alertDialog(
                                      context: context, content: error)
                                })
                      },
                  icon: const Icon(Icons.add_alarm),
                  label: const Text('添加闹钟'))
            ],
          )
        ]),
      ),
    );
  }
}
