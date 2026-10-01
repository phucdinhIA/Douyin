// Runs only in a purpose-built Simulator fixture. It is not the Douyin app.
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#include <math.h>
#import "DGPolicy.h"

@interface AWESettingsFixtureViewController : UIViewController
@end
@implementation AWESettingsFixtureViewController
@end
@interface AWECreatorProfileFixtureViewController : UIViewController
@end
@implementation AWECreatorProfileFixtureViewController
@end
@interface AWEFeedCaptionLabel : UILabel
@end
@implementation AWEFeedCaptionLabel
@end
@interface AWECommentFixtureView : UIView
@end
@implementation AWECommentFixtureView
@end
@interface AWELeftSideBarFixtureView : UIView
@end
@implementation AWELeftSideBarFixtureView
@end
@interface AWELeftSideBarRecentVisitUserCell : UIView
@end
@implementation AWELeftSideBarRecentVisitUserCell
@end
@interface AWENetworkErrorFixtureView : UIView
@end
@implementation AWENetworkErrorFixtureView
@end
// Fixture-only key window to exercise the fallback without changing real OS state.
@interface FixtureKeyWindow : UIWindow
@end
@implementation FixtureKeyWindow
- (BOOL)isKeyWindow { return YES; }
@end
@interface DGSettings : NSObject
+ (instancetype)shared;
- (void)attachWindows;
- (void)presentSettingsInWindow:(UIWindow *)window;
@end

static NSMutableArray<NSDictionary *> *checks;
static void check(BOOL condition, NSString *name) {
    [checks addObject:@{@"name":name,@"passed":@(condition)}];
    NSLog(@"UI fixture %@: %@",condition ? @"PASS" : @"FAIL",name);
}
static UILabel *label(UIView *parent, NSString *text, CGFloat y) {
    UILabel *value=[[UILabel alloc] initWithFrame:CGRectMake(20,y,160,28)];
    value.font=[UIFont systemFontOfSize:16]; value.text=text; [parent addSubview:value];
    return value;
}
static NSUInteger countText(UIView *view, NSString *text) {
    NSUInteger count=[view isKindOfClass:UILabel.class] && [((UILabel *)view).text isEqualToString:text];
    for (UIView *child in view.subviews) count+=countText(child,text);
    return count;
}

@interface FixtureDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) AWESettingsFixtureViewController *host;
@property (strong, nonatomic) UINavigationController *navigation;
- (void)runCases;
- (void)showVisualSamples;
@end
@implementation FixtureDelegate
- (void)saveWindowImage:(NSString *)name {
    UIGraphicsImageRenderer *renderer=[[UIGraphicsImageRenderer alloc] initWithSize:self.window.bounds.size];
    __block BOOL drawn=NO;
    UIImage *snapshot=[renderer imageWithActions:^(__unused UIGraphicsImageRendererContext *context) {
        drawn=[self.window drawViewHierarchyInRect:self.window.bounds afterScreenUpdates:YES];
    }];
    NSURL *documents=[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    BOOL saved=[UIImagePNGRepresentation(snapshot) writeToURL:[documents URLByAppendingPathComponent:name] atomically:YES];
    check(drawn && saved,[NSString stringWithFormat:@"render visual fixture %@",name]);
}
- (void)showVisualSamples {
    CGFloat width=self.window.bounds.size.width,height=self.window.bounds.size.height;
    AWENetworkErrorFixtureView *errorCanvas=[[AWENetworkErrorFixtureView alloc] initWithFrame:self.window.bounds];
    errorCanvas.backgroundColor=UIColor.systemBackgroundColor;
    UILabel *title=label(errorCanvas,@"Network error fixture",80);title.frame=CGRectMake(20,80,width-40,30);
    UIImageView *symbol=[[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"wifi.exclamationmark"]];
    symbol.frame=CGRectMake((width-80)/2,190,80,80);symbol.contentMode=UIViewContentModeScaleAspectFit;[errorCanvas addSubview:symbol];
    UILabel *errorTitle=label(errorCanvas,@"网络错误",320);errorTitle.frame=CGRectMake(20,320,width-40,34);errorTitle.textAlignment=NSTextAlignmentCenter;errorTitle.font=[UIFont systemFontOfSize:20];
    UILabel *detail=label(errorCanvas,@"请检查网络连接后重试",365);detail.frame=CGRectMake(20,365,width-40,30);detail.textAlignment=NSTextAlignmentCenter;detail.textColor=UIColor.secondaryLabelColor;
    UIButton *retry=[UIButton buttonWithType:UIButtonTypeSystem];retry.frame=CGRectMake(30,height-185,width-60,44);[retry setTitle:@"重试" forState:UIControlStateNormal];retry.layer.borderWidth=0.5;retry.layer.borderColor=UIColor.separatorColor.CGColor;[errorCanvas addSubview:retry];
    UIButton *help=[UIButton buttonWithType:UIButtonTypeSystem];help.frame=CGRectMake(30,height-125,width-60,40);[help setTitle:@"查看解决方案" forState:UIControlStateNormal];[errorCanvas addSubview:help];
    UIViewController *screen=[UIViewController new];screen.view=errorCanvas;self.window.rootViewController=screen;[self.window layoutIfNeeded];
    [self saveWindowImage:@"ui-network-error.png"];

    AWELeftSideBarFixtureView *sidebar=[[AWELeftSideBarFixtureView alloc] initWithFrame:self.window.bounds];sidebar.backgroundColor=UIColor.systemGroupedBackgroundColor;
    title=label(sidebar,@"Sidebar fixture • 0.3.0",65);title.frame=CGRectMake(20,65,width-40,28);title.font=[UIFont boldSystemFontOfSize:18];
    UILabel *settings=label(sidebar,@"设置",105);settings.frame=CGRectMake(285,105,32,22);settings.font=[UIFont systemFontOfSize:16];
    NSArray *sections=@[
        @[@"常用功能",@[@"观看历史",@"离线缓存",@"稍后再看",@"抖音创作者中心",@"直播广场",@"使用管理助手",@"我的二维码",@"未成年人保护"],@[@"clock",@"arrow.down.circle",@"play.rectangle",@"person.crop.circle",@"video",@"timer",@"qrcode",@"shield"]],
        @[@"工具服务",@[@"我的客服",@"我的预约",@"直播缓存"],@[@"headphones",@"bell",@"arrow.down.to.line"]],
        @[@"创作与经营",@[@"上热门"],@[@"chart.line.uptrend.xyaxis"]],
        @[@"生活娱乐",@[@"社区共建"],@[@"house"]]];
    CGFloat y=140,cardWidth=310;
    for (NSArray *section in sections) {
        NSArray *items=section[1],*icons=section[2];NSUInteger rows=(items.count+2)/3;
        CGFloat cardHeight=48+rows*62;
        UIView *card=[[UIView alloc] initWithFrame:CGRectMake(16,y,cardWidth,cardHeight)];card.backgroundColor=UIColor.secondarySystemGroupedBackgroundColor;card.layer.cornerRadius=14;[sidebar addSubview:card];
        UILabel *header=label(card,section[0],10);header.frame=CGRectMake(14,10,cardWidth-28,24);header.font=[UIFont boldSystemFontOfSize:17];
        for (NSUInteger i=0;i<items.count;i++) {
            CGFloat x=12+(i%3)*96,row=43+(i/3)*62;
            UIImageView *icon=[[UIImageView alloc] initWithImage:[UIImage systemImageNamed:icons[i]]];icon.frame=CGRectMake(x+33,row,26,26);icon.tintColor=UIColor.labelColor;icon.contentMode=UIViewContentModeScaleAspectFit;[card addSubview:icon];
            UILabel *item=label(card,items[i],row+30);item.frame=CGRectMake(x,row+30,92,24);item.textAlignment=NSTextAlignmentCenter;item.font=[UIFont systemFontOfSize:14];
        }
        y+=cardHeight+12;
    }
    screen=[UIViewController new];screen.view=sidebar;self.window.rootViewController=screen;[self.window layoutIfNeeded];
    [self saveWindowImage:@"ui-sidebar.png"];
}
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    (void)application; (void)options;
    checks=[NSMutableArray new];
    self.window=[[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.host=[AWESettingsFixtureViewController new];
    self.host.title=@"UIKit hook fixture";
    self.navigation=[[UINavigationController alloc] initWithRootViewController:self.host];
    self.window.rootViewController=self.navigation; self.host.view.backgroundColor=UIColor.systemBackgroundColor;
    [self.window makeKeyAndVisible];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC*2),dispatch_get_main_queue(),^{[self runCases];});
    return YES;
}
- (void)runCases {
    UIView *parent=self.host.view;
    check([NSBundle.mainBundle objectForInfoDictionaryKey:@"UIApplicationSceneManifest"]==nil,@"fixture uses delegate lifecycle without a Scene Manifest");
    [[DGSettings shared] attachWindows];
    [[DGSettings shared] attachWindows];
    NSUInteger gestures=0;
    for (UIGestureRecognizer *gesture in self.window.gestureRecognizers) {
        if (![gesture isKindOfClass:UITapGestureRecognizer.class]) continue;
        UITapGestureRecognizer *tap=(UITapGestureRecognizer *)gesture;
        if (tap.numberOfTouchesRequired==2 && tap.numberOfTapsRequired==3) {gestures++; check(!tap.cancelsTouchesInView,@"diagnostics gesture keeps normal touches");}
    }
    check(gestures==1,@"legacy window gets exactly one diagnostics gesture");
    UIWindow *realWindow=self.window;
    FixtureKeyWindow *fallback=[[FixtureKeyWindow alloc] initWithFrame:CGRectMake(0,0,200,200)];
    self.window=fallback;
    Method scenes=class_getInstanceMethod(UIApplication.class,@selector(connectedScenes));
    IMP originalScenes=method_getImplementation(scenes);
    IMP emptyScenes=imp_implementationWithBlock(^NSSet *(UIApplication *app) {(void)app; return [NSSet set];});
    method_setImplementation(scenes,emptyScenes);
    @try { [[DGSettings shared] attachWindows]; [[DGSettings shared] attachWindows]; }
    @finally { method_setImplementation(scenes,originalScenes); imp_removeBlock(emptyScenes); self.window=realWindow; }
    NSUInteger fallbackGestures=0;
    for (UIGestureRecognizer *gesture in fallback.gestureRecognizers)
        if ([gesture isKindOfClass:UITapGestureRecognizer.class] && ((UITapGestureRecognizer *)gesture).numberOfTouchesRequired==2) ++fallbackGestures;
    check(fallbackGestures==1,@"delegate-window fallback works with an empty Scene enumeration and stays idempotent");
    UILabel *home=label(parent,@"首页",100);
    check([home.text isEqualToString:@"Home"],@"text assigned before window attachment translates");
    home.text=@"设置";
    check([home.text isEqualToString:@"Settings"],@"attached label text updates translate");
    home.text=nil; check(home.text==nil || home.text.length==0,@"nil label text does not crash");
    home.text=@"首页";
    UILabel *fit=label(parent,@"更多功能",134);
    NSDictionary *fittingObservation=@{@"text":fit.text ?: @"",@"adjusts":@(fit.adjustsFontSizeToFitWidth),
        @"minimum_scale":@(fit.minimumScaleFactor),@"lines":@(fit.numberOfLines)};
    NSLog(@"Fitting observation: text=%@ adjusts=%d minimumScale=%.17g lines=%ld",fit.text,
          fit.adjustsFontSizeToFitWidth,(double)fit.minimumScaleFactor,(long)fit.numberOfLines);
    // UIKit may store this CGFloat property with float precision internally.
    check([fit.text isEqualToString:@"More options"] && fit.adjustsFontSizeToFitWidth && fabs(fit.minimumScaleFactor-0.65)<=1e-6,
          @"translated label fitting survives UIKit internal setters");
    fit.text=@"More options";
    check(fit.adjustsFontSizeToFitWidth,@"repeated translated text retains fitting");
    fit.text=@"ordinary reused content";
    check(!fit.adjustsFontSizeToFitWidth && fit.minimumScaleFactor==0,@"reused label restores original font settings");
    fit.text=@"更多功能";
    UILabel *caption=[[AWEFeedCaptionLabel alloc] initWithFrame:CGRectMake(20,168,200,28)];
    caption.text=@"我"; [parent addSubview:caption]; caption.text=@"首页";
    check([caption.text isEqualToString:@"首页"],@"caption text matching dictionary is preserved");
    AWECommentFixtureView *comment=[[AWECommentFixtureView alloc] initWithFrame:CGRectMake(0,200,300,28)];
    [parent addSubview:comment]; UILabel *commentLabel=label(comment,@"喜欢",0);
    check([commentLabel.text isEqualToString:@"喜欢"],@"comment ancestor prevents content translation");
    UIButton *button=[UIButton buttonWithType:UIButtonTypeSystem];
    button.frame=CGRectMake(20,234,150,30); [button setTitle:@"推荐" forState:UIControlStateNormal]; [parent addSubview:button];
    check([button.currentTitle isEqualToString:@"For You"],@"button title set before attachment translates");
    [button setTitle:@"首页" forState:UIControlStateNormal]; button.enabled=NO; [button layoutIfNeeded];
    check([button.currentTitle isEqualToString:@"Home"],@"disabled title fallback follows a later normal-title update");
    button.enabled=YES;
    [button setTitle:nil forState:UIControlStateNormal];
    check(button.currentTitle==nil || button.currentTitle.length==0,@"clearing button title does not preserve stale translations");
    [button setTitle:@"推荐" forState:UIControlStateNormal];
    UILabel *rich=label(parent,nil,268);
    rich.attributedText=[[NSAttributedString alloc] initWithString:@"更多功能" attributes:@{NSForegroundColorAttributeName:UIColor.systemBlueColor,NSFontAttributeName:[UIFont boldSystemFontOfSize:16]}];
    check([rich.attributedText.string isEqualToString:@"More options"] &&
          [[rich.attributedText attribute:NSForegroundColorAttributeName atIndex:0 effectiveRange:NULL] isEqual:UIColor.systemBlueColor],@"UIKit attributed translation preserves styling");
    NSMutableAttributedString *mixed=[[NSMutableAttributedString alloc] initWithString:@"更多功能"];
    [mixed addAttribute:NSForegroundColorAttributeName value:UIColor.systemRedColor range:NSMakeRange(0,1)];
    rich.attributedText=mixed;
    check([rich.attributedText.string isEqualToString:@"更多功能"],@"mixed attributed styles are not rewritten");
    rich.attributedText=nil; check(rich.attributedText==nil,@"nil attributed text does not crash");
    UITextField *input=[[UITextField alloc] initWithFrame:CGRectMake(20,302,250,30)];
    input.placeholder=@"搜索"; input.text=@"首页"; [parent addSubview:input];
    check([input.placeholder isEqualToString:@"Search"] && [input.text isEqualToString:@"首页"],@"placeholder translates while typed search content stays intact");
    UITabBarItem *tab=[[UITabBarItem alloc] initWithTitle:@"消息" image:nil tag:0];
    check([tab.title isEqualToString:@"Inbox"],@"tab title localization");
    NSData *wordsData=[NSData dataWithContentsOfURL:[NSBundle.mainBundle URLForResource:@"translations" withExtension:@"json" subdirectory:@"DouyinGuest.bundle"]];
    NSDictionary *words=[NSJSONSerialization JSONObjectWithData:wordsData options:0 error:NULL];
    BOOL allWords=YES, widthOK=YES;
    UILabel *probe=label(parent,nil,340); probe.frame=CGRectMake(20,340,120,30);
    for (NSString *word in words) {
        probe.frame=CGRectMake(20,340,320,30);
        probe.text=word;
        if (![probe.text isEqualToString:words[word]]) allWords=NO;
        probe.frame=CGRectMake(20,340,120,30);[probe setNeedsLayout];[probe layoutIfNeeded];
        CGFloat width=[probe.text sizeWithAttributes:@{NSFontAttributeName:probe.font}].width;
        if (width*probe.minimumScaleFactor>probe.bounds.size.width+1) widthOK=NO;
    }
    check(allWords,@"all configured labels pass through actual UIKit hooks in a settings context");
    check(widthOK,@"configured labels or their compact variants fit a 120pt control at 16pt font");
    probe.text=@"更多功能";
    AWELeftSideBarFixtureView *sidebar=[[AWELeftSideBarFixtureView alloc] initWithFrame:CGRectMake(0,0,300,300)];
    [parent addSubview:sidebar];
    NSDictionary *screenshotWords=@{@"工具服务":@"Tools & services",@"我的客服":@"Support",@"我的预约":@"Bookings",
        @"直播缓存":@"Live cache",@"创作与经营":@"Creator tools",@"上热门":@"Promote",@"生活娱乐":@"Lifestyle",
        @"社区共建":@"Community",@"券包":@"Coupons",@"常用功能":@"Quick tools",@"离线缓存":@"Offline videos",
        @"抖音创作者中心":@"Creator hub",@"直播广场":@"Live hub",@"使用管理助手":@"Screen time",
        @"定时关闭":@"Sleep timer",@"我的二维码":@"My QR code",@"未成年人保护":@"Teen safety"};
    UILabel *grid=label(sidebar,nil,0);grid.frame=CGRectMake(0,0,94,28);
    BOOL sidebarOK=YES,sidebarWidthOK=YES;
    for (NSString *word in screenshotWords) {
        grid.text=word;[grid layoutIfNeeded];
        if (![grid.text isEqualToString:screenshotWords[word]]) sidebarOK=NO;
        if ([grid.text sizeWithAttributes:@{NSFontAttributeName:grid.font}].width*grid.minimumScaleFactor>grid.bounds.size.width+1) sidebarWidthOK=NO;
    }
    check(sidebarOK && sidebarWidthOK,@"screenshot sidebar labels translate and fit 94pt grid controls");
    AWELeftSideBarRecentVisitUserCell *recentUser=[[AWELeftSideBarRecentVisitUserCell alloc] initWithFrame:CGRectMake(0,30,200,28)];
    [sidebar addSubview:recentUser];UILabel *nickname=label(recentUser,@"我的客服",0);
    check([nickname.text isEqualToString:@"我的客服"],@"sidebar recent-user nickname matching a menu label stays intact");
    UILabel *narrow=label(sidebar,@"设置",0);narrow.frame=CGRectMake(0,0,32,28);
    narrow.adjustsFontSizeToFitWidth=NO;narrow.minimumScaleFactor=1;[narrow setNeedsLayout];[narrow layoutIfNeeded];
    check([narrow.text isEqualToString:@"Setup"] && narrow.adjustsFontSizeToFitWidth && fabs(narrow.minimumScaleFactor-0.65)<1e-6,
          @"narrow Settings control uses a compact title and survives app fitting resets");
    narrow.frame=CGRectMake(0,0,120,28);[narrow setNeedsLayout];[narrow layoutIfNeeded];
    check([narrow.text isEqualToString:@"Settings"],@"widening a compact label restores its full English title");
    UILabel *adaptive=[[UILabel alloc] initWithFrame:CGRectMake(0,0,120,35)];
    adaptive.font=[UIFont systemFontOfSize:16];adaptive.text=@"设置";[sidebar addSubview:adaptive];
    adaptive.font=[UIFont systemFontOfSize:30];[adaptive setNeedsLayout];[adaptive layoutIfNeeded];
    check(fabs(adaptive.font.pointSize-30)<1e-6 && [adaptive.text isEqualToString:@"Settings"],
          @"plain label preserves a font change after translation and window attachment");
    narrow.text=@"ordinary text";[narrow layoutIfNeeded];
    check([narrow.text isEqualToString:@"ordinary text"] && !narrow.adjustsFontSizeToFitWidth,@"reusing a compact control clears translation state");
    narrow.attributedText=[[NSAttributedString alloc] initWithString:@"设置" attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16],NSForegroundColorAttributeName:UIColor.systemBlueColor}];
    narrow.frame=CGRectMake(0,0,32,28);[narrow setNeedsLayout];[narrow layoutIfNeeded];
    check([narrow.attributedText.string isEqualToString:@"Setup"] &&
          [[narrow.attributedText attribute:NSForegroundColorAttributeName atIndex:0 effectiveRange:NULL] isEqual:UIColor.systemBlueColor],
          @"compact attributed controls preserve styling");
    [sidebar removeFromSuperview];
    AWENetworkErrorFixtureView *errorView=[[AWENetworkErrorFixtureView alloc] initWithFrame:CGRectMake(0,0,350,100)];
    [parent addSubview:errorView];
    UILabel *errorDetail=label(errorView,@"请检查网络连接后重试",0);errorDetail.frame=CGRectMake(0,0,330,30);
    UILabel *troubleshoot=label(errorView,@"查看解决方案",34);
    check([errorDetail.text isEqualToString:@"Check your connection and retry"] && [troubleshoot.text isEqualToString:@"Troubleshoot"],
          @"network error controls translate without suppressing the error");
    [errorView removeFromSuperview];
    UITabBarItem *tips=[[UITabBarItem alloc] initWithTitle:@"经验" image:nil tag:1];
    check([tips.title isEqualToString:@"Tips"],@"experience channel label translates and remains present");
    self.window.overrideUserInterfaceStyle=UIUserInterfaceStyleDark;
    check([home.text isEqualToString:@"Home"] && home.adjustsFontSizeToFitWidth,@"dark appearance preserves text and fitting");
    self.window.overrideUserInterfaceStyle=UIUserInterfaceStyleLight;
    AWECreatorProfileFixtureViewController *profile=[AWECreatorProfileFixtureViewController new];
    profile.navigationItem.title=@"我"; profile.view.backgroundColor=UIColor.systemBackgroundColor;
    [self.navigation setViewControllers:@[profile] animated:NO]; [self.navigation.view layoutIfNeeded];
    check([profile.navigationItem.title isEqualToString:@"我"] && countText(self.navigation.navigationBar,@"Me")==0,
          @"creator profile title is not globally translated as a control label");
    [self.navigation setViewControllers:@[self.host] animated:NO]; [self.navigation.view layoutIfNeeded];
    [[DGSettings shared] presentSettingsInWindow:self.window];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC),dispatch_get_main_queue(),^{
        UIAlertController *sheet=(UIAlertController *)self.host.presentedViewController;
        if (![sheet isKindOfClass:UIAlertController.class]) sheet=(UIAlertController *)self.navigation.presentedViewController;
        check([sheet isKindOfClass:UIAlertController.class] && [sheet.title isEqualToString:@"Douyin Guest"],@"diagnostics sheet can actually be presented on legacy window");
        check(sheet.actions.count==5,@"diagnostics sheet exposes three switches, copy and close");
        [sheet dismissViewControllerAnimated:NO completion:nil];
        [self showVisualSamples];
        BOOL success=YES; for (NSDictionary *item in checks) if (![item[@"passed"] boolValue]) success=NO;
        NSDictionary *report=@{@"scope":@"UIKit fixture only; original Douyin app and network were not executed",@"ios":UIDevice.currentDevice.systemVersion,@"device":UIDevice.currentDevice.model,@"checks":checks,@"passed":@(success),@"count":@(checks.count),@"fitting_observation":fittingObservation};
        NSData *result=[NSJSONSerialization dataWithJSONObject:report options:NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys error:NULL];
        NSURL *documents=[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
        [result writeToURL:[documents URLByAppendingPathComponent:@"ui-results.json"] atomically:YES];
        NSLog(@"UI fixture finished: %@",success ? @"PASS" : @"FAIL");
    });
}
@end

int main(int argc,char **argv) {
    @autoreleasepool { return UIApplicationMain(argc,argv,nil,NSStringFromClass(FixtureDelegate.class)); }
}
