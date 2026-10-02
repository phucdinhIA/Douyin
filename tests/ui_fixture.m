// Runs only in a purpose-built Simulator fixture. It is not the Douyin app.
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#include <math.h>
#import "DGPolicy.h"
#import "DGHook.h"

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
@interface AWESearchResultFixtureView : UIView
@end
@implementation AWESearchResultFixtureView
@end
@interface AWESearchFilterCollectionViewCell : UIView
@end
@implementation AWESearchFilterCollectionViewCell
@end
@interface AWEProfileTabFixtureView : UIView
@end
@implementation AWEProfileTabFixtureView
@end
@interface AWECommentHeaderFixtureView : UIView
@end
@implementation AWECommentHeaderFixtureView
@end
@interface AWECommentVCHeaderBarView : UIView
@property (copy) NSAttributedString *attrTips;
@end
@implementation AWECommentVCHeaderBarView
@end
@interface AWECommentBottomTipsView : UIView
@end
@implementation AWECommentBottomTipsView
@end
@interface AWECommentReplyButton : UIButton
@end
@implementation AWECommentReplyButton
@end
@interface CommentCellFixtureView : UIView
@end
@implementation CommentCellFixtureView
@end
@interface AWECommentSurveyCell : UIView
@end
@implementation AWECommentSurveyCell
@end
@interface AWEUIKitViewControllerEmptyPageConfig : NSObject
@property (copy) NSString *titleText;
@property (copy) NSString *informativeText;
@property (copy) NSString *primaryButtonTitle;
@end
@implementation AWEUIKitViewControllerEmptyPageConfig
@end
@interface DUXToastViewConfig : NSObject
@property (copy) NSString *text;
@end
@implementation DUXToastViewConfig
@end
@interface AWECommentSurveyConfigModel : NSObject
@property (strong) id surveyDetail;
@end
@implementation AWECommentSurveyConfigModel
@end
@interface AWECommentEvaluationConfig : NSObject
@property (strong) id receivedConfig;
- (void)configWithDict:(id)config;
@end
@implementation AWECommentEvaluationConfig
- (void)configWithDict:(id)config { self.receivedConfig=config; }
@end
@interface _TtC18AWESearchSwiftImpl17SearchSettingView : UIView
@end
@implementation _TtC18AWESearchSwiftImpl17SearchSettingView
@end
@interface YYLabel : UIView
@property (copy, nonatomic) NSString *text;
@property (copy, nonatomic) NSAttributedString *attributedText;
@property (strong, nonatomic) UIFont *font;
@property (nonatomic) NSUInteger numberOfLines;
@end
@implementation YYLabel
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) { _font = [UIFont systemFontOfSize:16]; _numberOfLines = 1; self.opaque=NO; self.backgroundColor=UIColor.clearColor; }
    return self;
}
- (void)setText:(NSString *)text { _text = [text copy]; _attributedText = nil; }
- (void)setAttributedText:(NSAttributedString *)text { _attributedText = [text copy]; _text = text.string; }
- (void)drawRect:(CGRect)rect {
    if (self.attributedText) [self.attributedText drawInRect:rect];
    else [self.text drawInRect:rect withAttributes:@{NSFontAttributeName:self.font,NSForegroundColorAttributeName:UIColor.labelColor}];
}
@end
@interface FixtureGuestAdapter : NSObject
+ (BOOL)enableGuestSearch;
+ (BOOL)hasRemainingGuestSearchCount;
@end
@implementation FixtureGuestAdapter
+ (BOOL)enableGuestSearch { return NO; }
+ (BOOL)hasRemainingGuestSearchCount { return NO; }
@end
@interface AWESearchBaseUtility : NSObject
+ (Class)aAWESearchModuleServiceDOUYINSSAdaperClass;
@end
@implementation AWESearchBaseUtility
+ (Class)aAWESearchModuleServiceDOUYINSSAdaperClass { return FixtureGuestAdapter.class; }
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
    title=label(sidebar,@"Sidebar fixture • 0.4.0",65);title.frame=CGRectMake(20,65,width-40,28);title.font=[UIFont boldSystemFontOfSize:18];
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

    AWESearchResultFixtureView *searchCanvas=[[AWESearchResultFixtureView alloc] initWithFrame:self.window.bounds];
    searchCanvas.backgroundColor=UIColor.systemBackgroundColor;
    AWESearchFilterCollectionViewCell *filters=[[AWESearchFilterCollectionViewCell alloc] initWithFrame:self.window.bounds];[searchCanvas addSubview:filters];
    title=label(filters,@"Search controls fixture • 0.4.0",80);title.frame=CGRectMake(20,80,width-40,30);
    NSArray *searchWords=@[@"综合排序",@"视频",@"用户",@"直播",@"一周内",@"最多点赞",@"切换为单列模式",@"切换为双列模式",@"相关搜索",@"大家都在搜",@"没有搜索到相关内容",@"试试换个搜索词"];
    CGFloat rowY=140;
    for (NSUInteger i=0;i<searchWords.count;i++) {
        UILabel *item=label(filters,searchWords[i],rowY);item.frame=CGRectMake(20+(i%2)*180,rowY,160,34);
        item.layer.borderWidth=0.5;item.layer.borderColor=UIColor.separatorColor.CGColor;
        if (i%2) rowY+=50;
    }
    YYLabel *custom=[[YYLabel alloc] initWithFrame:CGRectMake(20,500,120,30)];custom.text=@"语音搜索重试按钮";[filters addSubview:custom];
    UILabel *query=label(searchCanvas,@"首页",555);query.frame=CGRectMake(20,555,width-40,30);
    UILabel *note=label(filters,@"The Chinese label above is protected result content.",595);note.frame=CGRectMake(20,595,width-40,50);note.numberOfLines=2;
    screen=[UIViewController new];screen.view=searchCanvas;self.window.rootViewController=screen;[self.window layoutIfNeeded];
    [self saveWindowImage:@"ui-search.png"];

    AWESettingsFixtureViewController *settingsScreen=[AWESettingsFixtureViewController new];settingsScreen.view.backgroundColor=UIColor.systemBackgroundColor;
    NSArray *settingsWords=@[@"设置",@"账号管理",@"个性化内容推荐",@"通知消息管理",@"私信和通话通知",@"字体大小",@"缓存设置",@"后台播放设置",@"小窗播放设置",@"字幕设置",@"黑名单管理",@"隐私政策及简明版"];
    title=label(settingsScreen.view,@"Settings fixture • 0.4.0",80);title.frame=CGRectMake(20,80,width-40,30);
    for (NSUInteger i=0;i<settingsWords.count;i++) { UILabel *item=label(settingsScreen.view,settingsWords[i],135+i*43);item.frame=CGRectMake(20,135+i*43,180,36); }
    screen=settingsScreen;self.window.rootViewController=screen;[self.window layoutIfNeeded];
    [self saveWindowImage:@"ui-settings.png"];

    AWECommentFixtureView *commentCanvas=[[AWECommentFixtureView alloc] initWithFrame:self.window.bounds];commentCanvas.backgroundColor=UIColor.systemBackgroundColor;
    AWECommentVCHeaderBarView *commentHeader=[[AWECommentVCHeaderBarView alloc] initWithFrame:CGRectMake(16,70,width-32,150)];[commentCanvas addSubview:commentHeader];
    title=label(commentHeader,@"Comment controls fixture • 0.5.0",0);title.frame=CGRectMake(4,0,width-40,28);title.font=[UIFont boldSystemFontOfSize:17];
    UILabel *headerCount=label(commentHeader,@"评论 1081",45);headerCount.frame=CGRectMake(4,45,170,28);
    UILabel *collection=label(commentHeader,@"观看完整合集：示例合集",82);collection.frame=CGRectMake(4,82,width-40,30);
    UILabel *summary=label(commentHeader,@"AI 解析",118);summary.frame=CGRectMake(4,118,130,28);
    AWECommentSurveyCell *survey=[[AWECommentSurveyCell alloc] initWithFrame:CGRectMake(16,245,width-32,155)];[commentCanvas addSubview:survey];
    survey.backgroundColor=UIColor.secondarySystemGroupedBackgroundColor;survey.layer.cornerRadius=12;
    UILabel *question=label(survey,@"你对该视频下的评论氛围是否满意?",12);question.frame=CGRectMake(10,12,width-52,50);question.numberOfLines=2;
    NSArray *ratings=@[@"非常不满意",@"不满意",@"一般",@"满意",@"非常满意"];
    CGFloat optionWidth=(width-52)/5;
    for (NSUInteger i=0;i<ratings.count;i++) {
        UILabel *rating=label(survey,ratings[i],76);rating.frame=CGRectMake(10+i*optionWidth,76,optionWidth-4,54);
        rating.font=[UIFont systemFontOfSize:12];rating.numberOfLines=2;rating.textAlignment=NSTextAlignmentCenter;
    }
    CommentCellFixtureView *body=[[CommentCellFixtureView alloc] initWithFrame:CGRectMake(16,425,width-32,160)];[commentCanvas addSubview:body];
    UILabel *content=label(body,@"示例评论：一般，满意，回复。",0);content.frame=CGRectMake(4,0,width-40,45);content.numberOfLines=2;
    AWECommentReplyButton *reply=[[AWECommentReplyButton alloc] initWithFrame:CGRectMake(4,55,150,30)];[body addSubview:reply];[reply setTitle:@"展开1条回复" forState:UIControlStateNormal];[reply setTitleColor:UIColor.secondaryLabelColor forState:UIControlStateNormal];
    UILabel *explanation=label(body,@"Chinese above is preserved sample comment content.",105);explanation.frame=CGRectMake(4,105,width-40,45);explanation.numberOfLines=2;explanation.font=[UIFont systemFontOfSize:13];
    AWECommentBottomTipsView *bottom=[[AWECommentBottomTipsView alloc] initWithFrame:CGRectMake(16,625,width-32,60)];[commentCanvas addSubview:bottom];
    UILabel *login=label(bottom,@"登录看更多精彩评论",0);login.frame=CGRectMake(4,0,width-40,40);login.textColor=UIColor.systemRedColor;login.textAlignment=NSTextAlignmentCenter;
    screen=[UIViewController new];screen.view=commentCanvas;self.window.rootViewController=screen;[self.window layoutIfNeeded];
    [self saveWindowImage:@"ui-comments.png"];

    AWENetworkErrorFixtureView *featured=[[AWENetworkErrorFixtureView alloc] initWithFrame:self.window.bounds];featured.backgroundColor=UIColor.systemBackgroundColor;
    title=label(featured,@"Featured narrow-label fixture • 0.5.0",80);title.frame=CGRectMake(20,80,width-40,30);title.font=[UIFont boldSystemFontOfSize:17];
    UILabel *featuredTitle=label(featured,@"网络错误",320);featuredTitle.frame=CGRectMake((width-60)/2,320,60,30);featuredTitle.textAlignment=NSTextAlignmentCenter;
    UILabel *errorDetail=label(featured,@"请检查网络连接后重试",365);errorDetail.frame=CGRectMake((width-120)/2,365,120,30);errorDetail.textAlignment=NSTextAlignmentCenter;
    UIButton *retryButton=[UIButton buttonWithType:UIButtonTypeSystem];retryButton.frame=CGRectMake((width-100)/2,415,100,42);[retryButton setTitle:@"重试" forState:UIControlStateNormal];[featured addSubview:retryButton];
    UILabel *notice=label(featured,@"操作失败，请稍后重试",485);notice.frame=CGRectMake(20,485,width-40,40);notice.textAlignment=NSTextAlignmentCenter;
    screen=[UIViewController new];screen.view=featured;self.window.rootViewController=screen;[self.window layoutIfNeeded];
    [self saveWindowImage:@"ui-featured-narrow.png"];
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
    NSMutableArray *overflowLabels=[NSMutableArray new];
    UILabel *probe=label(parent,nil,340); probe.frame=CGRectMake(20,340,120,30);
    for (NSString *word in words) {
        probe.frame=CGRectMake(20,340,320,30);
        probe.text=word;
        if (![probe.text isEqualToString:words[word]]) allWords=NO;
        probe.frame=CGRectMake(20,340,120,30);[probe setNeedsLayout];[probe layoutIfNeeded];
        CGFloat width=[probe.text sizeWithAttributes:@{NSFontAttributeName:probe.font}].width;
        if (width*probe.minimumScaleFactor>probe.bounds.size.width+1) { widthOK=NO; [overflowLabels addObject:@{@"source":word,@"display":probe.text,@"width":@(width)}]; }
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
    UILabel *padded=label(parent,@"  收起 \t",0);[padded layoutIfNeeded];
    check([padded.text isEqualToString:@"  Collapse \t"] && padded.adjustsFontSizeToFitWidth,@"padded control title translates and receives fitting after attachment");
    AWESearchResultFixtureView *results=[[AWESearchResultFixtureView alloc] initWithFrame:CGRectMake(0,0,350,200)];[parent addSubview:results];
    AWESearchFilterCollectionViewCell *filter=[[AWESearchFilterCollectionViewCell alloc] initWithFrame:CGRectMake(0,0,350,100)];[results addSubview:filter];
    UILabel *filterTitle=label(filter,@"综合排序",0);UILabel *resultContent=label(results,@"综合排序",100);
    check([filterTitle.text isEqualToString:@"Relevance"] && [resultContent.text isEqualToString:@"综合排序"],@"search filters translate within a protected result controller while result content remains original");
    AWEProfileTabFixtureView *profileTabs=[[AWEProfileTabFixtureView alloc] initWithFrame:CGRectMake(0,0,300,40)];[parent addSubview:profileTabs];
    check([label(profileTabs,@"作品",0).text isEqualToString:@"Posts"],@"profile control tabs translate without rewriting profile titles");
    AWECommentFixtureView *commentContainer=[[AWECommentFixtureView alloc] initWithFrame:CGRectMake(0,0,300,80)];[parent addSubview:commentContainer];
    AWECommentHeaderFixtureView *header=[[AWECommentHeaderFixtureView alloc] initWithFrame:CGRectMake(0,0,300,40)];[commentContainer addSubview:header];
    check([label(header,@"评论",0).text isEqualToString:@"Comments"] && [label(commentContainer,@"评论",40).text isEqualToString:@"评论"],@"comment header translates while the comment body stays original");
    _TtC18AWESearchSwiftImpl17SearchSettingView *swift=[[ _TtC18AWESearchSwiftImpl17SearchSettingView alloc] initWithFrame:CGRectMake(0,0,300,40)];[parent addSubview:swift];
    check([label(swift,@"默认排序",0).text isEqualToString:@"Default order"],@"Swift app control class names are recognized");
    YYLabel *custom=[[YYLabel alloc] initWithFrame:CGRectMake(0,0,32,30)];custom.text=@"设置";[filter addSubview:custom];[custom layoutIfNeeded];
    check([custom.text isEqualToString:@"Setup"] && custom.font.pointSize>=16*0.65-0.01 && custom.font.pointSize<16,@"custom YYLabel translates before attachment and fits narrow controls above the minimum scale");
    custom.frame=CGRectMake(0,0,160,30);[custom setNeedsLayout];[custom layoutIfNeeded];
    check([custom.text isEqualToString:@"Settings"] && fabs(custom.font.pointSize-16)<1e-6,@"custom label widens back to full title and original font");
    custom.frame=CGRectMake(0,0,32,60);custom.numberOfLines=2;[custom setNeedsLayout];[custom layoutIfNeeded];
    check([custom.text isEqualToString:@"Settings"] && fabs(custom.font.pointSize-16)<1e-6,@"custom multiline label restores full text and leaves wrapping to its own renderer");
    custom.frame=CGRectMake(0,0,160,30);custom.numberOfLines=1;
    custom.font=[UIFont systemFontOfSize:24];[custom setNeedsLayout];[custom layoutIfNeeded];
    check(fabs(custom.font.pointSize-24)<1e-6,@"custom label preserves a later app font change");
    custom.frame=CGRectMake(0,0,32,30);[custom setNeedsLayout];[custom layoutIfNeeded];custom.text=@"ordinary text";
    check([custom.text isEqualToString:@"ordinary text"] && fabs(custom.font.pointSize-24)<1e-6,@"custom label reuse restores the last app font");
    custom.font=[UIFont systemFontOfSize:16];
    custom.attributedText=[[NSAttributedString alloc] initWithString:@"设置" attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16],NSForegroundColorAttributeName:UIColor.systemBlueColor}];
    check([custom.attributedText.string isEqualToString:@"Setup"] && [[custom.attributedText attribute:NSForegroundColorAttributeName atIndex:0 effectiveRange:NULL] isEqual:UIColor.systemBlueColor],@"custom attributed control preserves color during fitting");
    NSMutableAttributedString *customMixed=[[NSMutableAttributedString alloc] initWithString:@"更多功能" attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16]}];
    [customMixed addAttribute:NSForegroundColorAttributeName value:UIColor.redColor range:NSMakeRange(0,1)];custom.attributedText=customMixed;
    check([custom.attributedText isEqualToAttributedString:customMixed],@"custom mixed attributed styles are left intact");
    YYLabel *customContent=[[YYLabel alloc] initWithFrame:CGRectMake(0,0,120,30)];customContent.text=@"首页";[results addSubview:customContent];
    check([customContent.text isEqualToString:@"首页"] && fabs(customContent.font.pointSize-16)<1e-6,@"custom result content is not translated or shrunk");
    custom.text=nil;custom.attributedText=nil;
    check(custom.text==nil && custom.attributedText==nil,@"custom nil/reused labels clear without a crash");
    check([AWESearchBaseUtility aAWESearchModuleServiceDOUYINSSAdaperClass]==FixtureGuestAdapter.class && ![FixtureGuestAdapter enableGuestSearch] && ![FixtureGuestAdapter hasRemainingGuestSearchCount],@"search gateway observation preserves native guest policy and quota in fixture");
    check([DGSearchAdapterSnapshot()[@"installed"] unsignedIntegerValue]==0 && [DGSearchAdapterSnapshot()[@"active"] unsignedIntegerValue]==0 && [DGSearchAdapterSnapshot()[@"adapter_classes"] unsignedIntegerValue]==1,@"search diagnostics distinguish an observed adapter from installed modifications");
    AWEUIKitViewControllerEmptyPageConfig *emptyConfig=[AWEUIKitViewControllerEmptyPageConfig new];
    emptyConfig.titleText=@"网络错误";emptyConfig.informativeText=@"请检查网络连接后重试";emptyConfig.primaryButtonTitle=@"重试";
    check([emptyConfig.titleText isEqualToString:@"Network error"] && [emptyConfig.informativeText isEqualToString:@"Check your connection and retry"] && [emptyConfig.primaryButtonTitle isEqualToString:@"Retry"],@"native empty config fields translate before any view/window or text measurement exists");
    CGFloat configWidth=[emptyConfig.titleText sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16]}].width;
    check(configWidth>[@"网络错误" sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16]}].width,@"renderer measuring its config receives the English width");
    AWENetworkErrorFixtureView *narrowError=[[AWENetworkErrorFixtureView alloc] initWithFrame:CGRectMake(0,0,300,100)];[parent addSubview:narrowError];
    UILabel *narrowTitle=label(narrowError,@"网络错误",0);narrowTitle.frame=CGRectMake(0,0,60,28);
    UILabel *narrowDetail=label(narrowError,@"请检查网络连接后重试",30);narrowDetail.frame=CGRectMake(0,30,120,28);
    narrowTitle.adjustsFontSizeToFitWidth=NO;narrowDetail.adjustsFontSizeToFitWidth=NO;
    [narrowTitle setNeedsLayout];[narrowDetail setNeedsLayout];[narrowError layoutIfNeeded];
    check([narrowTitle.text isEqualToString:@"Load error"] && [narrowDetail.text isEqualToString:@"Check connection"] &&
        [narrowTitle.text sizeWithAttributes:@{NSFontAttributeName:narrowTitle.font}].width*narrowTitle.minimumScaleFactor<=60 &&
        [narrowDetail.text sizeWithAttributes:@{NSFontAttributeName:narrowDetail.font}].width*narrowDetail.minimumScaleFactor<=120,
        @"Featured-sized narrow error labels remain complete after app resets fitting");
    DUXToastViewConfig *toast=[DUXToastViewConfig new];toast.text=@"操作失败，请稍后重试";
    check([toast.text isEqualToString:@"Action failed. Try again later"],@"toast config localization happens before toast measures its text");
    AWECommentVCHeaderBarView *realHeader=[[AWECommentVCHeaderBarView alloc] initWithFrame:CGRectMake(0,0,300,100)];[commentContainer addSubview:realHeader];
    UILabel *countLabel=label(realHeader,@"评论 1081",0);countLabel.frame=CGRectMake(0,0,150,28);[countLabel layoutIfNeeded];
    check([countLabel.text isEqualToString:@"Comments 1081"] && countLabel.adjustsFontSizeToFitWidth,@"actual native comment header name supports dynamic count and fitting");
    NSMutableAttributedString *collection=[[NSMutableAttributedString alloc] initWithString:@"观看完整合集：示例合集" attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16]}];
    [collection addAttributes:@{NSForegroundColorAttributeName:UIColor.systemBlueColor,NSLinkAttributeName:@"https://example.invalid/fixture"} range:NSMakeRange(7,4)];
    realHeader.attrTips=collection;
    NSAttributedString *translatedTips=realHeader.attrTips;
    UILabel *collectionLabel=label(realHeader,nil,30);collectionLabel.frame=CGRectMake(0,30,300,30);collectionLabel.attributedText=translatedTips;
    check([collectionLabel.attributedText.string isEqualToString:@"Collection: 示例合集"] &&
        [[collectionLabel.attributedText attribute:NSLinkAttributeName atIndex:12 effectiveRange:NULL] isEqual:@"https://example.invalid/fixture"],
        @"mixed collection link style and original title survive native header and UILabel localization");
    YYLabel *customCollection=[[YYLabel alloc] initWithFrame:CGRectMake(0,60,160,30)];[realHeader addSubview:customCollection];customCollection.attributedText=collection;[customCollection layoutIfNeeded];
    check([customCollection.attributedText.string isEqualToString:@"Collection: 示例合集"] &&
        [[customCollection.attributedText attribute:NSLinkAttributeName atIndex:12 effectiveRange:NULL] isEqual:@"https://example.invalid/fixture"],
        @"YYLabel fitting preserves mixed collection link spans instead of flattening them");
    CommentCellFixtureView *contentCell=[[CommentCellFixtureView alloc] initWithFrame:CGRectMake(0,100,300,60)];[commentContainer addSubview:contentCell];
    UILabel *originalBody=label(contentCell,@"一般",0);UILabel *originalReply=label(contentCell,@"展开1条回复",28);
    check([originalBody.text isEqualToString:@"一般"] && [originalReply.text isEqualToString:@"展开1条回复"],@"comment content resembling a rating or reply control remains unchanged outside an explicit control island");
    AWECommentReplyButton *reply=[[AWECommentReplyButton alloc] initWithFrame:CGRectMake(0,0,150,30)];[contentCell addSubview:reply];[reply setTitle:@"展开1条回复" forState:UIControlStateNormal];
    check([reply.currentTitle isEqualToString:@"View 1 reply"],@"explicit reply button translates inside a protected comment cell");
    AWECommentBottomTipsView *bottom=[[AWECommentBottomTipsView alloc] initWithFrame:CGRectMake(0,160,300,35)];[commentContainer addSubview:bottom];
    check([label(bottom,@"登录看更多精彩评论",0).text isEqualToString:@"Log in to see more comments"],@"comment login notice is readable and still reports the actual account requirement");
    AWECommentSurveyConfigModel *surveyModel=[AWECommentSurveyConfigModel new];
    surveyModel.surveyDetail=@{@"title":@"你对该视频下的评论氛围是否满意?",@"options":@[@"非常不满意",@"不满意",@"一般",@"满意",@"非常满意"],@"id":@42};
    check([surveyModel.surveyDetail[@"title"] isEqualToString:@"How do you feel about these comments?"] &&
        [surveyModel.surveyDetail[@"options"][2] isEqualToString:@"Neutral"] && [surveyModel.surveyDetail[@"id"] isEqual:@42],@"survey-specific getter translates exact question/options before Lynx consumption and preserves IDs");
    AWECommentEvaluationConfig *evaluation=[AWECommentEvaluationConfig new];
    [evaluation configWithDict:@{@"ratingPointDes":@"非常不满意,不满意,一般,满意,非常满意",@"bizParams":@{@"text":@"一般"}}];
    check([evaluation.receivedConfig[@"ratingPointDes"] isEqualToString:@"Very dissatisfied,Dissatisfied,Neutral,Satisfied,Very satisfied"] &&
        [evaluation.receivedConfig[@"bizParams"][@"text"] isEqualToString:@"一般"],@"Lynx evaluation config translates proven rating fields while arbitrary nested payload stays original");
    [narrowError removeFromSuperview];
    NSBundle *sdkCatalog=[NSBundle bundleWithPath:[NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"AWEFixtureSDK.bundle/zh.lproj"]];
    check([[sdkCatalog localizedStringForKey:@"known" value:nil table:@"Fixture"] isEqualToString:@"SDK fixture label"],@"SDK lookup selects the bundled English value for the original key");
    check([[sdkCatalog localizedStringForKey:@"missing" value:nil table:@"Fixture"] isEqualToString:@"未找到英文测试文字"],@"missing SDK English entry preserves original text rather than exposing a key");
    check([[sdkCatalog localizedStringForKey:@"format" value:nil table:@"Fixture"] isEqualToString:@"%ld SDK notices"],@"bundled SDK English format entry retains its numeric placeholder");
    [results removeFromSuperview];[profileTabs removeFromSuperview];[commentContainer removeFromSuperview];[swift removeFromSuperview];
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
        check(sheet.actions.count==6,@"diagnostics sheet exposes four switches, copy and close");
        [sheet dismissViewControllerAnimated:NO completion:nil];
        [self showVisualSamples];
        BOOL success=YES; for (NSDictionary *item in checks) if (![item[@"passed"] boolValue]) success=NO;
        NSDictionary *report=@{@"scope":@"UIKit fixture only; original Douyin app and network were not executed",@"ios":UIDevice.currentDevice.systemVersion,@"device":UIDevice.currentDevice.model,@"checks":checks,@"passed":@(success),@"count":@(checks.count),@"fitting_observation":fittingObservation,@"overflow_labels":overflowLabels,@"translation_entries_tested":@(words.count)};
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
