#import <UIKit/UIKit.h>

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
    /* No visible UI — window stays nil so SpringBoard remains visible underneath */
    self.window = nil;

    NSString *resultTitle = @"降噪切换";
    NSString *resultBody = nil;

    BluetoothManager *btMgr = [NSClassFromString(@"BluetoothManager") sharedInstance];
    if (!btMgr) {
        resultBody = @"蓝牙服务不可用";
        goto sendNotification;
    }

    NSArray *devices = [btMgr connectedDevices];
    if (!devices || devices.count == 0) {
        resultBody = @"未连接蓝牙设备";
        goto sendNotification;
    }

    BOOL toggled = NO;
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

sendNotification:
    /* Use UILocalNotification — it pops from Notification Center as a banner */
    UILocalNotification *notif = [[UILocalNotification alloc] init];
    if (@available(iOS 8.2, *)) {
        notif.alertTitle = resultTitle;
    }
    notif.alertBody = resultBody ?: @"未知错误";
    notif.fireDate = [NSDate dateWithTimeIntervalSinceNow:0.01];
    notif.timeZone = [NSTimeZone defaultTimeZone];
    notif.soundName = nil;
    [[UIApplication sharedApplication] scheduleLocalNotification:notif];

    /* Give notification time to fire, then exit to kill the app instantly */
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        exit(0);
    });

    return YES;
}

@end