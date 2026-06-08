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
    self.window = nil;

    NSBundle *bmBundle = [NSBundle bundleWithPath:@"/var/jb/System/Library/PrivateFrameworks/BluetoothManager.framework"];
    [bmBundle load];

    BluetoothManager *btMgr = [NSClassFromString(@"BluetoothManager") sharedInstance];
    if (!btMgr) exit(0);

    NSArray *devices = [btMgr connectedDevices];
    if (!devices.count) exit(0);

    for (id dev in devices) {
        if (![dev isAppleAudioDevice]) continue;
        NSInteger current = [dev listeningMode];
        NSInteger next = (current == 1) ? 2 : 1;
        [dev setListeningMode:next];
        break;
    }

    exit(0);
    return YES;
}

@end