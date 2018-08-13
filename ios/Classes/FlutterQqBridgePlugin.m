#import "FlutterQqBridgePlugin.h"
#import <Flutter/Flutter.h>
#import <TencentOpenAPI/TencentOAuth.h>
#import <TencentOpenAPI/QQApiInterface.h>
#import <TencentOpenAPI/QQApiInterfaceObject.h>

@implementation FlutterQqBridgePlugin

- (void)dealloc
{
    _oauth.sessionDelegate = nil;
    _oauth = nil;
    _result = nil;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"flutter_qq_bridge"
            binaryMessenger:[registrar messenger]];
  FlutterQqBridgePlugin* instance = [[FlutterQqBridgePlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    } else if ([@"registerQq" isEqualToString:call.method]) {
        NSDictionary *dict = call.arguments;
        NSString *appId = dict[@"iOSAppId"];
        if (appId != nil) {
            NSLog(@"appId:%@", appId);
            _oauth = [[TencentOAuth alloc] initWithAppId:appId
                                             andDelegate:self];
        }
        result(nil);
    } else if ([@"login" isEqualToString:call.method]) {
        // 登录
        _result = result;
        _oauth.authMode = kAuthModeClientSideToken;
        [_oauth authorize:[self getPermissions] inSafari:NO];
    } else if([@"getUserInfo" isEqualToString:call.method]) {
        NSLog(@"~~~~~~~getUserInfo: %@", @"start~~~~~~~~~");
        _result = result;
        
        NSDictionary *dict = call.arguments;
        _oauth.openId = dict[@"openId"];
        _oauth.accessToken = dict[@"accessToken"];
        _oauth.expirationDate = [self UTCDateFromTimeStamap:[dict[@"expires"] stringValue]];
        
        BOOL success = [_oauth getUserInfo];
        // 失败则返回一个异常
        if (!success) {
            NSDictionary *result = @{@"Code": @0, @"Message": @"error: unknown"};
            _result(result);
        }
    } else if ([@"shareToQQ" isEqualToString:call.method]) {
        _result = result;
        // 分享到 QQ
        NSDictionary *dict = call.arguments;
        NSString *utf8String = dict[@"targetUrl"];
        NSString *title = dict[@"title"];
        NSString *description = dict[@"summary"];
        NSString *previewImageUrl = dict[@"imageUrl"];
        
        QQApiNewsObject *newsObj = [QQApiNewsObject objectWithURL:[NSURL URLWithString:utf8String]
                                                            title:title
                                                      description:description
                                                  previewImageURL:[NSURL URLWithString:previewImageUrl]];
        SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:newsObj];
        QQApiSendResultCode sent = [QQApiInterface sendReq:req];
        
        [self handleSendResult:sent];
    } else if ([@"shareToQzone" isEqualToString:call.method]) {
        NSLog(@"shareToQzone in");
        _result = result;
        // 分享到 Qzone
        NSDictionary *dict = call.arguments;
        NSString *utf8String = dict[@"targetUrl"];
        NSString *title = dict[@"title"];
        NSString *description = dict[@"summary"];
        NSString *previewImageUrl = dict[@"imageUrl"];
        
        QQApiNewsObject *newsObj = [QQApiNewsObject objectWithURL:[NSURL URLWithString:utf8String]
                                                            title:title
                                                      description:description
                                                  previewImageURL:[NSURL URLWithString:previewImageUrl]];
        SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:newsObj];
        QQApiSendResultCode sent = [QQApiInterface SendReqToQZone:req];
        
        [self handleSendResult:sent];
    }
    else {
        result(FlutterMethodNotImplemented);
    }
}

// 需要的权限
- (NSMutableArray *)getPermissions
{
    NSMutableArray * g_permissions = [[NSMutableArray alloc] initWithObjects:kOPEN_PERMISSION_GET_USER_INFO,
                                      kOPEN_PERMISSION_GET_SIMPLE_USER_INFO,
                                      kOPEN_PERMISSION_ADD_ALBUM,
                                      kOPEN_PERMISSION_ADD_ONE_BLOG,
                                      kOPEN_PERMISSION_ADD_SHARE,
                                      kOPEN_PERMISSION_ADD_TOPIC,
                                      kOPEN_PERMISSION_CHECK_PAGE_FANS,
                                      kOPEN_PERMISSION_GET_INFO,
                                      kOPEN_PERMISSION_GET_OTHER_INFO,
                                      kOPEN_PERMISSION_LIST_ALBUM,
                                      kOPEN_PERMISSION_UPLOAD_PIC,
                                      kOPEN_PERMISSION_GET_VIP_INFO,
                                      kOPEN_PERMISSION_GET_VIP_RICH_INFO, nil];
    
    return g_permissions;
}

// 字典转 json
- (NSString*)convertToJSONData:(id)infoDict
{
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:infoDict
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    
    NSString *jsonString = @"";
    
    if (! jsonData)
    {
        NSLog(@"Got an error: %@", error);
    }else
    {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    jsonString = [jsonString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];  //去除掉首尾的空白字符和换行字符
    
    [jsonString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    return jsonString;
}

// Date 转时间戳
- (long long)getDateTimeTOMilliSeconds:(NSDate *)datetime
{
    NSTimeInterval interval = [datetime timeIntervalSince1970];
    long long totalMilliseconds = interval * 1000 ;
    return totalMilliseconds;
}

// 时间戳转 Date
- (NSDate *)UTCDateFromTimeStamap:(NSString *)timeStamap
{
    NSTimeInterval timeInterval=[timeStamap doubleValue] / 1000;
    NSDate *UTCDate=[NSDate dateWithTimeIntervalSince1970:timeInterval];
    return UTCDate;
}

// 登录成功
- (void)tencentDidLogin
{
    //    [[NSNotificationCenter defaultCenter] postNotificationName:kLoginSuccessed object:self];
    NSDictionary *message = @{@"openid": _oauth.openId,
                              @"access_token": _oauth.accessToken,
                              @"expires_time": [NSNumber numberWithLongLong:[self getDateTimeTOMilliSeconds:_oauth.expirationDate]]};
    NSString *msgStr = [self convertToJSONData:message];
    NSDictionary *result = @{@"Code": @0, @"Message": msgStr};
    _result(result);
}

// 网络异常
- (void)tencentDidNotNetWork
{
    //    [[NSNotificationCenter defaultCenter] postNotificationName:kLoginFailed object:self];
    NSDictionary *result = @{@"Code": @1, @"Message": @"error: network"};
    _result(result);
}

// 登录失败
- (void)tencentDidNotLogin:(BOOL)cancelled
{
    if (cancelled) {
        NSDictionary *result = @{@"Code": @2, @"Message": @"cancel"};
        _result(result);
    } else {
        NSDictionary *result = @{@"Code": @1, @"Message": @"error: unkown"};
        _result(result);
    }
}

// 获取到用户信息
- (void)getUserInfoResponse:(APIResponse*) response
{
    NSDictionary *temp = [NSDictionary dictionaryWithObjectsAndKeys:response, @"kResponse", nil];
    APIResponse *apiResponse = temp[@"kResponse"];
    NSDictionary *message = apiResponse.jsonResponse;
    
    NSDictionary *resultMessage = @{@"nickname": message[@"nickname"],
                                    @"gender": message[@"gender"],
                                    @"province": message[@"province"],
                                    @"city": message[@"city"],
                                    @"year": message[@"year"],
                                    @"figureurl": message[@"figureurl"],
                                    @"figureurl_1": message[@"figureurl_1"],
                                    @"figureurl_2": message[@"figureurl_2"],
                                    @"figureurl_qq_1": message[@"figureurl_qq_1"],
                                    @"figureurl_qq_2": message[@"figureurl_qq_2"],
                                    };
    NSString *msgStr = [self convertToJSONData:resultMessage];
    NSDictionary *result = @{@"Code": @0, @"Message": msgStr};
    _result(result);
}

// 分享结果处理
- (void)handleSendResult:(QQApiSendResultCode)sendResult
{
    switch (sendResult)
    {
        case EQQAPIAPPNOTREGISTED:
        {
            NSDictionary *result = @{@"Code": @1, @"Message": @"App未注册"};
            _result(result);
            break;
        }
        case EQQAPIMESSAGECONTENTINVALID:
        case EQQAPIMESSAGECONTENTNULL:
        case EQQAPIMESSAGETYPEINVALID:
        {
            NSDictionary *result = @{@"Code": @1, @"Message": @"发送参数错误"};
            _result(result);
            break;
        }
        case EQQAPIQQNOTINSTALLED:
        {
            NSDictionary *result = @{@"Code": @1, @"Message": @"未安装手Q"};
            _result(result);
            break;
        }
        case EQQAPIQQNOTSUPPORTAPI:
        {
            NSDictionary *result = @{@"Code": @1, @"Message": @"手Q API接口不支持"};
            _result(result);
            break;
        }
        case EQQAPISENDFAILD:
        {
            NSDictionary *result = @{@"Code": @1, @"Message": @"发送失败"};
            _result(result);
            break;
        }
        case EQQAPIQZONENOTSUPPORTTEXT:
        {
            NSDictionary *result = @{@"Code": @1, @"Message": @"空间分享不支持QQApiTextObject，请使用QQApiImageArrayForQZoneObject分享"};
            _result(result);
            break;
        }
        case EQQAPIQZONENOTSUPPORTIMAGE:
        {
            NSDictionary *result = @{@"Code": @1, @"Message": @"空间分享不支持QQApiImageObject，请使用QQApiImageArrayForQZoneObject分享"};
            _result(result);
            break;
        }
        case EQQAPIVERSIONNEEDUPDATE:
        {
            NSDictionary *result = @{@"Code": @1, @"Message": @"当前QQ版本太低，需要更新"};
            _result(result);
            break;
        }
        case ETIMAPIVERSIONNEEDUPDATE:
        {
            NSDictionary *result = @{@"Code": @1, @"Message": @"当前TIM版本太低，需要更新"};
            _result(result);
            break;
        }
        case EQQAPITIMNOTINSTALLED:
        {
            NSDictionary *result = @{@"Code": @1, @"Message": @"未安装TIM"};
            _result(result);
            break;
        }
        case EQQAPITIMNOTSUPPORTAPI:
        {
            NSDictionary *result = @{@"Code": @1, @"Message": @"TIM API接口不支持"};
            _result(result);
            break;
        }
        case EQQAPISHAREDESTUNKNOWN:
        {
            NSDictionary *result = @{@"Code": @1, @"Message": @"未指定分享到QQ或TIM"};
            _result(result);
            break;
        }
        default:
        {
            NSDictionary *result = @{@"Code": @1, @"Message": @"unkown"};
            _result(result);
            break;
        }
    }
}

@end
