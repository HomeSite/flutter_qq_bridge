import 'package:flutter/material.dart';
import 'package:flutter_qq_bridge/flutter_qq_bridge.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _loginRes = 'Unknown';
  String _shareRes = 'Unknown';
  String _userInfo = 'Unknown';

  Tencent _tencent;
  QqUser _qqUser;

  _login() async {
    var res = await FlutterQqBridge.login();

    if (res.code == 0) {
      _tencent = Tencent.fromJson(res.message);
      setState(() {
        _loginRes = 'openId:${_tencent.openId}, accessToken:${_tencent.accessToken}, expires:${_tencent.expiresTime}';
      });
    }
  }

  _share() async {
    var res = await FlutterQqBridge.shareToQQ(ShareQqContent(
      title: 'Remeet-只有00后的脱单神器',
      summary: '我们只想做个简单干净的聊天软件，帮你遇见喜欢的人。',
      targetUrl: 'http://a.app.qq.com/o/simple.jsp?pkgname=com.haisong.remeet',
      imageUrl: 'http://pp.myapp.com/ma_icon/0/icon_52621236_1517135649/96',
      appName: 'Remeet',
    ));

    setState(() {
      _shareRes = 'share -> code: ${res.code}, message:${res.message}';
    });
  }

  _user() async {
    if (_tencent != null) {
      var res = await FlutterQqBridge.getUserInfo(_tencent);
      if (res.code == 0) {
        _qqUser = QqUser.fromJson(res.message);
        setState(() {
          _userInfo = 'nickname:${_qqUser.nickname}, '
              'gender:${_qqUser.gender}, '
              'year:${_qqUser.year}, '
              'province:${_qqUser.province}, '
              'city:${_qqUser.city}, '
              'figureurl:${_qqUser.figureurl},';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    FlutterQqBridge.registerQq('1107027380', '1106056827');
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(padding: EdgeInsets.all(30.0),
                  child: GestureDetector(
                    onTap: _login,
                    child: Text('qq login \n $_loginRes', style: TextStyle(fontSize: 20.0, color: Colors.black),),
                  )
              ),

              Padding(padding: EdgeInsets.all(30.0),
                  child: GestureDetector(
                    onTap: _share,
                    child: Text('qq share \n $_shareRes', style: TextStyle(fontSize: 20.0, color: Colors.black),),
                  )
              ),

              Padding(padding: EdgeInsets.all(30.0),
                  child: GestureDetector(
                    onTap: _user,
                    child: Text('qq user \n $_userInfo', style: TextStyle(fontSize: 20.0, color: Colors.black),),
                  )
              ),
            ],
          ),
        ),
      ),
    );
  }
}