#import <UIKit/UIKit.h>

/* Forward declarations */
static void showToggleBanner(NSString *message, BOOL success);
static BOOL performToggle(void);

/* BluetoothManager private framework interfaces */
@interface BluetoothDevice : NSObject
- (BOOL)isAppleAudioDevice;
- (NSInteger)listeningMode;
- (BOOL)setListeningMode:(NSInteger)arg1;
@end

@interface BluetoothManager : NSObject
+ (id)sharedInstance;
- (id)connectedDevices;
@end

/* SpringBoardHome icon interfaces */
@interface SBIcon : NSObject
- (NSString *)applicationBundleIdentifier;
@end

@interface SBIconView : UIView
- (SBIcon *)icon;
@end

/* SBApplication — reliable fallback hook point */
@interface SBApplication : NSObject
- (NSString *)bundleIdentifier;
- (void)activate;
@end

/* ========== Notification banner ========== */
static void showToggleBanner(NSString *message, BOOL success) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindowScene *scene = (UIWindowScene *)[UIApplication sharedApplication].connectedScenes.anyObject;
        UIWindow *keyWindow = scene.keyWindow;
        if (!keyWindow) return;

        CGFloat topOffset = scene.statusBarManager.statusBarFrame.size.height + 8;
        CGFloat bannerW = keyWindow.bounds.size.width - 24;
        CGFloat bannerH = 52;

        UIView *container = [[UIView alloc] initWithFrame:CGRectMake(12, topOffset, bannerW, bannerH)];
        container.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.92];
        container.layer.cornerRadius = 14;
        container.clipsToBounds = YES;
        container.alpha = 0;
        container.transform = CGAffineTransformMakeTranslation(0, -bannerH);

        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 6, bannerW - 24, 18)];
        titleLabel.text = @"降噪切换";
        titleLabel.font = [UIFont boldSystemFontOfSize:14];
        titleLabel.textColor = [UIColor whiteColor];

        UILabel *msgLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 26, bannerW - 24, 18)];
        msgLabel.text = message;
        msgLabel.font = [UIFont systemFontOfSize:13];
        msgLabel.textColor = [UIColor lightGrayColor];

        [container addSubview:titleLabel];
        [container addSubview:msgLabel];
        [keyWindow addSubview:container];

        [UIView animateWithDuration:0.35 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0 options:0 animations:^{
            container.alpha = 1;
            container.transform = CGAffineTransformIdentity;
        } completion:nil];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.25 animations:^{
                container.alpha = 0;
                container.transform = CGAffineTransformMakeTranslation(0, -bannerH);
            } completion:^(BOOL finished) {
                [container removeFromSuperview];
            }];
        });
    });
}

/* ========== Toggle logic ========== */
static BOOL performToggle(void) {
    BluetoothManager *btMgr = [%c(BluetoothManager) sharedInstance];
    if (!btMgr) {
        showToggleBanner(@"蓝牙服务不可用", NO);
        return NO;
    }

    NSArray *devices = [btMgr connectedDevices];
    if (!devices || devices.count == 0) {
        showToggleBanner(@"未连接蓝牙设备", NO);
        return NO;
    }

    for (BluetoothDevice *dev in devices) {
        if (![dev isAppleAudioDevice]) continue;

        NSInteger current = [dev listeningMode];
        NSLog(@"[NoiseCancelToggle] Current listeningMode: %ld", (long)current);

        NSInteger next = (current == 1) ? 2 : 1;

        BOOL result = [dev setListeningMode:next];
        NSLog(@"[NoiseCancelToggle] setListeningMode:%ld -> %@", (long)next, result ? @"OK" : @"FAIL");

        NSString *name = (next == 1) ? @"降噪" : @"通透";
        showToggleBanner(result ? [NSString stringWithFormat:@"已切换至 %@", name]
                                : @"切换失败，请重试",
                         result);
        return result;
    }

    showToggleBanner(@"未找到 AirPods", NO);
    return NO;
}

/* ========== Tweak entry ========== */
%ctor {
    NSLog(@"[NoiseCancelToggle] v1.0.3 injected");
}

/* --- Hook 1: SBIconListView.iconTapped: --- */
%hook SBIconListView
- (void)iconTapped:(SBIcon *)icon {
    if ([[icon applicationBundleIdentifier] isEqualToString:@"com.huhansibuxin.noisecanceltoggle"]) {
        NSLog(@"[NoiseCancelToggle] iconTapped: intercepted");
        performToggle();
        return;
    }
    %orig;
}
%end

/* --- Hook 2: SBIconView._handleTap: (iOS 16) --- */
%hook SBIconView
- (void)_handleTap:(id)gesture {
    SBIcon *icon = [self icon];
    if ([[icon applicationBundleIdentifier] isEqualToString:@"com.huhansibuxin.noisecanceltoggle"]) {
        NSLog(@"[NoiseCancelToggle] _handleTap: intercepted");
        performToggle();
        return;
    }
    %orig;
}
%end

/* --- Hook 3: SBApplication.activate (most reliable fallback) --- */
%hook SBApplication
- (void)activate {
    if ([[self bundleIdentifier] isEqualToString:@"com.huhansibuxin.noisecanceltoggle"]) {
        NSLog(@"[NoiseCancelToggle] SBApplication.activate intercepted");
        performToggle();
        return;
    }
    %orig;
}
%end