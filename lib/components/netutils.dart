import 'dart:convert';
import 'dart:developer';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'dart:io';
import 'package:timeassistapp/components/global.dart';

class NetUtils {
  /// http request methods
  static const String getMethod = 'get';
  static const String postMethod = 'post';

  static Uri getUri(String url, Map<String, dynamic>? parameters) {
    Map<String, dynamic> allParameters = {};
    if (parameters != null && parameters.isNotEmpty) {
      allParameters.addAll(parameters);
    }

    final splitted = url.split('?');
    if (splitted.length == 2) {
      url = splitted[0];
      final queries = splitted[1].split('&');
      for (int i = 0; i < queries.length; i++) {
        final qs = queries[i].split('=');
        if (qs.length == 2) {
          allParameters[qs[0]] = qs[1];
        }
      }
    }

    if (allParameters.isNotEmpty) {
      parameters = allParameters;
    } else {
      parameters = null;
    }

    String baseUrl = Global.getServerURL();
    baseUrl = baseUrl.toLowerCase();
    if (!url.startsWith('/')) {
      url = '/$url';
    }

    var index = baseUrl.indexOf('://');
    if (index != -1) {
      String s = baseUrl.substring(baseUrl.indexOf("://") + 3);
      var index2 = s.indexOf('/');
      if (index2 != -1) {
        s = s.substring(index2);
        if (s.endsWith('/')) {
          s = s.substring(0, s.length - 1);
        }

        url = s + url;
        baseUrl = baseUrl.substring(0, index2 + index + 3);
      }
    }

    var s = baseUrl.startsWith('https://')
        ? Uri.https(
            baseUrl.substring(baseUrl.indexOf("://") + 3), url, parameters)
        : Uri.http(
            baseUrl.substring(baseUrl.indexOf("://") + 3), url, parameters);

    log(s.toString());
    return s;
  }

  ///Get请求
  static void getHttp<T>(
    String url, {
    Map<String, dynamic>? parameters,
    Function(T)? onSuccess,
    Function(int code, String msg, T resp)? onResult,
    Function(String error)? onError,
    Function()? onReLogin,
    Function()? onFinally,
  }) async {
    try {
      EasyLoading.show(status: '加载中...', dismissOnTap: false);

      final client = HttpClient();

      String? proxy = Global.proxy;
      if (proxy != null && proxy != '') {
        client.findProxy = (url) {
          return 'PROXY $proxy';
        };
      }

      HttpClientRequest request = await client.getUrl(getUri(url, parameters));
      request.headers.add('Accept', 'application/json,*/*');
      request.headers.add('Content-Type', 'application/json');
      request.headers.add('Authorization', 'Basic ${Global.token}');

      HttpClientResponse response =
          await request.close().timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        Map<String, dynamic> resp =
            json.decode(await response.transform(utf8.decoder).join());

        var code = resp['code'];
        if (code < 100) {
          if (onSuccess != null && resp['code'] == 0) {
            onSuccess(resp['resp']);
          } else {
            throw Exception('erroMsg:${resp['message']}');
          }

          if (onResult != null) {
            onResult(resp['code'], resp['message'] as String, resp['resp']);
          }
        } else {
          if (code == 106 || code == 107) {
            // CodeInvalidToken CodeNeedAuth
            if (onReLogin != null) {
              onReLogin();

              return;
            }
          }
          throw Exception('erroMsg:${resp['message']}');
        }
      } else {
        if (onError != null) {
          onError('${response.statusCode}');
        }
      }
    } catch (e) {
      if (onError != null) {
        onError(e.toString());
      }
    } finally {
      EasyLoading.dismiss();
      if (onFinally != null) {
        onFinally();
      }
    }
  }

  static void postHttp<T>(
    String url, {
    Map<String, dynamic>? parameters,
    Object? data,
    Function(T)? onSuccess,
    Function(int code, String msg, T resp)? onResult,
    Function(String error)? onError,
    Function()? onReLogin,
    Function()? onFinally,
  }) async {
    try {
      EasyLoading.show(status: '加载中...', dismissOnTap: false);

      final client = HttpClient();
      String? proxy = Global.proxy;
      if (proxy != null && proxy != '') {
        client.findProxy = (url) {
          return 'PROXY $proxy';
        };
      }
      HttpClientRequest request = await client.postUrl(getUri(url, parameters));
      request.headers.add('Accept', 'application/json,*/*');
      request.headers.add('Content-Type', 'application/json');
      request.headers.add('Authorization', 'Basic ${Global.token}');
      request.add(utf8.encode(jsonEncode(data)));

      HttpClientResponse response =
          await request.close().timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        Map<String, dynamic> resp =
            json.decode(await response.transform(utf8.decoder).join());

        var code = resp['code'];
        if (code < 100) {
          if (onSuccess != null && resp['code'] == 0) {
            onSuccess(resp['resp']);
          } else {
            throw Exception('${resp['message']}');
          }

          if (onResult != null) {
            onResult(resp['code'], resp['message'] as String, resp['resp']);
          }
        } else {
          if (code == 106 || code == 107) {
            // CodeInvalidToken CodeNeedAuth
            if (onReLogin != null) {
              onReLogin();

              return;
            }
          }

          throw Exception('${resp['message']}');
        }
      } else {
        if (onError != null) {
          onError('${response.statusCode}');
        }
      }
    } catch (e) {
      if (onError != null) {
        onError(e.toString());
      }
    } finally {
      EasyLoading.dismiss();
      if (onFinally != null) {
        onFinally();
      }
    }
  }

  static Future<void> requestHttp<T>(
    String url, {
    Map<String, dynamic>? parameters,
    Object? data,
    method,
    Function(dynamic)? onSuccess,
    Function(int code, String msg, dynamic resp)? onResult,
    Function(String error)? onError,
    Function()? onReLogin,
    Function()? onFinally,
  }) async {
    parameters = parameters ?? {};
    method = method ?? 'GET';

    if (method == NetUtils.getMethod) {
      getHttp(url, parameters: parameters, onSuccess: (data) {
        if (onSuccess != null) {
          onSuccess(data);
        }
      }, onResult: (code, msg, data) {
        if (onResult != null) {
          onResult(code, msg, data);
        }
      }, onError: (error) {
        if (onError != null) {
          if (error.startsWith('Exception:')) {
            error = error.substring('Exception:'.length);
          }
          onError(error);
        }
      }, onReLogin: () {
        if (onReLogin != null) {
          onReLogin();
        }
      }, onFinally: () {
        if (onFinally != null) {
          onFinally();
        }
        return Future(() => 1);
      });
    } else if (method == NetUtils.postMethod) {
      postHttp(url, parameters: parameters, data: data, onSuccess: (data) {
        if (onSuccess != null) {
          onSuccess(data);
        }
      }, onResult: (code, msg, data) {
        if (onResult != null) {
          onResult(code, msg, data);
        }
      }, onError: (error) {
        if (onError != null) {
          if (error.startsWith('Exception:')) {
            error = error.substring('Exception:'.length);
          }
          onError(error);
        }
      }, onReLogin: () {
        if (onReLogin != null) {
          onReLogin();
        }
      }, onFinally: () {
        if (onFinally != null) {
          onFinally();
        }
        return Future(() => 1);
      });
    } else {
      if (onFinally != null) {
        onFinally();
      }
      return Future(() => 0);
    }
  }
}
