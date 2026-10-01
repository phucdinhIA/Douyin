#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <os/lock.h>
#include <stdatomic.h>
#import "DGPolicy.h"
#import "DGHook.h"

static atomic_bool guestEnabled, adsEnabled, englishEnabled;
static NSDictionary<NSString *, NSString *> *translations;
static NSArray<NSDictionary *> *hookSpecs;
static NSMutableSet<NSString *> *installed;
static NSMutableDictionary<NSString *, NSNumber *> *counters;
static os_unfair_lock counterLock = OS_UNFAIR_LOCK_INIT;
static char fontStateKey, gestureKey;

static void DGCount(NSString *event, NSUInteger amount) {
    os_unfair_lock_lock(&counterLock);
    counters[event] = @([counters[event] unsignedLongLongValue] + amount);
    os_unfair_lock_unlock(&counterLock);
}

static NSDictionary *DGCounterSnapshot(void) {
    os_unfair_lock_lock(&counterLock);
    NSDictionary *snapshot = [counters copy];
    os_unfair_lock_unlock(&counterLock);
    return snapshot;
}

static BOOL DGIsContentClass(NSString *name) {
    for (NSString *part in @[@"Caption", @"Description", @"Subtitle", @"Comment",
                             @"Nickname", @"UserName", @"AwemeDesc", @"VideoTitle",
                             @"SearchResult", @"SearchInput", @"Chat", @"MessageCell",
                             @"AuthorName", @"AuthorInfo", @"UserNick", @"Danmaku", @"Barrage", @"UserText"]) {
        if ([name rangeOfString:part options:NSCaseInsensitiveSearch].location != NSNotFound)
            return YES;
    }
    return NO;
}

static BOOL DGIsChrome(UIView *view) {
    if (!atomic_load(&englishEnabled) || !view.window) return NO;
    BOOL chrome = [view isKindOfClass:UIButton.class];
    UIResponder *node = view;
    for (NSUInteger depth = 0; node && depth < 32; ++depth, node = node.nextResponder) {
        NSString *name = NSStringFromClass(node.class);
        if (DGIsContentClass(name) || [node isKindOfClass:UITextView.class] ||
            [node isKindOfClass:UITextField.class]) return NO;
        if ([node isKindOfClass:UINavigationBar.class] || [node isKindOfClass:UITabBar.class])
            chrome = YES;
        if ([name hasPrefix:@"AWE"] || [name hasPrefix:@"DUI"] || [name hasPrefix:@"IES"]) {
            for (NSString *part in @[@"Navigation", @"TabBar", @"TabButton", @"Menu", @"Setting",
                                     @"Toolbar", @"ToolBar", @"Control", @"ActionButton", @"Channel",
                                     @"Login", @"SearchBar", @"SearchButton", @"PageTitle", @"HeaderTitle",
                                     @"TopTitle", @"Progress", @"Quality", @"Speed"]) {
                if ([name containsString:part]) { chrome = YES; break; }
            }
        }
    }
    return chrome;
}

static void DGFitLabel(UILabel *label, BOOL changed) {
    NSDictionary *prior = objc_getAssociatedObject(label, &fontStateKey);
    if (changed && label.numberOfLines == 1) {
        if (!prior) {
            prior = @{@"adjust": @(label.adjustsFontSizeToFitWidth),
                      @"scale": @(label.minimumScaleFactor),
                      @"baseline": @(label.baselineAdjustment)};
            objc_setAssociatedObject(label, &fontStateKey, prior, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        label.adjustsFontSizeToFitWidth = YES;
        label.minimumScaleFactor = MAX(0.65, [prior[@"scale"] doubleValue]);
        label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    } else if (prior) {
        label.adjustsFontSizeToFitWidth = [prior[@"adjust"] boolValue];
        label.minimumScaleFactor = [prior[@"scale"] doubleValue];
        label.baselineAdjustment = (UIBaselineAdjustment)[prior[@"baseline"] integerValue];
        objc_setAssociatedObject(label, &fontStateKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

static void DGSwizzle(Class cls, SEL selector, id (^factory)(IMP)) {
    Method method = class_getInstanceMethod(cls, selector);
    if (!method) return;
    IMP replacement = imp_implementationWithBlock(factory(method_getImplementation(method)));
    if (!class_addMethod(cls, selector, replacement, method_getTypeEncoding(method)))
        class_replaceMethod(cls, selector, replacement, method_getTypeEncoding(method));
}

static void DGTranslateLabel(UILabel *label) {
    if (!DGIsChrome(label)) return;
    if (label.attributedText.length) {
        NSAttributedString *value = DGTranslateAttributed(label.attributedText, translations);
        if (value != label.attributedText) { label.attributedText = value; DGFitLabel(label, YES); }
    } else if (label.text.length) {
        NSString *value = DGTranslate(label.text, translations);
        if (![value isEqualToString:label.text]) { label.text = value; DGFitLabel(label, YES); }
    }
}

static void DGInstallEnglish(void) {
    DGSwizzle(UILabel.class, @selector(setText:), ^id(IMP original) {
        return ^(UILabel *label, NSString *text) {
            NSString *value = text && DGIsChrome(label) ? DGTranslate(text, translations) : text;
            BOOL changed = text && ![value isEqualToString:text];
            DGFitLabel(label, changed);
            ((void (*)(id, SEL, id))original)(label, @selector(setText:), value);
            if (changed) DGCount(@"Labels translated", 1);
        };
    });
    DGSwizzle(UILabel.class, @selector(setAttributedText:), ^id(IMP original) {
        return ^(UILabel *label, NSAttributedString *text) {
            NSAttributedString *value = text && DGIsChrome(label) ? DGTranslateAttributed(text, translations) : text;
            DGFitLabel(label, value != text);
            ((void (*)(id, SEL, id))original)(label, @selector(setAttributedText:), value);
            if (value != text) DGCount(@"Attributed labels translated", 1);
        };
    });
    DGSwizzle(UILabel.class, @selector(didMoveToWindow), ^id(IMP original) {
        return ^(UILabel *label) {
            ((void (*)(id, SEL))original)(label, @selector(didMoveToWindow));
            DGTranslateLabel(label);
        };
    });
    DGSwizzle(UIButton.class, @selector(setTitle:forState:), ^id(IMP original) {
        return ^(UIButton *button, NSString *title, UIControlState state) {
            NSString *value = title && DGIsChrome(button) ? DGTranslate(title, translations) : title;
            ((void (*)(id, SEL, id, UIControlState))original)(button, @selector(setTitle:forState:), value, state);
            if (title && ![value isEqualToString:title]) DGCount(@"Button titles translated", 1);
        };
    });
    DGSwizzle(UIButton.class, @selector(setAttributedTitle:forState:), ^id(IMP original) {
        return ^(UIButton *button, NSAttributedString *title, UIControlState state) {
            NSAttributedString *value = title && DGIsChrome(button) ? DGTranslateAttributed(title, translations) : title;
            ((void (*)(id, SEL, id, UIControlState))original)(button, @selector(setAttributedTitle:forState:), value, state);
        };
    });
    DGSwizzle(UIButton.class, @selector(didMoveToWindow), ^id(IMP original) {
        return ^(UIButton *button) {
            ((void (*)(id, SEL))original)(button, @selector(didMoveToWindow));
            if (!DGIsChrome(button)) return;
            for (NSNumber *state in @[@(UIControlStateNormal), @(UIControlStateHighlighted), @(UIControlStateSelected), @(UIControlStateDisabled)]) {
                UIControlState value = state.unsignedIntegerValue;
                NSAttributedString *rich = [button attributedTitleForState:value];
                if (rich.length) [button setAttributedTitle:rich forState:value];
                else { NSString *title = [button titleForState:value]; if (title.length) [button setTitle:title forState:value]; }
            }
            DGTranslateLabel(button.titleLabel);
        };
    });
    for (Class cls in @[UINavigationItem.class, UITabBarItem.class]) {
        DGSwizzle(cls, @selector(setTitle:), ^id(IMP original) {
            return ^(id item, NSString *title) {
                NSString *value = title && atomic_load(&englishEnabled) ? DGTranslate(title, translations) : title;
                ((void (*)(id, SEL, id))original)(item, @selector(setTitle:), value);
            };
        });
    }
    DGSwizzle(UITextField.class, @selector(setPlaceholder:), ^id(IMP original) {
        return ^(UITextField *field, NSString *text) {
            NSString *value = text && atomic_load(&englishEnabled) ? DGTranslate(text, translations) : text;
            ((void (*)(id, SEL, id))original)(field, @selector(setPlaceholder:), value);
        };
    });
    // Bundle lookups cover localized chrome; raw model data never passes through here.
    DGSwizzle(NSBundle.class, @selector(localizedStringForKey:value:table:), ^id(IMP original) {
        return ^NSString *(NSBundle *bundle, NSString *key, NSString *value, NSString *table) {
            NSString *text = ((id (*)(id, SEL, id, id, id))original)(bundle, @selector(localizedStringForKey:value:table:), key, value, table);
            NSString *appRoot = NSBundle.mainBundle.bundlePath;
            if (atomic_load(&englishEnabled) && [bundle.bundlePath hasPrefix:[appRoot stringByAppendingString:@"/"]])
                return DGTranslate(text, translations);
            if (bundle == NSBundle.mainBundle && atomic_load(&englishEnabled)) return DGTranslate(text, translations);
            return text;
        };
    });
}

static void DGInstallNative(void) {
    for (NSDictionary *spec in hookSpecs) {
        NSString *key = [NSString stringWithFormat:@"%@|%@|%@", spec[@"class"], spec[@"selector"], spec[@"class_method"]];
        if ([installed containsObject:key]) continue;
        NSString *feature = spec[@"feature"];
        DGEnabled enabled = ^BOOL { return [feature isEqualToString:@"guest"] ? atomic_load(&guestEnabled) : atomic_load(&adsEnabled); };
        if (DGInstallHook(spec, enabled, ^(NSString *event, NSUInteger count) { DGCount(event, count); }))
            [installed addObject:key];
    }
}

@interface DGSettings : NSObject <UIGestureRecognizerDelegate>
+ (instancetype)shared;
- (void)attachWindows;
- (void)open:(UITapGestureRecognizer *)gesture;
@end

@implementation DGSettings
+ (instancetype)shared { static DGSettings *value; static dispatch_once_t once; dispatch_once(&once, ^{ value = [DGSettings new]; }); return value; }
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)a shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)b {
    (void)a; (void)b; return YES;
}
- (void)attachWindows {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) continue;
        for (UIWindow *window in ((UIWindowScene *)scene).windows) {
            if (!window.isKeyWindow || objc_getAssociatedObject(window, &gestureKey)) continue;
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(open:)];
            tap.numberOfTouchesRequired = 2; tap.numberOfTapsRequired = 3;
            tap.cancelsTouchesInView = NO; tap.delegate = self;
            [window addGestureRecognizer:tap];
            objc_setAssociatedObject(window, &gestureKey, tap, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
}
- (void)open:(UITapGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateRecognized) return;
    UIViewController *presenter = ((UIWindow *)gesture.view).rootViewController;
    while (presenter.presentedViewController) presenter = presenter.presentedViewController;
    if (!presenter || [presenter isKindOfClass:UIAlertController.class]) return;
    NSString *message = [NSString stringWithFormat:@"Test build • 40.6.0 (406019)\nNative hooks: %lu/%lu\nChanges are local. Server restrictions still apply.\nRestart after changing options.", (unsigned long)installed.count, (unsigned long)hookSpecs.count];
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Douyin Guest" message:message preferredStyle:UIAlertControllerStyleAlert];
    NSArray *names = @[@"Hide login reminders", @"Filter feed / startup ads", @"English controls"];
    NSArray *keys = @[@"DGGuestEnabled", @"DGAdsEnabled", @"DGEnglishEnabled"];
    BOOL flags[] = {atomic_load(&guestEnabled), atomic_load(&adsEnabled), atomic_load(&englishEnabled)};
    for (NSUInteger i = 0; i < names.count; ++i) {
        BOOL next = !flags[i];
        NSString *title = [NSString stringWithFormat:@"%@: %@", names[i], flags[i] ? @"ON" : @"OFF"];
        [sheet addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [NSUserDefaults.standardUserDefaults setBool:next forKey:keys[i]];
            if (i == 0) atomic_store(&guestEnabled, next);
            if (i == 1) atomic_store(&adsEnabled, next);
            if (i == 2) atomic_store(&englishEnabled, next);
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"Copy diagnostics" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSMutableDictionary *report = [@{@"patch_version": @"0.1.0-test", @"app_version": @"40.6.0", @"build": @"406019", @"ios": UIDevice.currentDevice.systemVersion, @"native_hooks_installed": @(installed.count), @"native_hooks_expected": @(hookSpecs.count), @"translation_entries": @(translations.count), @"counters": DGCounterSnapshot()} mutableCopy];
        report[@"options"] = @{@"guest": @(atomic_load(&guestEnabled)), @"ads": @(atomic_load(&adsEnabled)), @"english": @(atomic_load(&englishEnabled))};
        NSData *data = [NSJSONSerialization dataWithJSONObject:report options:NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys error:NULL];
        if (data) UIPasteboard.generalPasteboard.string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:nil]];
    [presenter presentViewController:sheet animated:YES completion:nil];
}
@end

static id DGReadJSON(NSString *file) {
    NSURL *url = [NSBundle.mainBundle URLForResource:file withExtension:@"json" subdirectory:@"DouyinGuest.bundle"];
    NSData *data = url ? [NSData dataWithContentsOfURL:url] : nil;
    return data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL] : nil;
}

__attribute__((constructor)) static void DGStart(void) {
    @autoreleasepool {
        NSBundle *bundle = NSBundle.mainBundle;
        BOOL supportedID = [bundle.bundleIdentifier isEqualToString:@"com.ss.iphone.ugc.Aweme"] ||
                           [bundle.bundleIdentifier hasPrefix:@"com.ss.iphone.ugc.Aweme."];
        if (!supportedID ||
            ![[bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] isEqualToString:@"40.6.0"] ||
            ![[bundle objectForInfoDictionaryKey:@"CFBundleVersion"] isEqualToString:@"406019"]) return;
        id words = DGReadJSON(@"translations"), specs = DGReadJSON(@"hooks");
        if (![words isKindOfClass:NSDictionary.class] || ![specs isKindOfClass:NSArray.class]) return;
        translations = words; hookSpecs = specs;
        counters = [NSMutableDictionary new]; installed = [NSMutableSet new];
        [NSUserDefaults.standardUserDefaults registerDefaults:@{@"DGGuestEnabled": @YES, @"DGAdsEnabled": @YES, @"DGEnglishEnabled": @YES}];
        atomic_init(&guestEnabled, [NSUserDefaults.standardUserDefaults boolForKey:@"DGGuestEnabled"]);
        atomic_init(&adsEnabled, [NSUserDefaults.standardUserDefaults boolForKey:@"DGAdsEnabled"]);
        atomic_init(&englishEnabled, [NSUserDefaults.standardUserDefaults boolForKey:@"DGEnglishEnabled"]);
        DGInstallNative(); DGInstallEnglish();
        NSNotificationCenter *notifications = NSNotificationCenter.defaultCenter;
        for (NSString *name in @[UIApplicationDidFinishLaunchingNotification, UIApplicationDidBecomeActiveNotification, UIWindowDidBecomeKeyNotification]) {
            [notifications addObserverForName:name object:nil queue:NSOperationQueue.mainQueue usingBlock:^(__unused NSNotification *note) {
                DGInstallNative(); [[DGSettings shared] attachWindows];
            }];
        }
        for (NSNumber *delay in @[@1, @3, @8]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay.doubleValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                DGInstallNative(); [[DGSettings shared] attachWindows];
            });
        }
    }
}
