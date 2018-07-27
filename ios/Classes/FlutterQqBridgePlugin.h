#import <Flutter/Flutter.h>
#import <TencentOpenAPI/TencentOAuth.h>

@interface FlutterQqBridgePlugin : NSObject<FlutterPlugin, TencentSessionDelegate>
@property (nonatomic, retain)TencentOAuth *oauth;
@property FlutterResult result;
@end
