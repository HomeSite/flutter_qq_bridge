#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
#include <TencentOpenAPI/QQApiInterface.h>
#include <flutter_qq_bridge/FlutterQqBridgePlugin.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    [QQApiInterface handleOpenURL:url delegate:(id<QQApiInterfaceDelegate>)[FlutterQqBridgePlugin class]];
    return [TencentOAuth HandleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url{
    [QQApiInterface handleOpenURL:url delegate:(id<QQApiInterfaceDelegate>)[FlutterQqBridgePlugin class]];
    return [TencentOAuth HandleOpenURL:url];
}

@end
