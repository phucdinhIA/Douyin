#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <os/lock.h>
#include <stdatomic.h>
#include <math.h>
#import "DGPolicy.h"
#import "DGHook.h"

static atomic_bool guestEnabled, adsEnabled, englishEnabled;
static NSDictionary<NSString *, NSString *> *translations;
static NSSet<NSString *> *translatedValues;
static NSDictionary<NSString *, NSString *> *compactLabels;
static NSArray<NSDictionary *> *hookSpecs;
static NSMutableDictionary<NSString *, NSValue *> *installed;
static NSMutableSet<NSString *> *overwritten;
static NSMutableDictionary<NSString *, NSNumber *> *counters;
static os_unfair_lock counterLock = OS_UNFAIR_LOCK_INIT;
static char fontStateKey, gestureKey, labelSourceKey, labelUpdateKey, labelRichKey;

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
                             @"AuthorName", @"AuthorInfo", @"UserNick", @"Danmaku", @"Barrage", @"UserText",
                             @"RecentVisitUser", @"RevisitUser", @"UserCard"]) {
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
        if ([node isKindOfClass:UINavigationBar.class]) {
            id delegate = ((UINavigationBar *)node).delegate;
            if ([delegate isKindOfClass:UINavigationController.class]) {
                NSString *owner = NSStringFromClass(((UINavigationController *)delegate).topViewController.class);
                if (DGIsContentClass(owner) || [owner containsString:@"Profile"] || [owner containsString:@"UserDetail"])
                    return NO;
            }
        }
        if ([name hasPrefix:@"AWE"] || [name hasPrefix:@"DUI"] || [name hasPrefix:@"IES"]) {
            for (NSString *part in @[@"Navigation", @"TabBar", @"TabButton", @"Menu", @"Setting",
                                     @"Toolbar", @"ToolBar", @"Control", @"ActionButton", @"Channel",
                                     @"Login", @"SearchBar", @"SearchButton", @"PageTitle", @"HeaderTitle",
                                     @"TopTitle", @"Progress", @"Quality", @"Speed", @"SideBar", @"Sidebar",
                                     @"NetworkError", @"NetError", @"EmptyPage", @"EmptyView", @"ErrorView"]) {
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
        if (!label.adjustsFontSizeToFitWidth) label.adjustsFontSizeToFitWidth = YES;
        if (fabs(label.minimumScaleFactor - 0.65) > 1e-6) label.minimumScaleFactor = 0.65;
        if (label.baselineAdjustment != UIBaselineAdjustmentAlignCenters)
            label.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    } else if (prior) {
        label.adjustsFontSizeToFitWidth = [prior[@"adjust"] boolValue];
        label.minimumScaleFactor = [prior[@"scale"] doubleValue];
        label.baselineAdjustment = (UIBaselineAdjustment)[prior[@"baseline"] integerValue];
        objc_setAssociatedObject(label, &fontStateKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

static void DGApplyLabelLayout(UILabel *label) {
    if ([objc_getAssociatedObject(label, &labelUpdateKey) boolValue]) return;
    id source = objc_getAssociatedObject(label, &labelSourceKey);
    BOOL rich = [source isKindOfClass:NSAttributedString.class];
    NSString *full = rich ? ((NSAttributedString *)source).string : source;
    BOOL active = full && DGIsChrome(label);
    DGFitLabel(label, active);
    if (!active) return;
    NSString *display = full, *shorter = compactLabels[full];
    CGFloat width = label.bounds.size.width;
    UIFont *font = label.font;
    if (rich && [source length]) {
        id attribute = [source attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];
        if ([attribute isKindOfClass:UIFont.class]) font = attribute;
    }
    if (label.numberOfLines == 1 && width > 0 && shorter.length &&
        [full sizeWithAttributes:@{NSFontAttributeName:font}].width * 0.65 > width &&
        [shorter sizeWithAttributes:@{NSFontAttributeName:font}].width * 0.65 <= width)
        display = shorter;
    objc_setAssociatedObject(label, &labelUpdateKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    @try {
        if (rich) {
            NSAttributedString *value = [display isEqualToString:full] ? source : DGTranslateAttributed(source, @{full:display});
            if (![label.attributedText isEqualToAttributedString:value]) label.attributedText = value;
        } else if (![label.text isEqualToString:display]) {
            label.text = display;
        }
    } @finally { objc_setAssociatedObject(label, &labelUpdateKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
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
    if (objc_getAssociatedObject(label, &labelSourceKey)) { DGApplyLabelLayout(label); return; }
    // UILabel can synthesize attributedText for plain text. Track which public
    // setter the app used so that attachment does not freeze its original font.
    if ([objc_getAssociatedObject(label, &labelRichKey) boolValue] && label.attributedText.length) {
        NSAttributedString *value = DGTranslateAttributed(label.attributedText, translations);
        if (value != label.attributedText || [translatedValues containsObject:value.string]) { label.attributedText = value; }
    } else if (label.text.length) {
        NSString *value = DGTranslate(label.text, translations);
        if (![value isEqualToString:label.text] || [translatedValues containsObject:value]) { label.text = value; }
    }
    DGApplyLabelLayout(label);
}

static void DGInstallEnglish(void) {
    DGSwizzle(UILabel.class, @selector(setText:), ^id(IMP original) {
        return ^(UILabel *label, NSString *text) {
            if ([objc_getAssociatedObject(label, &labelUpdateKey) boolValue]) {
                ((void (*)(id, SEL, id))original)(label, @selector(setText:), text); return;
            }
            NSString *value = text && DGIsChrome(label) ? DGTranslate(text, translations) : text;
            objc_setAssociatedObject(label, &labelRichKey, @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            BOOL changed = text && ![value isEqualToString:text];
            BOOL chrome = value && DGIsChrome(label) && [translatedValues containsObject:value];
            objc_setAssociatedObject(label, &labelSourceKey, chrome ? value : nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(label, &labelUpdateKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            @try { ((void (*)(id, SEL, id))original)(label, @selector(setText:), value); }
            @finally { objc_setAssociatedObject(label, &labelUpdateKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
            // UIKit may call another text setter internally. Fit after its work finishes.
            DGApplyLabelLayout(label);
            if (changed) DGCount(@"Labels translated", 1);
        };
    });
    DGSwizzle(UILabel.class, @selector(setAttributedText:), ^id(IMP original) {
        return ^(UILabel *label, NSAttributedString *text) {
            if ([objc_getAssociatedObject(label, &labelUpdateKey) boolValue]) {
                ((void (*)(id, SEL, id))original)(label, @selector(setAttributedText:), text); return;
            }
            NSAttributedString *value = text && DGIsChrome(label) ? DGTranslateAttributed(text, translations) : text;
            objc_setAssociatedObject(label, &labelRichKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            BOOL chrome = value && DGIsChrome(label) && [translatedValues containsObject:value.string];
            objc_setAssociatedObject(label, &labelSourceKey, chrome ? value : nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(label, &labelUpdateKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            @try { ((void (*)(id, SEL, id))original)(label, @selector(setAttributedText:), value); }
            @finally { objc_setAssociatedObject(label, &labelUpdateKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC); }
            DGApplyLabelLayout(label);
            if (value != text) DGCount(@"Attributed labels translated", 1);
        };
    });
    DGSwizzle(UILabel.class, @selector(layoutSubviews), ^id(IMP original) {
        return ^(UILabel *label) {
            // App code may reset fitting or change font/width after setText:.
            // Reapply before layout; writes are conditional to avoid a layout loop.
            DGApplyLabelLayout(label);
            ((void (*)(id, SEL))original)(label, @selector(layoutSubviews));
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
            // Do not materialize fallback titles for disabled/highlighted states.
            // Otherwise changing the normal title later leaves a stale state override.
            NSAttributedString *rich = [button attributedTitleForState:UIControlStateNormal];
            if (rich.length) [button setAttributedTitle:rich forState:UIControlStateNormal];
            else { NSString *title = [button titleForState:UIControlStateNormal]; if (title.length) [button setTitle:title forState:UIControlStateNormal]; }
            DGTranslateLabel(button.titleLabel);
        };
    });
    // Navigation titles may be creator names. Translate their attached labels with
    // the owning controller context instead of rewriting every navigation item.
    for (Class cls in @[UITabBarItem.class]) {
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

static NSString *DGHookKey(NSDictionary *spec) {
    return [NSString stringWithFormat:@"%@|%@|%@", spec[@"class"], spec[@"selector"], spec[@"class_method"]];
}

static Method DGHookMethod(NSDictionary *spec) {
    Class cls = NSClassFromString(spec[@"class"]);
    if (!cls) return NULL;
    if ([spec[@"class_method"] boolValue]) cls = object_getClass(cls);
    return class_getInstanceMethod(cls, NSSelectorFromString(spec[@"selector"]));
}

static NSUInteger DGActiveHookCount(void) {
    NSUInteger active = 0;
    for (NSDictionary *spec in hookSpecs) {
        NSValue *implementation = installed[DGHookKey(spec)];
        Method method = DGHookMethod(spec);
        if (implementation && method && method_getImplementation(method) == (IMP)implementation.pointerValue) ++active;
    }
    return active;
}

static void DGInstallNative(void) {
    for (NSDictionary *spec in hookSpecs) {
        NSString *key = DGHookKey(spec);
        NSValue *implementation = installed[key];
        if (implementation) {
            Method method = DGHookMethod(spec);
            if ((!method || method_getImplementation(method) != (IMP)implementation.pointerValue) && ![overwritten containsObject:key]) {
                [overwritten addObject:key]; DGCount([@"Hook overwritten: " stringByAppendingString:key], 1);
            }
            // Do not automatically stack another hook over an unknown replacement.
            continue;
        }
        NSString *feature = spec[@"feature"];
        DGEnabled enabled = ^BOOL {
            if ([feature isEqualToString:@"diagnostics"]) return YES;
            return [feature isEqualToString:@"guest"] ? atomic_load(&guestEnabled) : atomic_load(&adsEnabled);
        };
        if (DGInstallHook(spec, enabled, ^(NSString *event, NSUInteger count) { DGCount(event, count); }))
            installed[key] = [NSValue valueWithPointer:(const void *)method_getImplementation(DGHookMethod(spec))];
    }
}

@interface DGSettings : NSObject <UIGestureRecognizerDelegate>
+ (instancetype)shared;
- (void)attachWindows;
- (void)attachWindow:(UIWindow *)window;
- (void)open:(UITapGestureRecognizer *)gesture;
- (void)presentSettingsInWindow:(UIWindow *)window;
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
            [self attachWindow:window];
        }
    }
    // The audited IPA has no UIApplicationSceneManifest and can use a legacy window.
    id<UIApplicationDelegate> delegate = UIApplication.sharedApplication.delegate;
    if ([delegate respondsToSelector:@selector(window)]) [self attachWindow:delegate.window];
}
- (void)attachWindow:(UIWindow *)window {
    if (!window || !window.isKeyWindow || objc_getAssociatedObject(window, &gestureKey)) return;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(open:)];
    tap.numberOfTouchesRequired = 2; tap.numberOfTapsRequired = 3;
    tap.cancelsTouchesInView = NO; tap.delegate = self;
    [window addGestureRecognizer:tap];
    objc_setAssociatedObject(window, &gestureKey, tap, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (void)open:(UITapGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateRecognized || ![gesture.view isKindOfClass:UIWindow.class]) return;
    [self presentSettingsInWindow:(UIWindow *)gesture.view];
}
- (void)presentSettingsInWindow:(UIWindow *)window {
    UIViewController *presenter = window.rootViewController;
    while (presenter.presentedViewController) presenter = presenter.presentedViewController;
    if (!presenter || [presenter isKindOfClass:UIAlertController.class]) return;
    NSString *message = [NSString stringWithFormat:@"Test build • 40.6.0 (406019)\nNative hooks: %lu/%lu active\nChanges are local. Server restrictions still apply.\nRestart after changing options.", (unsigned long)DGActiveHookCount(), (unsigned long)hookSpecs.count];
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
        NSMutableDictionary *report = [@{@"patch_version": @"0.3.0-test", @"app_version": @"40.6.0", @"build": @"406019", @"ios": UIDevice.currentDevice.systemVersion, @"native_hooks_installed": @(installed.count), @"native_hooks_expected": @(hookSpecs.count), @"translation_entries": @(translations.count), @"counters": DGCounterSnapshot()} mutableCopy];
        report[@"options"] = @{@"guest": @(atomic_load(&guestEnabled)), @"ads": @(atomic_load(&adsEnabled)), @"english": @(atomic_load(&englishEnabled))};
        report[@"native_hooks_active"] = @(DGActiveHookCount());
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
        translations = words; translatedValues = [NSSet setWithArray:translations.allValues]; hookSpecs = specs;
        compactLabels = @{@"Settings":@"Setup", @"Watch history":@"History", @"Creator tools":@"Creators",
                          @"Live cache":@"Live saves", @"My QR code":@"QR code", @"Screen time":@"Usage",
                          @"Check your connection and retry":@"Check connection"};
        counters = [NSMutableDictionary new]; installed = [NSMutableDictionary new]; overwritten = [NSMutableSet new];
        [NSUserDefaults.standardUserDefaults registerDefaults:@{@"DGGuestEnabled": @YES, @"DGAdsEnabled": @YES, @"DGEnglishEnabled": @YES}];
        atomic_init(&guestEnabled, [NSUserDefaults.standardUserDefaults boolForKey:@"DGGuestEnabled"]);
        atomic_init(&adsEnabled, [NSUserDefaults.standardUserDefaults boolForKey:@"DGAdsEnabled"]);
        atomic_init(&englishEnabled, [NSUserDefaults.standardUserDefaults boolForKey:@"DGEnglishEnabled"]);
        DGInstallNative(); DGInstallEnglish();
        NSNotificationCenter *notifications = NSNotificationCenter.defaultCenter;
        for (NSString *name in @[UIApplicationDidFinishLaunchingNotification, UIApplicationDidBecomeActiveNotification, UIWindowDidBecomeKeyNotification]) {
            [notifications addObserverForName:name object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *note) {
                DGInstallNative(); [[DGSettings shared] attachWindows];
                if ([note.object isKindOfClass:UIWindow.class]) [[DGSettings shared] attachWindow:note.object];
            }];
        }
        for (NSNumber *delay in @[@1, @3, @8]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay.doubleValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                DGInstallNative(); [[DGSettings shared] attachWindows];
            });
        }
    }
}
