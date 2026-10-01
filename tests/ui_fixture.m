// Runs only in a purpose-built Simulator fixture. It is not the Douyin app.
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
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
@end
@implementation FixtureDelegate
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
    check(UIApplication.sharedApplication.connectedScenes.count==0,@"fixture matches legacy lifecycle without Scene Manifest");
    [[DGSettings shared] attachWindows];
    [[DGSettings shared] attachWindows];
    NSUInteger gestures=0;
    for (UIGestureRecognizer *gesture in self.window.gestureRecognizers) {
        if (![gesture isKindOfClass:UITapGestureRecognizer.class]) continue;
        UITapGestureRecognizer *tap=(UITapGestureRecognizer *)gesture;
        if (tap.numberOfTouchesRequired==2 && tap.numberOfTapsRequired==3) {gestures++; check(!tap.cancelsTouchesInView,@"diagnostics gesture keeps normal touches");}
    }
    check(gestures==1,@"legacy window gets exactly one diagnostics gesture");
    UILabel *home=label(parent,@"首页",100);
    check([home.text isEqualToString:@"Home"],@"text assigned before window attachment translates");
    home.text=@"设置";
    check([home.text isEqualToString:@"Settings"],@"attached label text updates translate");
    home.text=nil; check(home.text==nil || home.text.length==0,@"nil label text does not crash");
    home.text=@"首页";
    UILabel *fit=label(parent,@"更多功能",134);
    check([fit.text isEqualToString:@"More options"] && fit.adjustsFontSizeToFitWidth && fit.minimumScaleFactor>=0.65,
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
        probe.text=word;
        if (![probe.text isEqualToString:words[word]]) allWords=NO;
        CGFloat width=[probe.text sizeWithAttributes:@{NSFontAttributeName:probe.font}].width;
        if (width*probe.minimumScaleFactor>probe.bounds.size.width+1) widthOK=NO;
    }
    check(allWords,@"all configured labels pass through actual UIKit hooks in a settings context");
    check(widthOK,@"configured labels can fit a 120pt fixture control at 16pt font");
    probe.text=@"更多功能";
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
        BOOL success=YES; for (NSDictionary *item in checks) if (![item[@"passed"] boolValue]) success=NO;
        NSDictionary *report=@{@"scope":@"UIKit fixture only; original Douyin app and network were not executed",@"ios":UIDevice.currentDevice.systemVersion,@"device":UIDevice.currentDevice.model,@"checks":checks,@"passed":@(success),@"count":@(checks.count)};
        NSData *result=[NSJSONSerialization dataWithJSONObject:report options:NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys error:NULL];
        NSURL *documents=[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
        [result writeToURL:[documents URLByAppendingPathComponent:@"ui-results.json"] atomically:YES];
        [sheet dismissViewControllerAnimated:NO completion:nil];
        NSLog(@"UI fixture finished: %@",success ? @"PASS" : @"FAIL");
    });
}
@end

int main(int argc,char **argv) {
    @autoreleasepool { return UIApplicationMain(argc,argv,nil,NSStringFromClass(FixtureDelegate.class)); }
}
