import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Global {
  static bool _devMode = false;
  static String? _customServerURL = '';

  static late SharedPreferences gSP;

  static void realInit(SharedPreferences sp) {
    gSP = sp;
    customServerURL = gSP.getString('custom_server_url');
    bool? f = gSP.getBool('dev_mode');
    if (f != null) {
      devMode = f;
    }
  }

  static Future<void> init() async {
    final sp = await SharedPreferences.getInstance();
    realInit(sp);
  }

  static bool get devMode {
    return _devMode;
  }

  static set devMode(bool v) {
    _devMode = v;
    gSP.setBool('dev_mode', v);
  }

  static String? get customServerURL {
    return _customServerURL;
  }

  static set customServerURL(String? v) {
    _customServerURL = v;

    if (v == null) {
      gSP.setString('custom_server_url', '');
    } else {
      gSP.setString('custom_server_url', v);
    }
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
    if (_customServerURL != null && _customServerURL != '') {
      return 'token4Custom';
    }

    if (_devMode) {
      return 'devToken';
    }

    return 'token';
  }

  static String getServerURL() {
    String? serverURL = _customServerURL;
    String nowServerUrl = '';
    if (serverURL != null) {
      nowServerUrl = serverURL;
    }

    if (nowServerUrl != '') {
      return nowServerUrl;
    }

    return _devMode
        ? dotenv.env['SERVER_DOMAIN_DEV']!
        : dotenv.env['SERVER_DOMAIN']!;
  }
}
