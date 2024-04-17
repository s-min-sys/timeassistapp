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

/*
type AlarmItem struct {
	ID       string `json:"id"`
	CheckAt  int64  `json:"check_at"`
	CheckAtS string `json:"check_at_s"`

	ShowAt    int64  `json:"show_at"`
	ShowAtS   string `json:"show_at_s"`
	ExpireAt  int64  `json:"expire_at"`
	ExpireAtS string `json:"expire_at_s"`

	Text   string `json:"text"`
	Value  string `json:"value"`
	AValue string `json:"a_value"`
}
*/
class AlarmDetailModel {
  final String id;
  final String checkAtS;
  final String showAtS;
  final String expireAtS;
  final String text;
  final String value;
  final String aValue;
  final String leftTime;

  AlarmDetailModel({
    required this.id,
    required this.checkAtS,
    required this.showAtS,
    required this.expireAtS,
    required this.text,
    required this.value,
    required this.aValue,
    required this.leftTime,
  });

  factory AlarmDetailModel.fromJson(Map<String, dynamic> json) {
    return AlarmDetailModel(
      id: json['id'],
      checkAtS: json['check_at_s'],
      showAtS: json['show_at_s'],
      expireAtS: json['expire_at_s'],
      text: json['text'],
      value: json['value'],
      aValue: json['a_value'],
      leftTime: json['left_time'],
    );
  }

  factory AlarmDetailModel.empty() {
    return AlarmDetailModel(
        id: '',
        checkAtS: '',
        showAtS: '',
        expireAtS: '',
        text: '',
        value: '',
        aValue: '',
        leftTime: '');
  }
}
