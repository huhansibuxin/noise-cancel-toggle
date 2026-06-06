#import <UIKit/UIKit.h>

@interface BluetoothDevice : NSObject
- (BOOL)isAppleAudioDevice;
- (unsigned int)listeningMode;
- (BOOL)setListeningMode:(unsigned int)arg1;
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
    /* Fallback: if the tweak fails to intercept, the app itself toggles ANC and exits */
    BluetoothManager *btMgr = [NSClassFromString(@"BluetoothManager") sharedInstance];
    if (btMgr) {
        NSArray *devices = [btMgr connectedDevices];
        for (id dev in devices) {
            if ([dev isAppleAudioDevice]) {
                unsigned int current = [dev listeningMode];
                unsigned int next = (current == 1) ? 2 : 1;
                [dev setListeningMode:next];
                break;
            }
        }
    }
    exit(0);
    return YES;
}

@end