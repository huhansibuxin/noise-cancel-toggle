#import <UIKit/UIKit.h>
#import <dlfcn.h>

@interface BluetoothDevice : NSObject
- (BOOL)isAppleAudioDevice;
- (NSInteger)listeningMode;
- (BOOL)setListeningMode:(NSInteger)arg1;
@end

@interface BluetoothManager : NSObject
+ (id)sharedInstance;
- (id)connectedDevices;
@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = nil;

    /* Ensure BluetoothManager framework is loaded in rootless env */
    dlopen("/var/jb/System/Library/PrivateFrameworks/BluetoothManager.framework/BluetoothManager", RTLD_NOW);

    NSString *resultBody = nil;
    BluetoothManager *btMgr = nil;
    NSArray *devices = nil;
    BOOL toggled = NO;

    btMgr = [NSClassFromString(@"BluetoothManager") sharedInstance];
    if (!btMgr) {
        resultBody = @"蓝牙服务不可用";
    } else {
        devices = [btMgr connectedDevices];
        if (!devices || devices.count == 0) {
            resultBody = @"未连接蓝牙设备";
        } else {
            for (id dev in devices) {
                if (![dev isAppleAudioDevice]) continue;

                NSInteger current = [dev listeningMode];
                NSInteger next = (current == 1) ? 2 : 1;

                BOOL ok = [dev setListeningMode:next];
                toggled = YES;
                resultBody = ok ? [NSString stringWithFormat:@"已切换至 %@", (next == 1) ? @"降噪" : @"通透"]
                                : @"切换失败，请重试";
                break;
            }
            if (!toggled) {
                resultBody = @"未找到 AirPods";
            }
        }
    }

    UILocalNotification *notif = [[UILocalNotification alloc] init];
    if (@available(iOS 8.2, *)) {
        notif.alertTitle = @"降噪切换";
    }
    notif.alertBody = resultBody ?: @"未知错误";
    notif.fireDate = [NSDate dateWithTimeIntervalSinceNow:0.01];
    notif.timeZone = [NSTimeZone defaultTimeZone];
    notif.soundName = nil;
    [[UIApplication sharedApplication] scheduleLocalNotification:notif];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        exit(0);
    });

    return YES;
}

@end