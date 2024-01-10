import 'package:shared_preferences/shared_preferences.dart';

class Global {
  static bool devMode = false;

  static late SharedPreferences gSP;

  static void realInit(SharedPreferences sp) {
    gSP = sp;
  }

  static Future<void> init() async {
    final sp = await SharedPreferences.getInstance();
    realInit(sp);
  }

  static String? get token {
    return gSP.getString(getTokenStorageKey());
  }

  static set token(String? s) {
    if (s == null) {
      gSP.remove(getTokenStorageKey());
    } else {
      gSP.setString(getTokenStorageKey(), s);
    }
  }

  static String getTokenStorageKey() {
    if (Global.devMode) {
      return 'devToken';
    }

    return 'token';
  }
}
