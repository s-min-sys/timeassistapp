import 'package:timeassistapp/screens/alarm_add.dart';

class AlarmTypeModel {
  final String typeS;
  final AlarmType type;

  AlarmTypeModel({required this.typeS, required this.type});

  factory AlarmTypeModel.empty() {
    return AlarmTypeModel(typeS: '', type: AlarmType.once);
  }

  @override
  String toString() => typeS;
}
