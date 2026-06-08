#import <UIKit/UIKit.h>

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

/* ========== Banner notification helper ========== */
static NSString *modeName(NSInteger mode) {
    switch (mode) {
        case 0: return @"关闭";
        case 1: return @"降噪";
        case 2: return @"通透";
        case 3: return @"自适应";
        default: return @"未知";
    }
}

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

        UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(12, 12, 24, 24)];
        iconView.contentMode = UIViewContentModeScaleAspectFit;
        iconView.tintColor = success ? [UIColor systemGreenColor] : [UIColor systemRedColor];

        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(44, 6, bannerW - 56, 18)];
        titleLabel.text = @"降噪切换";
        titleLabel.font = [UIFont boldSystemFontOfSize:14];
        titleLabel.textColor = [UIColor whiteColor];

        UILabel *msgLabel = [[UILabel alloc] initWithFrame:CGRectMake(44, 26, bannerW - 56, 18)];
        msgLabel.text = message;
        msgLabel.font = [UIFont systemFontOfSize:13];
        msgLabel.textColor = [UIColor lightGrayColor];

        [container addSubview:iconView];
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

/* ========== Tweak entry point ========== */
%ctor {
    NSLog(@"[NoiseCancelToggle] Tweak injected into SpringBoard");
}

%hook SBIconListView

- (void)iconTapped:(SBIcon *)icon {
    NSString *bundleID = [icon applicationBundleIdentifier];

    if ([bundleID isEqualToString:@"com.huhansibuxin.noisecanceltoggle"]) {
        NSLog(@"[NoiseCancelToggle] Intercepted icon tap, toggling ANC...");

        BluetoothManager *btMgr = [%c(BluetoothManager) sharedInstance];
        if (!btMgr) {
            showToggleBanner(@"蓝牙服务不可用", NO);
            return;
        }

        NSArray *devices = [btMgr connectedDevices];
        if (!devices || devices.count == 0) {
            showToggleBanner(@"未连接蓝牙设备", NO);
            return;
        }

        for (BluetoothDevice *dev in devices) {
            if (![dev isAppleAudioDevice]) continue;

            NSInteger current = [dev listeningMode];
            NSLog(@"[NoiseCancelToggle] Current listeningMode: %ld", (long)current);

            /* Toggle between ANC(1) and Transparency(2) only */
            NSInteger next = (current == 1) ? 2 : 1;

            BOOL result = [dev setListeningMode:next];
            NSLog(@"[NoiseCancelToggle] setListeningMode:%ld -> %@", (long)next, result ? @"OK" : @"FAIL");

            if (result) {
                showToggleBanner([NSString stringWithFormat:@"已切换至 %@", modeName(next)], YES);
            } else {
                showToggleBanner(@"切换失败，请重试", NO);
            }
            return;
        }

        showToggleBanner(@"未找到 AirPods", NO);
        return;
    }

    %orig;
}

%end