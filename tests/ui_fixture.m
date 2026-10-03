// Runs only in a purpose-built Simulator fixture. It is not the Douyin app.
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#include <math.h>
#include <stdatomic.h>
#import "DGPolicy.h"
#import "DGHook.h"
#import "DGGeminiUI.h"
#import "DGMediaUI.h"
#import "DGSubtitleUI.h"
#import "DGComments.h"
#import "DGTransduck.h"
#import <WebKit/WebKit.h>
#import "DGAudioUI.h"
static atomic_int translationRequests;
@interface TranslationFixtureProtocol : NSURLProtocol
@end
@implementation TranslationFixtureProtocol
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {return [request.URL.host isEqualToString:@"generativelanguage.googleapis.com"] || [request.URL.host isEqualToString:@"yd.transduck.com"];}
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {return request;}
- (void)startLoading {
    atomic_fetch_add(&translationRequests,1);
    NSHTTPURLResponse *response=[[NSHTTPURLResponse alloc] initWithURL:self.request.URL statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:@{@"Content-Type":@"application/json"}];
    NSData *data=[NSJSONSerialization dataWithJSONObject:@{@"subtitleTranslateResults":@[@{@"translateResult":@"Nội dung do AI tạo.\n\nVideo này bàn về các <mark class=\"highlight\">kỹ thuật chụp ảnh</mark>.\n\nBản dịch minh họa trong fixture, không phải kết quả kiểm tra trên Douyin thật.",@"useAiTranslate":@YES}]} options:0 error:NULL];
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];[self.client URLProtocol:self didLoadData:data];[self.client URLProtocolDidFinishLoading:self];
}
- (void)stopLoading {}
@end

@interface ServalMarkdownView : UIView
@property(nonatomic,copy) NSString *content;
- (NSString *)getContent;
@end
@implementation ServalMarkdownView
- (NSString *)getContent {return self.content;}
@end
@interface LynxServalMarkdownViewWrapper : ServalMarkdownView
@end
@implementation LynxServalMarkdownViewWrapper
@end
@interface LynxMarkdownViewV2 : UIView {
    LynxServalMarkdownViewWrapper *_markdownView;
}
- (instancetype)initWithContent:(NSString *)content;
@end
@implementation LynxMarkdownViewV2
- (instancetype)initWithContent:(NSString *)content {
    if ((self=[super initWithFrame:CGRectMake(0,0,300,100)])) {_markdownView=[LynxServalMarkdownViewWrapper new];_markdownView.content=content;}return self;
}
@end
@interface LynxMarkdownShadowNode : NSObject {NSString *_content;}
- (instancetype)initWithContent:(NSString *)content;
@end
@implementation LynxMarkdownShadowNode
- (instancetype)initWithContent:(NSString *)content {if ((self=[super init])) _content=[content copy];return self;}
@end
@interface LynxMarkdownBundle : NSObject
@property(nonatomic,strong) LynxMarkdownShadowNode *node;
@property(nonatomic) BOOL content_complete;
@end
@implementation LynxMarkdownBundle
@end
@interface LynxMarkdownView : UIView
@property(nonatomic,strong) LynxMarkdownBundle *bundle;
@end
@implementation LynxMarkdownView
@end
@interface AWESearchAIGCQueryContext : NSObject
@property(nonatomic,copy) NSString *query;
@end
@implementation AWESearchAIGCQueryContext
@end
@interface AWEFeedDoubleColumnAIParseViewController : UIViewController
@property(nonatomic) NSUInteger nativeSends;
- (void)inputViewSendQueryContext:(id)context sourceFrom:(NSInteger)source;
@end
@implementation AWEFeedDoubleColumnAIParseViewController
- (void)inputViewSendQueryContext:(id)context sourceFrom:(NSInteger)source {(void)context;(void)source;++self.nativeSends;}
@end
@interface AWEFeedDoubleColumnCommentAIParseViewController : AWEFeedDoubleColumnAIParseViewController
@property(nonatomic) NSUInteger nativeEntries;
@property(nonatomic,strong) UIViewController *capturedPresentation;
@property(nonatomic,strong) UIViewController *contentVC;
- (void)commentAIParseTabDidEnter;
- (void)commentAIParseTabWillLeave;
@end
@implementation AWEFeedDoubleColumnCommentAIParseViewController
- (void)commentAIParseTabDidEnter {++self.nativeEntries;}
- (void)commentAIParseTabWillLeave {}
- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    (void)flag;self.capturedPresentation=viewControllerToPresent;if (completion) completion();
}
@end
@interface DGGeminiChatController (FixtureActions)
- (void)context;
- (void)mode;
@end
static UIView *findID(UIView *root,NSString *identifier) {
    if ([root.accessibilityIdentifier isEqualToString:identifier]) return root;
    for (UIView *child in root.subviews) {UIView *result=findID(child,identifier);if (result) return result;}
    return nil;
}

@interface _TtC16AWELiveSwiftImpl21AWEFeedLiveTabTagView : UIView
@end
@implementation _TtC16AWELiveSwiftImpl21AWEFeedLiveTabTagView
@end
@interface HTSLiveToolbarFixtureView : UIView
@end
@implementation HTSLiveToolbarFixtureView
@end
@interface HTSLiveRoomTitleFixtureView : UIView
@end
@implementation HTSLiveRoomTitleFixtureView
@end
@interface HTSLiveChatFixtureView : UIView
@end
@implementation HTSLiveChatFixtureView
@end
@interface AWEAwemeBackgroundPlayStoreService : NSObject
@property BOOL originalSwitch;
@property NSInteger originalAudio;
@property NSInteger originalScene;
- (BOOL)switchState;
- (NSInteger)audioSwitchState;
- (NSInteger)audioSceneState;
@end
@implementation AWEAwemeBackgroundPlayStoreService
- (BOOL)switchState { return self.originalSwitch; }
- (NSInteger)audioSwitchState { return self.originalAudio; }
- (NSInteger)audioSceneState { return self.originalScene; }
@end

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
@property NSRange linkRange;
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
@interface YYTextLayout : NSObject
@property(nonatomic,strong) NSAttributedString *text;
@property(nonatomic,strong) id container;
+ (instancetype)layoutWithContainer:(id)container text:(NSAttributedString *)text;
@end
@implementation YYTextLayout
+ (instancetype)layoutWithContainer:(id)container text:(NSAttributedString *)text {YYTextLayout *layout=[self new];layout.container=container;layout.text=text;return layout;}
@end
@interface YYLabel : UIView
@property(nonatomic,strong) YYTextLayout *textLayout;
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

@interface AWEAwemeModel : NSObject
@property(nonatomic,copy) NSString *itemID;
@end
@implementation AWEAwemeModel
@end
@interface AWEPlayVideoViewController : UIViewController
@property(nonatomic,strong) AWEAwemeModel *model;
@property(nonatomic) double playback;
@property(nonatomic) BOOL playing;
@property(nonatomic) BOOL muted;
@property(nonatomic) float videoRate;
@property(nonatomic) NSUInteger pauseCalls,resumeCalls;
- (double)currentPlaybackTime;
- (BOOL)pause;
- (BOOL)isPlaying;
- (void)resumePlayVideo;
@end
@implementation AWEPlayVideoViewController
- (void)viewDidAppear:(BOOL)animated {[super viewDidAppear:animated];}
- (void)viewWillDisappear:(BOOL)animated {[super viewWillDisappear:animated];}
- (double)currentPlaybackTime {return self.playback;}
- (BOOL)pause {self.playing=NO;self.pauseCalls++;return YES;}
- (BOOL)isPlaying {return self.playing;}
- (float)getCurrentPlaybackRate {return self.videoRate>0 ? self.videoRate : 1;}
- (void)updatePlaybackRate:(double)rate {self.videoRate=(float)rate;}
- (BOOL)isMute {return self.muted;}
- (void)setPlayerSeekTime:(double)time completion:(void (^)(BOOL))completion {self.playback=time;if (completion) completion(YES);}
- (void)resumePlayVideo {self.playing=YES;self.resumeCalls++;}
@end
@interface MissedAppearancePlayer : AWEPlayVideoViewController
@end
@implementation MissedAppearancePlayer
- (void)viewDidAppear:(BOOL)animated {(void)animated;}
@end
@interface AWECommentModel : NSObject
@property(nonatomic,copy) NSString *content;
@end
@implementation AWECommentModel
@end
@interface AWECommentNewFeedCell : UIView
@property(nonatomic,strong) AWECommentModel *commentModel;
@end
@implementation AWECommentNewFeedCell
@end
@interface AWECommentContainerViewController : UIViewController
@end
@implementation AWECommentContainerViewController
- (void)viewDidAppear:(BOOL)animated {[super viewDidAppear:animated];}
- (void)viewWillDisappear:(BOOL)animated {[super viewWillDisappear:animated];}
@end
@interface AWECommentFullScreenContainerViewController : AWECommentContainerViewController
@end
@implementation AWECommentFullScreenContainerViewController
@end
@interface _TtC28AWECommentPanelListSwiftImpl20BaseCellCommentLabel : YYLabel
@end
@implementation _TtC28AWECommentPanelListSwiftImpl20BaseCellCommentLabel
@end
static atomic_int mediaRequests,commentRequests;
static atomic_bool gtxThrottle;
static atomic_bool longComments;
static NSData *mediaJSON(id value) {return [NSJSONSerialization dataWithJSONObject:value options:0 error:NULL];}
static NSData *mediaBody(NSURLRequest *request) {
    if (request.HTTPBody) return request.HTTPBody;
    NSInputStream *stream=request.HTTPBodyStream;NSMutableData *result=[NSMutableData new];[stream open];uint8_t bytes[4096];NSInteger count;
    while ((count=[stream read:bytes maxLength:sizeof(bytes)])>0) [result appendBytes:bytes length:(NSUInteger)count];[stream close];return result;
}
@interface MediaFixtureProtocol : NSURLProtocol
@end
@implementation MediaFixtureProtocol
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {(void)request;return YES;}
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {return request;}
- (void)startLoading {
    atomic_fetch_add(&mediaRequests,1);NSURLRequest *request=self.request;NSInteger status=200;NSData *data;
    if ([request.URL.host isEqual:@"api.apify.com"]) {
        if ([request.URL.path containsString:@"/runs"]) {status=201;data=mediaJSON(@{@"data":@{@"id":@"run1",@"status":@"SUCCEEDED",@"defaultDatasetId":@"data1"}});}
        else data=mediaJSON(@[@{@"url":@"https://www.douyin.com/video/7534679152504376595",@"videoUrl":@"https://www.douyin.com/aweme/v1/play/?file_id=mock",@"duration":@10,@"errMsg":@""}]);
    } else if ([request.URL.host isEqual:@"api.deepgram.com"]) data=mediaJSON(@{@"metadata":@{@"duration":@10},@"results":@{@"channels":@[@{@"alternatives":@[@{@"words":@[@{@"word":@"你",@"start":@0,@"end":@0},@{@"word":@"好",@"start":@0,@"end":@1},@{@"word":@"中国",@"start":@2,@"end":@3},@{@"word":@"谢谢",@"start":@5,@"end":@6}]}]}]}});
    else if ([request.URL.host isEqual:@"generativelanguage.googleapis.com"]) {
        NSDictionary *body=[NSJSONSerialization JSONObjectWithData:mediaBody(request) options:0 error:NULL];NSString *text=body[@"contents"][0][@"parts"][0][@"text"];NSArray *input=[NSJSONSerialization JSONObjectWithData:[text dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];NSMutableArray *rows=[NSMutableArray new];
        for (NSDictionary *cue in input) [rows addObject:@{@"id":cue[@"id"],@"text":atomic_load(&longComments) ? [@"Bản dịch tiếng Việt dài cần xuống dòng đầy đủ, giữ đúng ý của bình luận và đọc rõ trên màn hình nhỏ. " stringByPaddingToLength:1400 withString:@"Nội dung tiếp theo phải được cuộn để đọc, không bị che bởi hàng kế tiếp. " startingAtIndex:0] : @[@"Xin chào",@"Trung Quốc",@"Cảm ơn"][[cue[@"id"] unsignedIntegerValue]]}];
        data=mediaJSON(@{@"candidates":@[@{@"content":@{@"parts":@[@{@"text":[[NSString alloc] initWithData:mediaJSON(@{@"translations":rows}) encoding:NSUTF8StringEncoding]}]},@"finishReason":@"STOP"}]});
    } else if ([request.URL.host isEqual:@"translate.googleapis.com"]) {atomic_fetch_add(&commentRequests,1);if (atomic_load(&gtxThrottle)) {status=429;data=mediaJSON(@{});}else data=mediaJSON(@[@[@[@"Video rất hay, cảm ơn bạn!",@"视频很好，谢谢！"]]]);}
    else if ([request.URL.host isEqual:@"yd.transduck.com"]) {
        NSDictionary *body=[NSJSONSerialization JSONObjectWithData:mediaBody(request) options:0 error:NULL];NSMutableArray *rows=[NSMutableArray new];for (NSDictionary *cue in body[@"subtitles"]) [rows addObject:@{@"translateResult":@[@"Xin ch\u00e0o",@"Trung Qu\u1ed1c",@"C\u1ea3m \u01a1n"][[cue[@"index"] unsignedIntegerValue]],@"useAiTranslate":@YES}];data=mediaJSON(@{@"subtitleTranslateResults":rows});
    }
    else {status=500;data=mediaJSON(@{});}
    [self.client URLProtocol:self didReceiveResponse:[[NSHTTPURLResponse alloc] initWithURL:request.URL statusCode:status HTTPVersion:@"HTTP/1.1" headerFields:nil] cacheStoragePolicy:NSURLCacheStorageNotAllowed];[self.client URLProtocol:self didLoadData:data];[self.client URLProtocolDidFinishLoading:self];
}
- (void)stopLoading {}
@end
static void mediaWait(BOOL (^finished)(void)) {NSDate *until=[NSDate dateWithTimeIntervalSinceNow:10];while (!finished() && until.timeIntervalSinceNow>0) [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];}

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
- (void)presentPublicFinder:(UIViewController *)presenter profileLink:(BOOL)profileLink;
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
- (void)showMediaSamples;
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

- (void)showMediaSamples {
    NSURLSessionConfiguration *cfg=NSURLSessionConfiguration.ephemeralSessionConfiguration;cfg.protocolClasses=@[MediaFixtureProtocol.class];DGMediaFixtureConfiguration(cfg,nil);
    DGMediaInstall(nil);DGMediaFixtureBackend(@{});check([DGMediaSnapshot()[@"hooks_installed"] integerValue]==7,@"media installs only seven verified native ABI hooks");
    AWEPlayVideoViewController *player=[AWEPlayVideoViewController new];AWEAwemeModel *model=[AWEAwemeModel new];model.itemID=@"7534679152504376595";player.model=model;player.playback=0.5;player.playing=YES;
    player.view.backgroundColor=UIColor.darkGrayColor;self.window.rootViewController=player;[player viewDidAppear:NO];[self.window layoutIfNeeded];
    UILabel *title=label(player.view,@"Video fixture · phụ đề theo thời gian phát",220);title.frame=CGRectMake(18,220,self.window.bounds.size.width-36,60);title.numberOfLines=0;title.textColor=UIColor.whiteColor;
    UIButton *button=(UIButton *)findID(self.window,@"vietnamese-captions-button");UILabel *caption=(UILabel *)findID(self.window,@"vietnamese-captions-text");
    check(button && caption.hidden && atomic_load(&mediaRequests)==0,@"video appearance adds one opt-in button and sends no provider requests");
    DGMediaAttachWindow(self.window);DGMediaAttachWindow(self.window);NSUInteger shortcutCount=0;
    for (UIGestureRecognizer *gesture in self.window.gestureRecognizers) if ([gesture isKindOfClass:UITapGestureRecognizer.class] && ((UITapGestureRecognizer *)gesture).numberOfTapsRequired==4) {
        UITapGestureRecognizer *tap=(UITapGestureRecognizer *)gesture;shortcutCount++;
        check(tap.numberOfTouchesRequired==1 && !tap.cancelsTouchesInView && !tap.delaysTouchesBegan && !tap.delaysTouchesEnded,@"four taps require one finger and preserve native video touches without delay");
    }
    check(shortcutCount==1 && atomic_load(&mediaRequests)==0,@"shortcut attachment is idempotent and fewer than four taps have no action configured");
    check(DGMediaFixtureShortcut(self.window,CGPointMake(280,300)),@"four-tap production routing starts current visible video");
    check(!player.playing && player.pauseCalls==1 && [DGMediaSnapshot()[@"caption_waiting"] boolValue],@"video pauses before subtitle provider requests start");
    DGMediaFixtureShortcut(self.window,CGPointMake(280,300));
    check([DGMediaSnapshot()[@"caption_running"] boolValue],@"repeated four taps neither cancel nor duplicate pending subtitle work");
    player.playing=YES;DGMediaFixtureTick(player);check(!player.playing && player.pauseCalls==2,@"native playback cannot run ahead while subtitles are being prepared");
    mediaWait(^BOOL{return ![DGMediaSnapshot()[@"caption_running"] boolValue];});DGMediaFixtureTick(player);
    check(atomic_load(&mediaRequests)==4,@"idempotent shortcut completes with exactly one Apify run ASR and translation request");
    check(player.playing && player.resumeCalls==1 && ![DGMediaSnapshot()[@"caption_waiting"] boolValue],@"complete subtitles resume the same video once");
    check(!caption.hidden && [caption.text isEqual:@"Xin chào"],@"caption extraction transcription translation and overlay complete via mock pipeline");
    check(![DGMediaSnapshot()[@"tts_enabled"] boolValue] && !player.muted && fabs([player getCurrentPlaybackRate]-1)<0.01,@"translated subtitles resume immediately with original audio and unchanged user speed, without TTS");
    check(caption.numberOfLines==3 && caption.font.pointSize>=19 && caption.frame.origin.y>CGRectGetMidY(self.window.bounds) && CGRectGetMaxX(caption.frame)<self.window.bounds.size.width-60 && CGRectGetMaxY(caption.frame)<self.window.bounds.size.height-144,@"portrait subtitles have at most three lines and clear right controls and bottom description");
    NSString *longSubtitle=@"Bản dịch tiếng Việt cần dễ đọc và giữ chính xác từng ý trong câu gốc. Mỗi trang chỉ có vài dòng, không che các nút và không dồn toàn bộ nội dung video vào một đoạn dài. Tiếng Việt có dấu và biểu tượng 👨‍👩‍👧‍👦 cũng phải được giữ đầy đủ.";
    UIFont *readingFont=[UIFont systemFontOfSize:24];NSArray *pages=DGSubtitlePages(longSubtitle,220,readingFont,3);
    check(pages.count>2 && [[pages componentsJoinedByString:@""] isEqual:longSubtitle],@"measured subtitle pagination retains all Vietnamese accents punctuation and emoji without shortening meaning");
    BOOL fit=YES;for (NSString *page in pages) {NSString *trim=[page stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];CGFloat height=[trim boundingRectWithSize:CGSizeMake(220,CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:readingFont} context:nil].size.height;if (height>ceil(readingFont.lineHeight*3)+1) fit=NO;}
    check(fit,@"every long subtitle page fits three measured lines at accessibility font size on a narrow display");
    check(!DGSubtitlePageAt(pages,0.9,1,5) && !DGSubtitlePageAt(pages,5,1,5) && [DGSubtitlePageAt(pages,1,1,5) isEqual:[pages.firstObject stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet]],@"subtitle pages never appear before their original cue or spill into the next cue");
    NSString *middlePage=DGSubtitlePageAt(pages,3,1,5);check([DGSubtitlePageAt(pages,3,1,5) isEqual:middlePage] && [DGSubtitlePageAt(pages,1,1,5) isEqual:DGSubtitlePageAt(pages,1,1,5)],@"page selection uses native video time so pause seek and loop do not advance on wall-clock time");
    NSArray *landscapePages=DGSubtitlePages(longSubtitle,460,[UIFont systemFontOfSize:19],2);check(landscapePages.count && [[landscapePages componentsJoinedByString:@""] isEqual:longSubtitle],@"landscape uses two-line pages and retains the whole cue");
    check(!DGSubtitlePages(longSubtitle,NAN,readingFont,3).count && !DGSubtitlePages(@"",220,readingFont,3).count && !DGSubtitlePageAt(pages,NAN,1,5),@"subtitle layout rejects empty text invalid dimensions and invalid clocks safely");
    DGMediaFixtureTick(player);check([caption.text isEqual:@"Xin chào"],@"paused playback holds caption without advancing wall time");
    player.playback=1.5;DGMediaFixtureTick(player);check(caption.hidden,@"speech gap hides previous cue");
    player.playback=5.5;DGMediaFixtureTick(player);check([caption.text isEqual:@"Cảm ơn"] && !caption.hidden,@"seek forward uses actual native playback time");
    player.playback=0.5;DGMediaFixtureTick(player);check([caption.text isEqual:@"Xin chào"],@"seek backward and video loop restore first cue");
    [player.view layoutIfNeeded];[button layoutIfNeeded];
    check([button.currentTitle isEqual:@"Tắt phụ đề Việt"] && [button.titleLabel.text isEqual:button.currentTitle] && button.titleLabel.bounds.size.width>40,@"caption button retains visible title after asynchronous stage updates");
    [self saveWindowImage:@"ui-captions.png"];int requests=atomic_load(&mediaRequests);
    [button sendActionsForControlEvents:UIControlEventTouchUpInside];check(caption.hidden,@"subtitle off hides overlay immediately");
    [button sendActionsForControlEvents:UIControlEventTouchUpInside];DGMediaFixtureTick(player);check(!caption.hidden && atomic_load(&mediaRequests)==requests,@"subtitle re-enable uses complete cache without API cost");
    AWEAwemeModel *other=[AWEAwemeModel new];other.itemID=@"7683814443658054955";player.model=other;check(caption.hidden && ![DGMediaSnapshot()[@"caption_showing"] boolValue],@"changing native video model cancels and clears prior subtitles");
    NSUInteger resumed=player.resumeCalls;
    [button sendActionsForControlEvents:UIControlEventTouchUpInside];[button sendActionsForControlEvents:UIControlEventTouchUpInside];
    check(player.playing && player.resumeCalls==resumed+1 && ![DGMediaSnapshot()[@"caption_running"] boolValue],@"manual cancellation restores playback rather than leaving video paused");
    [button sendActionsForControlEvents:UIControlEventTouchUpInside];mediaWait(^BOOL{return ![DGMediaSnapshot()[@"caption_running"] boolValue];});
    check(!player.playing && [DGMediaSnapshot()[@"caption_waiting"] boolValue] && [button.currentTitle isEqual:@"Bỏ qua · phát video"],@"provider failure holds video until subtitles exist or user explicitly skips");
    int failedRequests=atomic_load(&mediaRequests);DGMediaFixtureShortcut(self.window,CGPointMake(280,300));
    check(!player.playing && atomic_load(&mediaRequests)==failedRequests,@"four taps after failure cannot automatically spend another paid request");
    [button sendActionsForControlEvents:UIControlEventTouchUpInside];check(player.playing && ![DGMediaSnapshot()[@"caption_waiting"] boolValue],@"explicit skip after failure restores playback");
    resumed=player.resumeCalls;[button sendActionsForControlEvents:UIControlEventTouchUpInside];[NSNotificationCenter.defaultCenter postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];check(caption.hidden && ![DGMediaSnapshot()[@"caption_running"] boolValue] && player.resumeCalls==resumed,@"background cancels pipeline without unexpectedly resuming video");
    // An embedded player that never called the hooked native appearance method.
    UIViewController *host=[UIViewController new];MissedAppearancePlayer *late=[MissedAppearancePlayer new];late.model=model;late.playback=0.5;late.playing=YES;
    [host addChildViewController:late];late.view.frame=self.window.bounds;[host.view addSubview:late.view];[late didMoveToParentViewController:host];
    AWEPlayVideoViewController *hiddenPlayer=[AWEPlayVideoViewController new];hiddenPlayer.model=other;[host addChildViewController:hiddenPlayer];hiddenPlayer.view.frame=self.window.bounds;hiddenPlayer.view.hidden=YES;[host.view addSubview:hiddenPlayer.view];
    UIView *nativeOverlay=[[UIView alloc] initWithFrame:self.window.bounds];[host.view addSubview:nativeOverlay];self.window.rootViewController=host;[self.window layoutIfNeeded];
    DGMediaAttachWindow(self.window);check(!late.pauseCalls && !hiddenPlayer.pauseCalls,@"late-install recovery adds UI without automatically starting paid work");
    check(DGMediaFixtureShortcut(self.window,CGPointMake(280,300)) && late.pauseCalls==1 && !hiddenPlayer.pauseCalls,@"shortcut resolves embedded visible player beneath native sibling overlay and excludes hidden player");
    mediaWait(^BOOL{return ![DGMediaSnapshot()[@"caption_running"] boolValue];});
    UIButton *nativeControl=[UIButton buttonWithType:UIButtonTypeSystem];nativeControl.frame=CGRectMake(250,280,80,80);[nativeOverlay addSubview:nativeControl];
    int controlRequests=atomic_load(&mediaRequests);check(!DGMediaFixtureShortcut(self.window,CGPointMake(280,300)) && atomic_load(&mediaRequests)==controlRequests,@"four taps on native controls do not start captions");
    [nativeControl removeFromSuperview];
    UIViewController *modal=[UIViewController new];[host presentViewController:modal animated:NO completion:nil];mediaWait(^BOOL{return modal.view.window!=nil;});
    check(!DGMediaFixtureShortcut(self.window,CGPointMake(280,300)),@"presented modal prevents resolving underlying player");
    [host dismissViewControllerAnimated:NO completion:nil];
    AWECommentContainerViewController *comments=[AWECommentContainerViewController new];comments.view.backgroundColor=UIColor.systemBackgroundColor;self.window.rootViewController=comments;
    _TtC28AWECommentPanelListSwiftImpl20BaseCellCommentLabel *native=[[_TtC28AWECommentPanelListSwiftImpl20BaseCellCommentLabel alloc] initWithFrame:CGRectMake(18,200,330,55)];native.textLayout=[YYTextLayout layoutWithContainer:[NSObject new] text:[[NSAttributedString alloc] initWithString:@"视频很好，谢谢！"]];[comments.view addSubview:native];
    _TtC28AWECommentPanelListSwiftImpl20BaseCellCommentLabel *hidden=[[_TtC28AWECommentPanelListSwiftImpl20BaseCellCommentLabel alloc] initWithFrame:CGRectMake(18,280,300,40)];hidden.text=@"隐藏的评论";hidden.hidden=YES;[comments.view addSubview:hidden];
    UILabel *name=label(comments.view,@"Username must not be captured",140);ServalMarkdownView *analysis=[[ServalMarkdownView alloc] initWithFrame:CGRectMake(10,380,320,50)];analysis.content=@"AI summary must not be captured";[comments.view addSubview:analysis];[comments viewDidAppear:NO];[comments.view layoutIfNeeded];
    check([DGMediaReadVisibleComments(comments.view) isEqual:@[@"视频很好，谢谢！"]],@"GTX captures only visible native comment text excluding names hidden comments and AI");
    UIView *wrapper=[[UIView alloc] initWithFrame:CGRectZero];[comments.view addSubview:wrapper];
    AWECommentNewFeedCell *drawn=[[AWECommentNewFeedCell alloc] initWithFrame:CGRectMake(18,300,310,45)];AWECommentModel *commentModel=[AWECommentModel new];commentModel.content=@"模型评论";drawn.commentModel=commentModel;[wrapper addSubview:drawn];
    check([DGMediaReadVisibleComments(comments.view) containsObject:commentModel.content],@"GTX reads audited model from custom-drawn cell inside zero-size non-clipping wrapper");
    wrapper.clipsToBounds=YES;check(![DGMediaReadVisibleComments(comments.view) containsObject:commentModel.content],@"GTX respects clipping wrappers and does not send invisible comment model");wrapper.clipsToBounds=NO;
    drawn.frame=CGRectMake(18,-100,310,45);check(![DGMediaReadVisibleComments(comments.view) containsObject:commentModel.content],@"GTX excludes offscreen model cells");[wrapper removeFromSuperview];
    mediaWait(^BOOL{return countText(comments.view,@"Video rất hay, cảm ơn bạn!")>0;});
    check(countText(comments.view,@"Video rất hay, cảm ơn bạn!")>0 && atomic_load(&commentRequests)==1,@"opening comments automatically displays translations in measured rows preserving native text");
    check([name.text isEqual:@"Username must not be captured"] && [hidden.text isEqual:@"\u9690\u85cf\u7684\u8bc4\u8bba"],@"automatic GTX preserves author name and hidden text");
    check([DGCommentVisibleText(native) isEqual:@"视频很好，谢谢！"],@"original fixed-frame comment and rich text remain unchanged");
    UITableView *translatedTable=(id)findID(comments.view,@"comments-vietnamese-table");
    check(translatedTable.rowHeight==UITableViewAutomaticDimension && translatedTable.visibleCells.firstObject.textLabel.numberOfLines==0,@"Vietnamese comment rows wrap at their own measured height");
    UISegmentedControl *commentLanguage=(id)findID(comments.view,@"comments-language");commentLanguage.selectedSegmentIndex=1;[commentLanguage sendActionsForControlEvents:UIControlEventValueChanged];check(translatedTable.hidden,@"original mode exposes native comment controls and media");commentLanguage.selectedSegmentIndex=0;[commentLanguage sendActionsForControlEvents:UIControlEventValueChanged];
    int translatedRequests=atomic_load(&commentRequests);
    [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
    check(atomic_load(&commentRequests)==translatedRequests,@"translated visible cells are not sent again on subsequent scans");
    native.textLayout=nil;native.text=@"\u65b0\u7684\u8bc4\u8bba";
    mediaWait(^BOOL{return atomic_load(&commentRequests)>translatedRequests && countText(comments.view,@"Video rất hay, cảm ơn bạn!")>0;});
    check(atomic_load(&commentRequests)==translatedRequests+1 && countText(comments.view,@"Video rất hay, cảm ơn bạn!")>0,@"reused native cell is translated for its new source");
    _TtC28AWECommentPanelListSwiftImpl20BaseCellCommentLabel *offscreen=[[_TtC28AWECommentPanelListSwiftImpl20BaseCellCommentLabel alloc] initWithFrame:CGRectMake(18,1500,320,40)];offscreen.text=@"\u8fd8\u6709\u4e00\u6761";[comments.view addSubview:offscreen];
    translatedRequests=atomic_load(&commentRequests);[NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
    check(atomic_load(&commentRequests)==translatedRequests,@"offscreen comment is not translated or charged a request");
    offscreen.frame=CGRectMake(18,300,320,40);mediaWait(^BOOL{return atomic_load(&commentRequests)>translatedRequests && countText(comments.view,@"Video rất hay, cảm ơn bạn!")>0;});
    check(atomic_load(&commentRequests)==translatedRequests+1,@"scrolling another comment into view starts automatic GTX");
    DGCommentsStop(comments);translatedRequests=atomic_load(&commentRequests);native.text=@"\u505c\u6b62\u540e\u4e0d\u53d1\u9001";
    [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
    check(atomic_load(&commentRequests)==translatedRequests,@"closing comment session cancels automatic work");
    [self saveWindowImage:@"ui-gtx-comments.png"];
    atomic_store(&gtxThrottle,YES);native.textLayout=nil;native.text=@"额度限制测试";int before429=atomic_load(&commentRequests);[comments viewDidAppear:NO];UIButton *commentButton=(UIButton *)findID(self.window,@"gtx-comments-button");
    mediaWait(^BOOL {return countText(comments.view,@"Xin chào")>0;});check(countText(comments.view,@"Xin chào")>0 && atomic_load(&commentRequests)==before429+1,@"ordinary comment automatically uses Gemini when GTX returns 429");
    native.text=@"另一个限制测试";mediaWait(^BOOL {return countText(comments.view,@"Xin chào")>0;});check(countText(comments.view,@"Xin chào")>0 && atomic_load(&commentRequests)==before429+1,@"new visible comment uses authorized fallback during shared cooldown without repeated GTX calls");
    check([commentButton.currentTitle containsString:@"Gemini"],@"comment status names the paid fallback provider instead of claiming GTX success");
    DGCommentsStop(comments);atomic_store(&gtxThrottle,NO);
    atomic_store(&longComments,YES);AWECommentContainerViewController *longPanel=[AWECommentContainerViewController new];UIViewController *inner=[UIViewController new];self.window.rootViewController=longPanel;longPanel.view.backgroundColor=UIColor.systemBackgroundColor;[longPanel addChildViewController:inner];inner.view.frame=longPanel.view.bounds;[longPanel.view addSubview:inner.view];[inner didMoveToParentViewController:longPanel];
    UIScrollView *nativeList=[[UIScrollView alloc] initWithFrame:CGRectMake(0,100,self.window.bounds.size.width,500)];nativeList.contentSize=CGSizeMake(nativeList.bounds.size.width,1400);[inner.view addSubview:nativeList];
    _TtC28AWECommentPanelListSwiftImpl20BaseCellCommentLabel *fixed=[[_TtC28AWECommentPanelListSwiftImpl20BaseCellCommentLabel alloc] initWithFrame:CGRectMake(16,4,300,24)];fixed.text=@"新评论长文内容测试";[nativeList addSubview:fixed];
    UIButton *reply=[UIButton buttonWithType:UIButtonTypeSystem];reply.frame=CGRectMake(16,36,80,30);[reply setTitle:@"Reply" forState:UIControlStateNormal];[nativeList addSubview:reply];UIImageView *attachment=[[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"star"]];attachment.frame=CGRectMake(16,80,100,100);[nativeList addSubview:attachment];
    DGMediaClient *readerClient=[[DGMediaClient alloc] initWithConfig:@{} geminiKey:@"fixture-key-no-network" store:[[DGTranslationStore alloc] initWithURL:nil] configuration:cfg];DGCommentsStart(longPanel,readerClient,nil);
    mediaWait(^BOOL {UITableView *t=(id)findID(inner.view,@"comments-vietnamese-table");[inner.view layoutIfNeeded];return t.contentSize.height>t.bounds.size.height;});
    UITableView *reader=(id)findID(inner.view,@"comments-vietnamese-table");check(reader.contentSize.height>reader.bounds.size.height && reader.visibleCells.firstObject.textLabel.numberOfLines==0 && fixed.bounds.size.height==24,@"long Vietnamese translation owns a scrollable measured row instead of overwriting a fixed Chinese label");[self saveWindowImage:@"ui-comments-long.png"];
    UISegmentedControl *readerLanguage=(id)findID(inner.view,@"comments-language");readerLanguage.selectedSegmentIndex=1;[readerLanguage sendActionsForControlEvents:UIControlEventValueChanged];
    CGPoint replyPoint=[reply convertPoint:CGPointMake(40,15) toView:inner.view];check([inner.view hitTest:replyPoint withEvent:nil]==reply && attachment.superview==nativeList && nativeList.contentInset.top==48,@"original mode reserves language-switch space and preserves reply controls and image attachments");
    DGMediaClient *nestedReader=[[DGMediaClient alloc] initWithConfig:@{} geminiKey:@"fixture-key-no-network" store:[[DGTranslationStore alloc] initWithURL:nil] configuration:cfg];DGCommentsStart(inner,nestedReader,nil);
    check(nativeList.contentInset.top==0 && findID(inner.view,@"comments-translation-panel")!=nil,@"nested comment ownership removes the previous surface and restores its native insets");DGCommentsStop(inner);check(!findID(longPanel.view,@"comments-translation-panel") && nativeList.contentInset.top==0,@"closing comments removes the reader and restores native layout");atomic_store(&longComments,NO);

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
    title=label(sidebar,@"Sidebar fixture • 0.14.0",65);title.frame=CGRectMake(20,65,width-40,28);title.font=[UIFont boldSystemFontOfSize:18];
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
    title=label(filters,@"Search controls fixture • 0.14.0",80);title.frame=CGRectMake(20,80,width-40,30);
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
    title=label(settingsScreen.view,@"Settings fixture • 0.14.0",80);title.frame=CGRectMake(20,80,width-40,30);
    for (NSUInteger i=0;i<settingsWords.count;i++) { UILabel *item=label(settingsScreen.view,settingsWords[i],135+i*43);item.frame=CGRectMake(20,135+i*43,180,36); }
    screen=settingsScreen;self.window.rootViewController=screen;[self.window layoutIfNeeded];
    [self saveWindowImage:@"ui-settings.png"];

    AWECommentFixtureView *commentCanvas=[[AWECommentFixtureView alloc] initWithFrame:self.window.bounds];commentCanvas.backgroundColor=UIColor.systemBackgroundColor;
    AWECommentVCHeaderBarView *commentHeader=[[AWECommentVCHeaderBarView alloc] initWithFrame:CGRectMake(16,70,width-32,150)];[commentCanvas addSubview:commentHeader];
    title=label(commentHeader,@"Comment controls fixture • 0.14.0",0);title.frame=CGRectMake(4,0,width-40,28);title.font=[UIFont boldSystemFontOfSize:17];
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
    title=label(featured,@"Featured narrow-label fixture • 0.14.0",80);title.frame=CGRectMake(20,80,width-40,30);title.font=[UIFont boldSystemFontOfSize:17];
    UILabel *featuredTitle=label(featured,@"网络错误",320);featuredTitle.frame=CGRectMake((width-60)/2,320,60,30);featuredTitle.textAlignment=NSTextAlignmentCenter;
    UILabel *errorDetail=label(featured,@"请检查网络连接后重试",365);errorDetail.frame=CGRectMake((width-120)/2,365,120,30);errorDetail.textAlignment=NSTextAlignmentCenter;
    UIButton *retryButton=[UIButton buttonWithType:UIButtonTypeSystem];retryButton.frame=CGRectMake((width-100)/2,415,100,42);[retryButton setTitle:@"重试" forState:UIControlStateNormal];[featured addSubview:retryButton];
    UILabel *notice=label(featured,@"操作失败，请稍后重试",485);notice.frame=CGRectMake(20,485,width-40,40);notice.textAlignment=NSTextAlignmentCenter;
    screen=[UIViewController new];screen.view=featured;self.window.rootViewController=screen;[self.window layoutIfNeeded];
    [self saveWindowImage:@"ui-featured-narrow.png"];

    UIView *live=[[UIView alloc] initWithFrame:self.window.bounds];live.backgroundColor=UIColor.systemBackgroundColor;
    title=label(live,@"LIVE controls fixture • 0.14.0",80);title.frame=CGRectMake(20,80,width-40,30);title.font=[UIFont boldSystemFontOfSize:18];
    _TtC16AWELiveSwiftImpl21AWEFeedLiveTabTagView *tags=[[_TtC16AWELiveSwiftImpl21AWEFeedLiveTabTagView alloc] initWithFrame:CGRectMake(20,140,width-40,44)];[live addSubview:tags];
    NSArray *cn=@[@"明星",@"聊天",@"唱歌",@"团播",@"颜值"];
    CGFloat slot=(width-40)/5;
    for (NSUInteger i=0;i<cn.count;i++) {
        UILabel *tab=label(tags,cn[i],0);tab.frame=CGRectMake(i*slot,0,slot-7,32);tab.textAlignment=NSTextAlignmentCenter;tab.font=[UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    }
    HTSLiveToolbarFixtureView *tools=[[HTSLiveToolbarFixtureView alloc] initWithFrame:CGRectMake(20,230,width-40,190)];[live addSubview:tools];
    for (NSUInteger i=0;i<3;i++) {
        UILabel *item=label(tools,(@[@"后台播放音频",@"清晰度",@"更多功能"])[i],i*54);item.frame=CGRectMake(0,i*54,170,36);
    }
    HTSLiveRoomTitleFixtureView *room=[[HTSLiveRoomTitleFixtureView alloc] initWithFrame:CGRectMake(20,470,width-40,55)];[live addSubview:room];
    UILabel *roomName=label(room,@"明星",0);roomName.frame=CGRectMake(0,0,170,36);
    HTSLiveChatFixtureView *chat=[[HTSLiveChatFixtureView alloc] initWithFrame:CGRectMake(20,530,width-40,55)];[live addSubview:chat];
    UILabel *chatMessage=label(chat,@"聊天",0);chatMessage.frame=CGRectMake(0,0,170,36);
    UILabel *liveNote=label(live,@"Chinese below the tools is sample room/chat content and remains unchanged.",620);liveNote.frame=CGRectMake(20,620,width-40,66);liveNote.numberOfLines=3;liveNote.font=[UIFont systemFontOfSize:14];
    screen=[UIViewController new];screen.view=live;self.window.rootViewController=screen;[self.window layoutIfNeeded];
    check([roomName.text isEqual:@"明星"] && [chatMessage.text isEqual:@"聊天"],@"LIVE visual sample protects room titles and chat content");
    [self saveWindowImage:@"ui-live.png"];
    {
    NSURLSessionConfiguration *translationMock=NSURLSessionConfiguration.ephemeralSessionConfiguration;translationMock.protocolClasses=@[TranslationFixtureProtocol.class];
    DGGeminiTranslationFixtureConfiguration(translationMock,[[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:@"fixture-ai-translation.json"]);
    NSDictionary *aiState=DGGeminiSnapshot();
    check([aiState[@"configured"] boolValue] && [aiState[@"native_send_hook"] boolValue] && [aiState[@"native_entry_hook"] boolValue] && [aiState[@"native_leave_hook"] boolValue],@"Gemini fixture installs three exact comment-AI hooks with a synthetic key");
    AWEFeedDoubleColumnCommentAIParseViewController *ai=[AWEFeedDoubleColumnCommentAIParseViewController new];
    ai.view.backgroundColor=UIColor.systemBackgroundColor;self.window.rootViewController=ai;[self.window layoutIfNeeded];
    ai.contentVC=[UIViewController new];[ai.contentVC loadViewIfNeeded];
    UIView *drawnRoot=[[UIView alloc] initWithFrame:CGRectMake(0,0,300,300)];
    LynxMarkdownViewV2 *v2=[[LynxMarkdownViewV2 alloc] initWithContent:@"V2 源内容，不是 UILabel。"];[drawnRoot addSubview:v2];
    check([DGGeminiReadSummary(drawnRoot) isEqual:@"V2 源内容，不是 UILabel。"] && v2.subviews.count==0,@"V2 captures backing renderer ivar without a bundle getter or visible text subviews");
    [v2 removeFromSuperview];LynxMarkdownView *legacy=[[LynxMarkdownView alloc] initWithFrame:CGRectMake(0,0,300,100)];legacy.bundle=[LynxMarkdownBundle new];legacy.bundle.node=[[LynxMarkdownShadowNode alloc] initWithContent:@"原始完整分析\n"];legacy.bundle.content_complete=YES;[drawnRoot addSubview:legacy];
    check([DGGeminiReadSummary(drawnRoot) isEqual:@"原始完整分析\n"] && legacy.subviews.count==0,@"legacy custom-drawn markdown captures exact shadow-node source without UILabel scanning");
    legacy.hidden=YES;check(!DGGeminiReadSummary(drawnRoot).length,@"hidden custom-drawn renderer is still excluded");legacy.hidden=NO;
    UIView *zeroWrapper=[[UIView alloc] initWithFrame:CGRectZero];[legacy removeFromSuperview];[zeroWrapper addSubview:legacy];[drawnRoot addSubview:zeroWrapper];
    check([DGGeminiReadSummary(drawnRoot) isEqual:@"原始完整分析\n"],@"zero-size unclipped wrappers do not hide their visible AI renderer descendants");zeroWrapper.clipsToBounds=YES;check(!DGGeminiReadSummary(drawnRoot).length,@"clipped zero-size AI wrappers still exclude invisible content");
    zeroWrapper.frame=CGRectMake(0,200,300,40);legacy.frame=CGRectMake(0,-200,300,100);check(!DGGeminiReadSummary(drawnRoot).length,@"AI renderer inside root but outside its clipping ancestor is not captured as visible analysis");
    ServalMarkdownView *markdown=[[ServalMarkdownView alloc] initWithFrame:CGRectMake(12,100,width-24,180)];markdown.content=@"内容由AI生成。这个视频讨论摄影技巧。";[ai.view addSubview:markdown];
    UILabel *privateComment=label(ai.view,@"This unrelated comment must not be sent to Google",300);
    UILabel *aiTabs=label(ai.view,@"Bình luận     Phân tích AI",62);aiTabs.frame=CGRectMake(12,62,width-24,32);aiTabs.font=[UIFont boldSystemFontOfSize:18];
    check(atomic_load(&translationRequests)==0 && ![DGGeminiSnapshot()[@"translation_active"] boolValue],@"creating comments controller without AI-tab entry never starts translation");
    [ai commentAIParseTabDidEnter];[ai commentAIParseTabDidEnter];
    check(ai.nativeEntries==2 && findID(ai.view,@"gemini-comment-entry")!=nil,@"comment-AI entry calls native lifecycle once per entry");
    NSUInteger entries=0;for (UIView *view in ai.view.subviews) if ([view.accessibilityIdentifier isEqualToString:@"gemini-comment-entry"]) ++entries;
    check(entries==1,@"Gemini entry does not stack duplicate controls");
    NSString *captured=DGGeminiReadSummary(ai.view);
    check([captured isEqualToString:markdown.content] && ![captured containsString:privateComment.text],@"summary extraction reads only the markdown renderer and preserves its source");
    markdown.hidden=YES;check(DGGeminiReadSummary(ai.view).length==0,@"hidden analysis is not captured");markdown.hidden=NO;
    NSTimeInterval translationTime=NSProcessInfo.processInfo.systemUptime;
    DGGeminiTranslationFixtureTick(ai,translationTime);check(atomic_load(&translationRequests)==0,@"entry waits for source stability without an immediate API charge");
    check(((UITextView *)findID(ai.view,@"gemini-translation-text")).hidden && [findID(ai.view,@"gemini-translation-panel") hitTest:CGPointMake(100,200) withEvent:nil]==nil,@"original analysis remains visible and scrollable while capture or translation is pending");
    DGGeminiTranslationFixtureTick(ai,translationTime+0.75);DGGeminiTranslationFixtureTick(ai,translationTime+1);
    UITextView *viText=(UITextView *)findID(ai.view,@"gemini-translation-text");
    NSDate *translationDeadline=[NSDate dateWithTimeIntervalSinceNow:5];
    while (![viText.text containsString:@"kỹ thuật chụp ảnh"] && translationDeadline.timeIntervalSinceNow>0) [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
    NSLog(@"Translation mock observation: requests=%d, ready=%d",atomic_load(&translationRequests),[viText.text containsString:@"kỹ thuật chụp ảnh"]);
    check(atomic_load(&translationRequests)==1 && [viText.text containsString:@"kỹ thuật chụp ảnh"],@"explicit AI entry translates exactly once through isolated mock transport");
    check(![viText.text containsString:@"<mark"] && ![viText.text containsString:@"</mark>"],@"translated AI highlights preserve text without displaying HTML mark tags");
    [ai.view layoutIfNeeded];
    UIView *viPanel=findID(ai.view,@"gemini-translation-panel");
    check(!viPanel.hidden && viText.frame.size.height>200 && CGRectGetMaxY(viPanel.frame)<=CGRectGetMinY(findID(ai.view,@"gemini-comment-entry").frame),@"Vietnamese analysis scroll panel fits above Q&A button");
    check([DGGeminiReadSummary(ai.view) isEqual:captured] && [markdown.content isEqual:captured],@"translated overlay never replaces or contaminates original Q&A context");
    check([viText.text containsString:@"kỹ thuật chụp ảnh"],@"empty contentVC falls back to actual owner renderer and produces translation");
    [self saveWindowImage:@"ui-gemini-translation.png"];
    UISegmentedControl *language=(UISegmentedControl *)findID(ai.view,@"gemini-translation-language");language.selectedSegmentIndex=1;[language sendActionsForControlEvents:UIControlEventValueChanged];
    check(viText.hidden && [viPanel hitTest:CGPointMake(100,200) withEvent:nil]==nil,@"original toggle restores native content and passes scrolling touches through overlay");
    language.selectedSegmentIndex=0;[language sendActionsForControlEvents:UIControlEventValueChanged];check(!viText.hidden && atomic_load(&translationRequests)==1,@"toggling Vietnamese does not charge another request");
    [ai commentAIParseTabWillLeave];check(findID(ai.view,@"gemini-comment-entry").hidden,@"Gemini entry hides on AI-tab leave");
    DGGeminiTranslationFixtureTick(ai,translationTime+12);check(viPanel.hidden && ![DGGeminiSnapshot()[@"translation_active"] boolValue] && atomic_load(&translationRequests)==1,@"leaving AI stops polling and hides translation");
    [ai commentAIParseTabDidEnter];translationTime=NSProcessInfo.processInfo.systemUptime;DGGeminiTranslationFixtureTick(ai,translationTime);DGGeminiTranslationFixtureTick(ai,translationTime+4);
    check(atomic_load(&translationRequests)==1 && [((UILabel *)findID(ai.view,@"gemini-translation-status")).text containsString:@"Không gọi API lại"],@"same analysis reopening shows persistent cache without billing");
    [NSNotificationCenter.defaultCenter postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
    check(viPanel.hidden && ![DGGeminiSnapshot()[@"translation_active"] boolValue],@"backgrounding stops automatic translation activity");
    [NSNotificationCenter.defaultCenter postNotificationName:UIApplicationDidBecomeActiveNotification object:nil];translationTime=NSProcessInfo.processInfo.systemUptime;DGGeminiTranslationFixtureTick(ai,translationTime);DGGeminiTranslationFixtureTick(ai,translationTime+4);
    check(!viPanel.hidden && atomic_load(&translationRequests)==1,@"returning to an explicitly opened AI tab restores cached translation without billing");
    [ai commentAIParseTabWillLeave];DGGeminiTranslationFixtureTimers(YES);[ai commentAIParseTabDidEnter];
    NSDate *trackingDeadline=[NSDate dateWithTimeIntervalSinceNow:2];
    UILabel *translationStatus=(UILabel *)findID(ai.view,@"gemini-translation-status");
    while (![translationStatus.text containsString:@"Không gọi API lại"] && trackingDeadline.timeIntervalSinceNow>0) [NSRunLoop.currentRunLoop runMode:UITrackingRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    check([translationStatus.text containsString:@"Không gọi API lại"] && atomic_load(&translationRequests)==1,@"real common-mode timer captures cached analysis while UIKit is in scroll tracking mode");
    [ai commentAIParseTabWillLeave];DGGeminiTranslationFixtureTimers(NO);
    [ai commentAIParseTabWillLeave];markdown.content=@"新的分析\n";[ai commentAIParseTabDidEnter];translationTime=NSProcessInfo.processInfo.systemUptime;DGGeminiTranslationFixtureTick(ai,translationTime);DGGeminiTranslationFixtureTick(ai,translationTime+4);
    [ai viewWillDisappear:NO];[ai viewDidAppear:NO];translationTime=NSProcessInfo.processInfo.systemUptime;DGGeminiTranslationFixtureTick(ai,translationTime);DGGeminiTranslationFixtureTick(ai,translationTime+4);
    check([((UILabel *)findID(ai.view,@"gemini-translation-status")).text containsString:@"Yêu cầu trước đã dừng"],@"returning after cancelling a sent request does not automatically spend a second request in same tab entry");
    markdown.content=captured;
    [ai commentAIParseTabWillLeave];
    [NSUserDefaults.standardUserDefaults setBool:YES forKey:@"DGGeminiDisabled"];
    int requestsBeforeOff=atomic_load(&translationRequests);[ai commentAIParseTabDidEnter];DGGeminiTranslationFixtureTick(ai,translationTime+20);check(atomic_load(&translationRequests)==requestsBeforeOff && viPanel.hidden,@"Gemini OFF cannot auto-translate on tab entry");[ai commentAIParseTabWillLeave];
    AWESearchAIGCQueryContext *queryContext=[AWESearchAIGCQueryContext new];queryContext.query=@"Dịch giúp tôi";
    [ai inputViewSendQueryContext:queryContext sourceFrom:0];
    check(ai.nativeSends==1 && !ai.presentedViewController,@"Gemini OFF retains original submit policy without taking over");
    AWEFeedDoubleColumnAIParseViewController *otherAI=[AWEFeedDoubleColumnAIParseViewController new];[otherAI inputViewSendQueryContext:queryContext sourceFrom:0];
    check(otherAI.nativeSends==1,@"other AI screens are not routed to Gemini");
    [NSUserDefaults.standardUserDefaults setBool:NO forKey:@"DGGeminiDisabled"];
    [ai inputViewSendQueryContext:queryContext sourceFrom:0];
    UINavigationController *routed=[ai.capturedPresentation isKindOfClass:UINavigationController.class] ? (UINavigationController *)ai.capturedPresentation : nil;
    [routed.topViewController loadViewIfNeeded];
    UITextView *routedInput=(UITextView *)findID(routed.topViewController.view,@"gemini-input");
    check(ai.nativeSends==1 && [routed.topViewController isKindOfClass:DGGeminiChatController.class] && [routedInput.text isEqualToString:queryContext.query],@"enabled native submit routes a draft to Gemini without calling native login or sending it automatically");
    check(![NSJSONSerialization JSONObjectWithData:[NSJSONSerialization dataWithJSONObject:DGGeminiSnapshot() options:0 error:NULL] options:0 error:NULL][@"api_key"],@"Gemini diagnostics do not expose the configured key");
    DGGeminiChatController *gemini=[[DGGeminiChatController alloc] initWithSummary:captured question:queryContext.query];
    UINavigationController *geminiNav=[[UINavigationController alloc] initWithRootViewController:gemini];
    self.window.rootViewController=geminiNav;[self.window layoutIfNeeded];[gemini.view layoutIfNeeded];
    UITextView *input=(UITextView *)findID(gemini.view,@"gemini-input");UILabel *notice=(UILabel *)findID(gemini.view,@"gemini-notice");
    check([input.text isEqualToString:queryContext.query] && [notice.text containsString:@"Google Gemini"] && [notice.text containsString:@"Context:"],@"Gemini draft identifies Google and the captured context without auto-sending");
    check(CGRectGetMaxY(input.frame)<=gemini.view.bounds.size.height && input.frame.size.width>150,@"Gemini multiline input and Send fit portrait safe area");
    [self saveWindowImage:@"ui-gemini.png"];
    [gemini mode];check([notice.text containsString:@"Fast"],@"Fast mode updates model disclosure");[gemini mode];
    [gemini context];[geminiNav.view layoutIfNeeded];
    UITextView *contextText=(UITextView *)findID(geminiNav.topViewController.view,@"gemini-context");
    check([contextText.text isEqualToString:captured] && contextText.editable,@"captured context can be reviewed and edited separately from Douyin's analysis");
    [self saveWindowImage:@"ui-gemini-context.png"];
    check([markdown.content isEqualToString:captured],@"Gemini UI does not rewrite original Douyin analysis");
    AWEFeedDoubleColumnCommentAIParseViewController *webAI=[AWEFeedDoubleColumnCommentAIParseViewController new];self.window.rootViewController=webAI;webAI.view.backgroundColor=UIColor.systemBackgroundColor;
    webAI.contentVC=[UIViewController new];[webAI addChildViewController:webAI.contentVC];webAI.contentVC.view.frame=webAI.view.bounds;[webAI.view addSubview:webAI.contentVC.view];[webAI.contentVC didMoveToParentViewController:webAI];
    WKWebView *web=[[WKWebView alloc] initWithFrame:CGRectMake(12,100,width-24,300)];[webAI.contentVC.view addSubview:web];[web loadHTMLString:@"<html><body><article>这是独立的网页分析内容。</article></body></html>" baseURL:nil];mediaWait(^BOOL{return !web.loading;});
    DGGeminiTranslationFixtureConfiguration(translationMock,nil);int beforeWeb=atomic_load(&translationRequests);[webAI commentAIParseTabDidEnter];
    mediaWait(^BOOL {DGGeminiTranslationFixtureTick(webAI,NSProcessInfo.processInfo.systemUptime+4);return atomic_load(&translationRequests)>beforeWeb && [((UITextView *)findID(webAI.view,@"gemini-translation-text")).text containsString:@"kỹ thuật chụp ảnh"];});
    check(atomic_load(&translationRequests)==beforeWeb+1 && [((UITextView *)findID(webAI.view,@"gemini-translation-text")).text containsString:@"kỹ thuật chụp ảnh"],@"scoped web-rendered analysis translates through Claude without requiring Markdown native labels");[webAI commentAIParseTabWillLeave];
    [web removeFromSuperview];UILabel *drawnText=[[UILabel alloc] initWithFrame:CGRectMake(16,140,width-32,120)];drawnText.font=[UIFont systemFontOfSize:28];drawnText.numberOfLines=0;drawnText.text=@"这是屏幕上显示的中文分析内容。";[webAI.contentVC.view addSubview:drawnText];[self.window layoutIfNeeded];
    [self saveWindowImage:@"ui-ai-ocr-source.png"];
    DGGeminiTranslationFixtureConfiguration(translationMock,nil);int beforeOCR=atomic_load(&translationRequests);[webAI commentAIParseTabDidEnter];
    NSDate *ocrDeadline=[NSDate dateWithTimeIntervalSinceNow:45];while (atomic_load(&translationRequests)==beforeOCR && ocrDeadline.timeIntervalSinceNow>0) {DGGeminiTranslationFixtureTick(webAI,NSProcessInfo.processInfo.systemUptime+4);[NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];}
    mediaWait(^BOOL {return [((UITextView *)findID(webAI.view,@"gemini-translation-text")).text containsString:@"kỹ thuật chụp ảnh"];});
    check(atomic_load(&translationRequests)==beforeOCR+1 && [((UILabel *)findID(webAI.view,@"gemini-translation-status")).text containsString:@"đang hiển thị"],@"local Chinese OCR waits for matching captures then translates visible AI content without image upload");[webAI commentAIParseTabWillLeave];
    drawnText.text=@"这是另一个尚未翻译的分析。";DGGeminiTranslationFixtureConfiguration(translationMock,nil);int beforeStaleOCR=atomic_load(&translationRequests);[webAI commentAIParseTabDidEnter];DGGeminiTranslationFixtureTick(webAI,NSProcessInfo.processInfo.systemUptime+4);[webAI commentAIParseTabWillLeave];[NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    check(atomic_load(&translationRequests)==beforeStaleOCR,@"leaving AI rejects in-flight OCR and cannot spend a stale translation request");
    }
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
    // Run from a run-loop timer, not inside a main-queue dispatch block. The async
    // provider completion dispatches to main; nesting a run loop inside that queue
    // would prevent the queued completion from running until all assertions finished.
    [NSTimer scheduledTimerWithTimeInterval:2 repeats:NO block:^(__unused NSTimer *timer) {[self runCases];}];
    return YES;
}
- (void)runCases {
    UIView *parent=self.host.view;
    AWEAwemeBackgroundPlayStoreService *store=[AWEAwemeBackgroundPlayStoreService new];store.originalAudio=2;store.originalScene=2;
    check(store.switchState && store.audioSwitchState==1 && store.audioSceneState==1 && !store.originalSwitch && store.originalAudio==2 && store.originalScene==2,@"default Background audio applies only native preference getters without overwriting original values");
    _TtC16AWELiveSwiftImpl21AWEFeedLiveTabTagView *liveTabs=[[_TtC16AWELiveSwiftImpl21AWEFeedLiveTabTagView alloc] initWithFrame:CGRectMake(10,600,360,40)];[parent addSubview:liveTabs];
    NSArray *liveCN=@[@"明星",@"聊天",@"唱歌",@"团播",@"颜值"], *liveEN=@[@"Stars",@"Chat",@"Singing",@"Groups",@"Beauty"];
    for (NSUInteger i=0;i<liveCN.count;i++) {
        UILabel *tab=label(liveTabs,liveCN[i],0);tab.frame=CGRectMake(i*70,0,63,32);[tab layoutIfNeeded];
        CGFloat needed=[tab.text sizeWithAttributes:@{NSFontAttributeName:tab.font}].width;
        check([tab.text isEqual:liveEN[i]] && needed*tab.minimumScaleFactor<=tab.bounds.size.width,@"LIVE category translates and fits narrow label");
        tab.frame=CGRectMake(i*70,0,32,32);[tab setNeedsLayout];[tab layoutIfNeeded];
        needed=[tab.text sizeWithAttributes:@{NSFontAttributeName:tab.font}].width;
        check(needed*0.65<=32,@"LIVE category has a readable compact option at 32 points");
        tab.frame=CGRectMake(i*70,0,63,32);[tab setNeedsLayout];[tab layoutIfNeeded];
        check([tab.text isEqual:liveEN[i]],@"LIVE category restores full label when width grows");
    }
    HTSLiveRoomTitleFixtureView *liveRoom=[[HTSLiveRoomTitleFixtureView alloc] initWithFrame:CGRectMake(0,0,180,35)];[parent addSubview:liveRoom];
    HTSLiveChatFixtureView *liveChat=[[HTSLiveChatFixtureView alloc] initWithFrame:CGRectMake(0,0,180,35)];[parent addSubview:liveChat];
    UILabel *protectedRoom=label(liveRoom,@"明星",0), *protectedChat=label(liveChat,@"聊天",0);
    [parent layoutIfNeeded];check([protectedRoom.text isEqual:@"明星"] && [protectedChat.text isEqual:@"聊天"],@"exact LIVE category words are preserved in user room/chat content");
    UILabel *reused=liveTabs.subviews.firstObject;[reused removeFromSuperview];[liveChat addSubview:reused];reused.text=@"唱歌";[reused layoutIfNeeded];
    check([reused.text isEqual:@"唱歌"] && !reused.adjustsFontSizeToFitWidth,@"LIVE label reuse into chat restores original text fitting");
    [liveTabs removeFromSuperview];[liveRoom removeFromSuperview];[liveChat removeFromSuperview];
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
    input.placeholder=@"问AI或按住说话";input.text=@"山螃蟹怎么做好吃？";
    check([input.placeholder isEqualToString:@"Ask AI or hold to speak"] && [input.text isEqualToString:@"山螃蟹怎么做好吃？"],
        @"AI input placeholder translates without altering the user's question");
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
    emptyConfig.linkRange=NSMakeRange(0,2);
    check([emptyConfig.informativeText isEqualToString:@"请检查网络连接后重试"],@"empty config with a separate character link range preserves its source text and action span");
    emptyConfig.linkRange=NSMakeRange(0,0);
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
    UILabel *aiNotice=label(realHeader,@"内容由AI生成，仅供参考",60);aiNotice.frame=CGRectMake(4,60,250,28);
    [aiNotice layoutIfNeeded];check([aiNotice.text isEqualToString:@"AI-generated. For reference only."],
        @"AI chrome disclaimer translates in an explicitly identified header");
    aiNotice.frame=CGRectMake(4,60,120,28);[aiNotice setNeedsLayout];[aiNotice layoutIfNeeded];
    check([aiNotice.text isEqualToString:@"AI; reference only"] &&
          [aiNotice.text sizeWithAttributes:@{NSFontAttributeName:aiNotice.font}].width*aiNotice.minimumScaleFactor<=120,
          @"AI disclaimer preserves reference-only meaning in a narrow control");
    aiNotice.frame=CGRectMake(4,60,250,28);[aiNotice setNeedsLayout];[aiNotice layoutIfNeeded];
    check([aiNotice.text isEqualToString:@"AI-generated. For reference only."],@"AI disclaimer restores complete English text when widened");
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
    check([evaluation.receivedConfig[@"ratingPointDes"] isEqualToString:@"Very unhappy,Unhappy,Neutral,Happy,Very happy"] &&
        [evaluation.receivedConfig[@"bizParams"][@"text"] isEqualToString:@"一般"],@"Lynx evaluation config translates proven rating fields while arbitrary nested payload stays original");
    AWECommentSurveyCell *ratingGroup=[[AWECommentSurveyCell alloc] initWithFrame:CGRectMake(0,0,341,70)];[commentContainer addSubview:ratingGroup];
    BOOL ratingFit=YES;
    for (NSString *source in @[@"非常不满意",@"不满意",@"一般",@"满意",@"非常满意"]) {
        UILabel *option=label(ratingGroup,source,0);option.frame=CGRectMake(0,0,64.2,54);option.font=[UIFont systemFontOfSize:12];option.numberOfLines=2;
        CGSize size=[option.text boundingRectWithSize:CGSizeMake(64.2,CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin
            attributes:@{NSFontAttributeName:option.font} context:nil].size;
        if (size.height>54 || [option.text containsString:@"…"]) ratingFit=NO;
        for (NSString *word in [option.text componentsSeparatedByString:@" "])
            if ([word sizeWithAttributes:@{NSFontAttributeName:option.font}].width>64.2) ratingFit=NO;
    }
    check(ratingFit,@"five survey ratings fit actual 64.2pt columns at 12pt without splitting a word or ellipsis");
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
        check([sheet isKindOfClass:UIAlertController.class] && [sheet.title isEqualToString:@"Douyin"],@"diagnostics sheet can actually be presented on legacy window");
        check(sheet.actions.count==13,@"settings expose six switches, GTX fallback, Gemini actions, two public web actions, copy and close");
        check([sheet.actions[5].title isEqualToString:@"Feed compatibility: ON"],@"feed transport compatibility is exposed and enabled by default");
        [self saveWindowImage:@"ui-feed-compat.png"];
        [sheet dismissViewControllerAnimated:NO completion:^{
          [[DGSettings shared] presentPublicFinder:self.navigation profileLink:NO];
          dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC),dispatch_get_main_queue(),^{
            UIAlertController *finder=(UIAlertController *)self.navigation.presentedViewController;
            check([finder isKindOfClass:UIAlertController.class] && [finder.title isEqualToString:@"Find public profiles"] && finder.textFields.count==1 && finder.actions.count==2,
                @"public finder presents a native name-entry prompt without making a network request");
            check([finder.message containsString:@"Bing"] && [finder.message containsString:@"may vary"],@"public finder identifies the destination and guest availability limits");
            [self saveWindowImage:@"ui-public-finder.png"];
            [finder dismissViewControllerAnimated:NO completion:^{
              [[DGSettings shared] presentPublicFinder:self.navigation profileLink:YES];
              dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC),dispatch_get_main_queue(),^{
                UIAlertController *linkPrompt=(UIAlertController *)self.navigation.presentedViewController;
                check([linkPrompt.title isEqualToString:@"Open public profile"] && linkPrompt.textFields.firstObject.keyboardType==UIKeyboardTypeURL,
                    @"profile-link prompt uses the URL keyboard and official-link wording");
                [self saveWindowImage:@"ui-public-profile.png"];
                [linkPrompt dismissViewControllerAnimated:NO completion:^{
        // This final visual/async section is reached from dispatch-based modal
        // callbacks, even when runCases itself starts from a timer.
        [NSTimer scheduledTimerWithTimeInterval:0.05 repeats:NO block:^(__unused NSTimer *timer) {
        [self showVisualSamples];
        [self showMediaSamples];
        BOOL success=YES; for (NSDictionary *item in checks) if (![item[@"passed"] boolValue]) success=NO;
        NSDictionary *report=@{@"scope":@"UIKit fixture only; original Douyin app and network were not executed",@"ios":UIDevice.currentDevice.systemVersion,@"device":UIDevice.currentDevice.model,@"checks":checks,@"passed":@(success),@"count":@(checks.count),@"fitting_observation":fittingObservation,@"overflow_labels":overflowLabels,@"translation_entries_tested":@(words.count)};
        NSData *result=[NSJSONSerialization dataWithJSONObject:report options:NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys error:NULL];
        NSURL *documents=[NSFileManager.defaultManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
        [result writeToURL:[documents URLByAppendingPathComponent:@"ui-results.json"] atomically:YES];
        NSLog(@"UI fixture finished: %@",success ? @"PASS" : @"FAIL");
        }];
                }];
              });
            }];
          });
        }];
    });
}
@end

int main(int argc,char **argv) {
    @autoreleasepool { return UIApplicationMain(argc,argv,nil,NSStringFromClass(FixtureDelegate.class)); }
}
