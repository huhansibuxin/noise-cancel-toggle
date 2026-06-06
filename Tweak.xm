#import <UIKit/UIKit.h>

/* BluetoothManager private framework interfaces */
@interface BluetoothDevice : NSObject
- (BOOL)isAppleAudioDevice;
- (unsigned int)listeningMode;
- (BOOL)setListeningMode:(unsigned int)arg1;
@end

@interface BluetoothManager : NSObject
+ (id)sharedInstance;
- (id)connectedDevices;
@end

/* SpringBoardHome icon interfaces */
@interface SBIcon : NSObject
- (NSString *)applicationBundleIdentifier;
@end

/*
 * Hook SBIconListView to intercept taps on our companion app icon.
 * When the icon for com.huhansibuxin.noisecanceltoggle is tapped,
 * we toggle AirPods noise control mode and prevent app launch.
 */
%hook SBIconListView

- (void)iconTapped:(SBIcon *)icon {
    NSString *bundleID = [icon applicationBundleIdentifier];

    if ([bundleID isEqualToString:@"com.huhansibuxin.noisecanceltoggle"]) {
        BluetoothManager *btMgr = [%c(BluetoothManager) sharedInstance];
        if (!btMgr) return;

        NSArray *devices = [btMgr connectedDevices];
        for (BluetoothDevice *dev in devices) {
            if (![dev isAppleAudioDevice]) continue;

            unsigned int current = [dev listeningMode];
            /* 0 = Off, 1 = ANC, 2 = Transparency, 3 = Adaptive */
            unsigned int next = (current == 1) ? 2 : 1;
            [dev setListeningMode:next];
            return;
        }
        return;
    }

    %orig;
}

%end