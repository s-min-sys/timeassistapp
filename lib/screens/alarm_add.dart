import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_pickers/pickers.dart';

enum AlarmType {
  once,
  recycleYear,
  recycleMonth,
  recycleWeek,
  recycleDay,
  recycleHour,
  recycleMinute
}

class AlarmAdd extends StatefulWidget {
  const AlarmAdd({super.key});

  @override
  State<AlarmAdd> createState() => _AlarmAddState();
}

class _AlarmAddState extends State<AlarmAdd> {
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
  final weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
  final hours = List.generate(24, (index) => (index)).toList();
  final minutes = List.generate(60, (index) => (index)).toList();
  final seconds = List.generate(60, (index) => (index)).toList();

  void showSelector(AlarmType type, bool lunarFlag) {
    List<String> suffix = [];
    List<List> data = [];

    if (type == AlarmType.once) {
      data.add([for (var i = 2024; i < 2024 + 10; i++) i]);
      suffix.add('年');
    }

    if (type == AlarmType.once || type == AlarmType.recycleYear) {
      if (lunarFlag) {
        data.add(monthsLunar);
        suffix.add('');
      } else {
        data.add(months);
        suffix.add('月');
      }
    }

    if (type == AlarmType.once ||
        type == AlarmType.recycleYear ||
        type == AlarmType.recycleMonth) {
      if (lunarFlag) {
        data.add(daysLunar);
        suffix.add('');
      } else {
        data.add(days);
        suffix.add('');
      }
    }

    if (type == AlarmType.recycleWeek) {
      data.add(weekDays);
      suffix.add('');
    }

    if (type == AlarmType.once ||
        type == AlarmType.recycleYear ||
        type == AlarmType.recycleMonth ||
        type == AlarmType.recycleWeek ||
        type == AlarmType.recycleDay) {
      data.add(hours);
      suffix.add('时');
    }

    if (type == AlarmType.once ||
        type == AlarmType.recycleYear ||
        type == AlarmType.recycleMonth ||
        type == AlarmType.recycleWeek ||
        type == AlarmType.recycleDay ||
        type == AlarmType.recycleHour) {
      data.add(minutes);
      suffix.add('分');
    }

    if (type == AlarmType.once ||
        type == AlarmType.recycleYear ||
        type == AlarmType.recycleMonth ||
        type == AlarmType.recycleWeek ||
        type == AlarmType.recycleDay ||
        type == AlarmType.recycleHour ||
        type == AlarmType.recycleMinute) {
      data.add(seconds);
      suffix.add('秒');
    }

    Pickers.showMultiPicker(
      context,
      data: data,
      suffix: suffix,
      onConfirm: (p, position) {
        log('$p - $position');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('组'),
      ),
      body: Column(children: [
        ElevatedButton(
            onPressed: () {
              showSelector(AlarmType.recycleWeek, true);
            },
            child: Text('add'))
      ]),
    );
  }
}
