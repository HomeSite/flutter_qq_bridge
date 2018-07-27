package com.zll.qq.flutterqqbridge;

import android.content.Intent;
import android.os.Bundle;

import com.tencent.connect.UserInfo;
import com.tencent.connect.common.Constants;
import com.tencent.connect.share.QQShare;
import com.tencent.tauth.IUiListener;
import com.tencent.tauth.Tencent;
import com.tencent.tauth.UiError;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * FlutterQqBridgePlugin
 */
public class FlutterQqBridgePlugin implements MethodCallHandler {
  /**
   * Plugin registration.
   */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "flutter_qq_bridge");
    channel.setMethodCallHandler(new FlutterQqBridgePlugin(registrar));
  }

  private static Tencent tencent;
  private Registrar registrar;

  private FlutterQqBridgePlugin(Registrar registrar) {
    this.registrar = registrar;
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    OneListener listener = new OneListener();
    registrar.addActivityResultListener(listener);

    switch (call.method) {
      case "getPlatformVersion" :
        result.success("Android " + android.os.Build.VERSION.RELEASE);
        break;
      case "registerQq":
        String mAppid = call.argument("androidAppId");
        tencent = Tencent.createInstance(mAppid, registrar.context());
        result.success(null);
        break;
      case "login":
        listener.setResult(result);
        tencent.login(registrar.activity(), "all", listener);
        break;
      case "getUserInfo":
        listener.setResult(result);

        String openId = call.argument("openId");
        tencent.setOpenId(openId);

        String accessToken = call.argument("accessToken");
        Long expires = call.argument("expires");
        tencent.setAccessToken(accessToken, expires.toString());


        getUserInfo(listener);
        break;
      case "shareToQQ":
        listener.setResult(result);
        shareToQQ(call, listener);
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  private void getUserInfo(final OneListener listener) {
    final UserInfo userInfo = new UserInfo(registrar.activity(), tencent.getQQToken());
    userInfo.getUserInfo(listener);
  }

  private void shareToQQ(MethodCall call, final OneListener listener) {
    final Bundle params = new Bundle();
    int shareType = call.argument("shareType");

    params.putInt(QQShare.SHARE_TO_QQ_KEY_TYPE, shareType);
    params.putString(QQShare.SHARE_TO_QQ_TITLE, (String) call.argument("title"));
    params.putString(QQShare.SHARE_TO_QQ_TARGET_URL, (String) call.argument("targetUrl"));
    params.putString(QQShare.SHARE_TO_QQ_SUMMARY, (String) call.argument("summary"));
    params.putString(QQShare.SHARE_TO_QQ_IMAGE_URL, (String) call.argument("imageUrl"));
    params.putString(QQShare.SHARE_TO_QQ_APP_NAME, (String) call.argument("appName"));
    tencent.shareToQQ(registrar.activity(), params, listener);
  }

  private class OneListener implements IUiListener, PluginRegistry.ActivityResultListener {

    private Result result;

    void setResult(Result result) {
      this.result = result;
    }

    @Override
    public void onComplete(Object response) {
      Map<String, Object> re = new HashMap<>();
      re.put("Code", 0);
      re.put("Message", response.toString());
      result.success(re);
    }

    @Override
    public void onError(UiError uiError) {
      Map<String, Object> re = new HashMap<>();
      re.put("Code", 1);
      re.put("Message", "errorCode:" + uiError.errorCode + ";errorMessage:" + uiError.errorMessage);
      result.success(re);
    }

    @Override
    public void onCancel() {
      Map<String, Object> re = new HashMap<>();
      re.put("Code", 2);
      re.put("Message", "cancel");
      result.success(re);
    }

    @Override
    public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
      if (requestCode == Constants.REQUEST_LOGIN ||
              requestCode == Constants.REQUEST_QQ_SHARE ||
              requestCode == Constants.REQUEST_QZONE_SHARE ||
              requestCode == Constants.REQUEST_APPBAR) {
        Tencent.onActivityResultData(requestCode, resultCode, data, this);
        return true;
      }
      return false;
    }
  }
}
