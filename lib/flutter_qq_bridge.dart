import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

class FlutterQqBridge {
  static const MethodChannel _channel = const MethodChannel('flutter_qq_bridge');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<void> registerQq(String androidAppId, String iOSAppId) async {
    await _channel.invokeMethod('registerQq', {'androidAppId': androidAppId, 'iOSAppId': iOSAppId});
  }

  static Future<QQResult> login() async {
    final Map<dynamic, dynamic> result = await _channel.invokeMethod('login');
    QQResult qqResult = new QQResult();
    qqResult.code = result["Code"];
    qqResult.message = result["Message"].toString();
    return qqResult;
  }

  static Future<QQResult> getUserInfo(Tencent tencent) async {
    final Map<dynamic, dynamic> result = await _channel.invokeMethod('getUserInfo', {'openId': tencent.openId, 'accessToken': tencent.accessToken, 'expires': tencent.expiresTime});
    QQResult qqResult = new QQResult();
    qqResult.code = result["Code"];
    qqResult.message = result["Message"].toString();
    return qqResult;
  }

  static Future<QQResult> shareToQQ(ShareQqContent shareContent) async {
    Map<String, Object> params;
    params = {
      "shareType": 1,
      "title": shareContent.title,
      "targetUrl": shareContent.targetUrl,
      "summary": shareContent.summary,
      "imageUrl": shareContent.imageUrl,
      "imageLocalUrl": shareContent.imageLocalUrl,
      "appName": shareContent.appName,
    };

    final Map<dynamic, dynamic> result = await _channel.invokeMethod('shareToQQ', params);
    QQResult qqResult = new QQResult();
    qqResult.code = result["Code"];
    qqResult.message = result["Message"].toString();
    return qqResult;
  }
}

class QQResult {
  int code;
  String message;
}

class Tencent {
  String openId;
  String accessToken;
  int expiresTime;

  Tencent({
    this.openId,
    this.accessToken,
    this.expiresTime,
  });

  static Tencent fromJson(String jsonStr) {
    var json = JsonDecoder().convert(jsonStr);
    return Tencent(
      openId: json['openid'],
      accessToken: json['access_token'],
      expiresTime: json['expires_time'],
    );
  }
}

class QqUser {
  String nickname;
  String gender;
  String province;
  String city;
  String year;
  String figureurl;

  QqUser({
    this.nickname,
    this.gender,
    this.province,
    this.city,
    this.year,
    this.figureurl,
  });

  static QqUser fromJson(String jsonStr) {
    var json = JsonDecoder().convert(jsonStr);

    return QqUser(
      nickname: json['nickname'],
      gender: json['gender'],
      province: json['province'],
      city: json['city'],
      year: json['year'],
      figureurl: _getFigureurl(json),
    );
  }

  static String _getFigureurl(dynamic json) {
    var figureurl_qq_2 = json['figureurl_qq_2'].toString();
    if (figureurl_qq_2 != null && figureurl_qq_2.isNotEmpty) {
      return figureurl_qq_2;
    }

    var figureurl_2 = json['figureurl_2'].toString();
    if (figureurl_2 != null && figureurl_2.isNotEmpty) {
      return figureurl_2;
    }

    var figureurl_qq_1 = json['figureurl_qq_1'].toString();
    if (figureurl_qq_1 != null && figureurl_qq_1.isNotEmpty) {
      return figureurl_qq_1;
    }

    var figureurl_1 = json['figureurl_1'].toString();
    if (figureurl_1 != null && figureurl_1.isNotEmpty) {
      return figureurl_2;
    }

    var figureurl = json['figureurl'].toString();
    if (figureurl != null && figureurl.isNotEmpty) {
      return figureurl;
    }

    return '';
  }
}

class ShareQqContent {
  String title;
  String targetUrl;
  String summary;

  String imageUrl;
  String imageLocalUrl;

  String appName;

  ShareQqContent({
    this.title = '',
    this.targetUrl = '',
    this.summary = '',
    this.imageUrl = '',
    this.imageLocalUrl = '',
    this.appName = '',
  });
}