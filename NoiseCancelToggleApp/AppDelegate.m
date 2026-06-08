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
    /*
     * Fallback: if the tweak fails to intercept iconTapped: in SpringBoard,
     * the app itself will be launched. We perform the toggle and exit
     * immediately without showing any UI.
     */
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.hidden = YES;

    BluetoothManager *btMgr = [NSClassFromString(@"BluetoothManager") sharedInstance];
    if (!btMgr) {
        exit(0);
    }

    NSArray *devices = [btMgr connectedDevices];
    if (!devices || devices.count == 0) {
        exit(0);
    }

    for (id dev in devices) {
        if (![dev isAppleAudioDevice]) continue;

        NSInteger current = [dev listeningMode];
        NSInteger next;
        switch (current) {
            case 0: next = 1; break;
            case 1: next = 2; break;
            case 2: next = 0; break;
            case 3: next = 1; break;
            default: next = 1; break;
        }

        [dev setListeningMode:next];
        break;
    }

    exit(0);
    return YES;
}

@end