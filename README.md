# flutter_qq_bridge
支持 Android / iOS：
>1.登录
>2.获取用户基本信息
>3.分享（目前仅支持新闻类型）

## Getting Started

### 1. 环境配置
#### Android

##### AndroidManifest

```
...

<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>

...

<activity
    android:name="com.tencent.connect.common.AssistActivity"
    android:configChanges="orientation|keyboardHidden"
    android:screenOrientation="behind"
    android:theme="@android:style/Theme.Translucent.NoTitleBar" />
<activity
    android:name="com.tencent.tauth.AuthActivity"
    android:launchMode="singleTask"
    android:noHistory="true" >
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="tencent${your app_id}" />
    </intent-filter>
</activity>
```



#### iOS
详情请参考腾讯官方文档及网络上更多优秀解答

### 2. Flutter 中使用

```
import 'package:flutter_qq_bridge/flutter_qq_bridge.dart';
```

#### ① 初始化

```
await FlutterQqBridge.registerQq('$androidAppId', '$iOSAppId');
```

#### ② QQ 登录

```
var res = await FlutterQqBridge.login();

if (res.code == 0) { // success
  _tencent = Tencent.fromJson(res.message);
  
  // update UI
  setState(() {
    _loginRes = 'openId:${_tencent.openId}, accessToken:${_tencent.accessToken}, expires:${_tencent.expiresTime}';
  });
}
```
#### ③ 获取用户基本信息（登录之后）

```
if (_tencent != null) { // _tencent from login success
  var res = await FlutterQqBridge.getUserInfo(_tencent);
  if (res.code == 0) {
    _qqUser = QqUser.fromJson(res.message);
    
    // update UI
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
```

#### ④ 分享
```
var res = await FlutterQqBridge.shareToQQ(ShareQQContent(
  title: 'Remeet-只有00后的脱单神器',
  summary: '我们只想做个简单干净的聊天软件，帮你遇见喜欢的人。',
  targetUrl: 'http://a.app.qq.com/o/simple.jsp?pkgname=com.haisong.remeet',
  imageUrl: 'http://pp.myapp.com/ma_icon/0/icon_52621236_1517135649/96',
  appName: 'Remeet',
));

// update UI
setState(() {
  _shareRes = 'share -> code: ${res.code}, message:${res.message}';
});
```

