#import "DGMediaUI.h"
#import "DGMedia.h"
#import <objc/runtime.h>
#include <math.h>

static NSDictionary *DGMediaConfig,*DGMediaGemini;
static DGTranslationStore *DGMediaCache;
static NSURLSessionConfiguration *DGMediaConfiguration;
static void (^DGMediaRecord)(NSString *,NSUInteger);
static NSMutableSet *DGMediaHooks;
static char DGCaptionKey,DGCommentKey;
static NSString *const DGNativeCommentLabel=@"_TtC28AWECommentPanelListSwiftImpl20BaseCellCommentLabel";
static void DGMediaCount(NSString *name) {if (DGMediaRecord) DGMediaRecord(name,1);}
static id DGMediaGetter(id object,NSString *name) {
    SEL selector=NSSelectorFromString(name);Method method=class_getInstanceMethod(object_getClass(object),selector);
    if (!method || strcmp(method_getTypeEncoding(method),"@16@0:8")) return nil;
    @try {return ((id (*)(id,SEL))method_getImplementation(method))(object,selector);}@catch (__unused NSException *error) {return nil;}
}
static NSString *DGVideoID(UIViewController *owner) {
    id model=DGMediaGetter(owner,@"model");Class cls=NSClassFromString(@"AWEAwemeModel");
    if (!cls || ![model isKindOfClass:cls]) return nil;id identifier=DGMediaGetter(model,@"itemID");
    return [identifier isKindOfClass:NSString.class] && DGCaptionVideoURL(identifier) ? identifier : nil;
}
static NSDictionary *DGMediaResource(NSString *name) {
    NSURL *url=[NSBundle.mainBundle URLForResource:name withExtension:@"json" subdirectory:@"DouyinGuest.bundle"];
    NSData *data=url ? [NSData dataWithContentsOfURL:url] : nil;id root=data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL] : nil;return [root isKindOfClass:NSDictionary.class] ? root : @{};
}
static DGMediaClient *DGNewMediaClient(void) {
    if (!DGMediaCache) {
        NSURL *base=[NSFileManager.defaultManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject;
        DGMediaCache=[[DGCaptionStore alloc] initWithURL:[base URLByAppendingPathComponent:@"DouyinGuest/media-vi-v1.json"]];
    }
    DGMediaClient *client=[[DGMediaClient alloc] initWithConfig:DGMediaConfig geminiKey:DGMediaGemini[@"api_key"] store:DGMediaCache configuration:DGMediaConfiguration];
    client.event=^(NSString *name) {DGMediaCount(name);};return client;
}
NSArray *DGMediaReadVisibleComments(UIView *root) {
    if (!root || !NSThread.isMainThread) return @[];Class label=NSClassFromString(DGNativeCommentLabel);
    if (!label) return @[];NSMutableArray *pending=[NSMutableArray arrayWithObject:root],*comments=[NSMutableArray new];NSMutableSet *seen=[NSMutableSet new];NSUInteger visited=0;
    while (pending.count && visited++<1200 && comments.count<50) {
        UIView *node=pending.lastObject;[pending removeLastObject];
        if (node.hidden || node.alpha<0.01 || !CGRectIntersectsRect([node convertRect:node.bounds toView:root],root.bounds)) continue;
        if ([node isKindOfClass:label]) {
            id attributed=DGMediaGetter(node,@"attributedText"),text=DGMediaGetter(node,@"text");
            NSString *source=[attributed isKindOfClass:NSAttributedString.class] ? [attributed string] : [text isKindOfClass:NSString.class] ? text : nil;
            if (source.length && source.length<=2000 && ![seen containsObject:source]) {[comments addObject:source];[seen addObject:source];}continue;
        }
        for (UIView *child in node.subviews.reverseObjectEnumerator) [pending addObject:child];
    }return comments;
}
@interface DGCommentTranslations : UITableViewController
@property(nonatomic,strong) NSArray *comments;
@property(nonatomic,strong) NSMutableDictionary *answers;
@property(nonatomic,strong) DGMediaClient *client;
@property(nonatomic,strong) NSNumber *loading;
@end
@implementation DGCommentTranslations
- (void)viewDidLoad {
    [super viewDidLoad];self.title=@"Dịch bình luận · GTX";self.answers=[NSMutableDictionary new];self.client=DGNewMediaClient();self.tableView.accessibilityIdentifier=@"gtx-comments-table";
    self.tableView.rowHeight=UITableViewAutomaticDimension;self.tableView.estimatedRowHeight=100;
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@"Đóng" style:UIBarButtonItemStyleDone target:self action:@selector(close)];
    UILabel *note=[[UILabel alloc] initWithFrame:CGRectMake(0,0,320,76)];note.numberOfLines=0;note.font=[UIFont systemFontOfSize:13];note.textAlignment=NSTextAlignmentCenter;
    note.text=self.comments.count ? @"Chạm bình luận để dịch sang tiếng Việt.\nChỉ chữ bình luận được gửi tới Google Translate GTX.\nBình luận gốc giữ nguyên." : @"Chưa đọc được bình luận đang hiển thị.\nĐóng, cuộn tới bình luận rồi mở lại.";self.tableView.tableHeaderView=note;
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(stop) name:UIApplicationDidEnterBackgroundNotification object:nil];
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {(void)tableView;(void)section;return self.comments.count;}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)path {
    UITableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:@"comment"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"comment"];
    cell.textLabel.numberOfLines=0;cell.textLabel.font=[UIFont systemFontOfSize:15];cell.textLabel.text=self.comments[path.row];cell.detailTextLabel.numberOfLines=0;cell.detailTextLabel.font=[UIFont systemFontOfSize:15];cell.detailTextLabel.textColor=UIColor.systemBlueColor;
    cell.detailTextLabel.text=[self.loading isEqual:@(path.row)] ? @"Đang dịch…" : self.answers[@(path.row)] ?: @"Chạm để dịch tiếng Việt";return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)path {
    [tableView deselectRowAtIndexPath:path animated:YES];if (self.loading || path.row>=self.comments.count) return;
    NSNumber *row=@(path.row);self.loading=row;[tableView reloadData];DGMediaCount(@"GTX comment selected");__weak DGCommentTranslations *weakSelf=self;
    [self.client translateComment:self.comments[path.row] completion:^(NSString *answer,NSString *failure) {
        DGCommentTranslations *owner=weakSelf;if (!owner || !owner.view.window) return;owner.loading=nil;owner.answers[row]=answer ?: failure;[owner.tableView reloadData];DGMediaCount(answer ? @"GTX ready" : @"GTX failed");
    }];
}
- (void)stop {[self.client cancel];self.loading=nil;if (self.isViewLoaded) [self.tableView reloadData];}
- (void)close {[self stop];[self dismissViewControllerAnimated:YES completion:nil];}
- (void)viewWillDisappear:(BOOL)animated {[super viewWillDisappear:animated];[self stop];}
- (void)dealloc {[_client cancel];[NSNotificationCenter.defaultCenter removeObserver:self];}
@end
@interface DGCommentEntry : NSObject
@property(nonatomic,weak) UIViewController *owner;
@property(nonatomic,strong) UIButton *button;
- (void)open;
@end
@implementation DGCommentEntry
- (void)open {
    if (!self.owner.view.window || self.owner.presentedViewController) return;DGCommentTranslations *sheet=[DGCommentTranslations new];sheet.comments=DGMediaReadVisibleComments(self.owner.view);
    [self.owner presentViewController:[[UINavigationController alloc] initWithRootViewController:sheet] animated:YES completion:nil];DGMediaCount(sheet.comments.count ? @"GTX visible comments captured" : @"GTX visible comments unavailable");
}
@end
@interface DGCaptionEntry : NSObject
@property(nonatomic,weak) UIViewController *owner;
@property(nonatomic,strong) UIButton *button;
@property(nonatomic,strong) UILabel *status;
@property(nonatomic,strong) UILabel *caption;
@property(nonatomic,strong) DGMediaClient *client;
@property(nonatomic,strong) NSTimer *timer;
@property(nonatomic,copy) NSString *videoID;
@property(nonatomic,strong) NSArray *cues;
@property(nonatomic) BOOL showing;
@property(nonatomic) BOOL running;
- (void)open;
- (void)stop;
- (void)tick;
@end
static __weak DGCaptionEntry *DGActiveCaption;
@implementation DGCaptionEntry
- (void)open {
    if (!self.owner.view.window || self.owner.view.hidden) return;
    if (self.running) {[self stop];self.status.text=@"Đã hủy · Không tự thử lại";return;}
    if (self.showing) {self.showing=NO;self.caption.hidden=YES;[self.timer invalidate];self.timer=nil;[self.button setTitle:@"Hiện phụ đề Việt" forState:UIControlStateNormal];return;}
    NSString *identifier=DGVideoID(self.owner);
    if (!identifier) {self.status.text=@"Chưa đọc được ID video đang xem.";DGMediaCount(@"Captions video ID unavailable");return;}
    if (DGActiveCaption!=self) [DGActiveCaption stop];DGActiveCaption=self;
    self.videoID=identifier;self.showing=YES;self.running=YES;self.cues=@[];self.client=DGNewMediaClient();[self.button setTitle:@"Hủy phụ đề" forState:UIControlStateNormal];
    self.timer=[NSTimer timerWithTimeInterval:0.1 repeats:YES block:^(__unused NSTimer *timer) {[DGActiveCaption tick];}];[NSRunLoop.mainRunLoop addTimer:self.timer forMode:NSRunLoopCommonModes];
    __weak DGCaptionEntry *weakSelf=self;
    self.client.update=^(NSString *stage,NSArray *cues,NSString *failure) {
        DGCaptionEntry *entry=weakSelf;if (!entry || !entry.showing || !entry.owner.view.window || ![entry.videoID isEqual:DGVideoID(entry.owner)]) {[entry stop];return;}
        entry.cues=cues;entry.running=!([stage isEqual:@"ready"] || [stage isEqual:@"cached"] || [stage isEqual:@"failed"]);
        entry.status.text=[stage isEqual:@"apify"] ? @"Đang lấy video · Apify" : [stage isEqual:@"deepgram"] ? @"Đang nhận dạng tiếng Trung · Nova-3" : [stage isEqual:@"gemini"] ? @"Đang dịch phụ đề · Gemini" : [stage isEqual:@"partial"] ? @"Đã có một phần phụ đề · đang dịch tiếp" : [stage isEqual:@"cached"] ? @"Phụ đề đã lưu · không gọi API lại" : [stage isEqual:@"ready"] ? @"Phụ đề Việt đã sẵn sàng" : failure;
        [entry.button setTitle:entry.running ? @"Hủy phụ đề" : [stage isEqual:@"failed"] ? @"Thử lại phụ đề" : @"Tắt phụ đề Việt" forState:UIControlStateNormal];
        if ([stage isEqual:@"failed"]) {entry.showing=NO;[entry.timer invalidate];entry.timer=nil;}
        DGMediaCount([@"Captions stage " stringByAppendingString:stage]);[entry tick];
    };
    SEL timeSelector=NSSelectorFromString(@"currentPlaybackTime");Method timeMethod=class_getInstanceMethod(object_getClass(self.owner),timeSelector);
    double time=timeMethod && !strcmp(method_getTypeEncoding(timeMethod),"d16@0:8") ? ((double (*)(id,SEL))method_getImplementation(timeMethod))(self.owner,timeSelector) : 0;
    DGMediaCount(@"Captions opt-in");[self.client startVideo:identifier at:time];
}
- (void)tick {
    if (!self.owner.view.window || self.owner.view.hidden || UIApplication.sharedApplication.applicationState!=UIApplicationStateActive || ![self.videoID isEqual:DGVideoID(self.owner)]) {[self stop];return;}
    SEL selector=NSSelectorFromString(@"currentPlaybackTime");Method method=class_getInstanceMethod(object_getClass(self.owner),selector);
    if (!self.showing || !method || strcmp(method_getTypeEncoding(method),"d16@0:8")) {self.caption.hidden=YES;return;}
    NSTimeInterval time=((double (*)(id,SEL))method_getImplementation(method))(self.owner,selector);if (self.running) [self.client prioritizeTime:time];NSString *text=DGCaptionTextAt(self.cues,time);
    self.caption.hidden=!text.length;if (![self.caption.text isEqual:text]) self.caption.text=text;
}
- (void)stop {
    [self.client cancel];self.client=nil;[self.timer invalidate];self.timer=nil;self.running=NO;self.showing=NO;self.caption.hidden=YES;self.cues=@[];self.status.text=@"";[self.button setTitle:@"Phụ đề Việt" forState:UIControlStateNormal];
}
- (void)dealloc {[_client cancel];[_timer invalidate];[NSNotificationCenter.defaultCenter removeObserver:self];}
@end
static void DGAttachCaption(UIViewController *owner) {
    DGCaptionEntry *entry=objc_getAssociatedObject(owner,&DGCaptionKey);
    if (!entry) {
        entry=[DGCaptionEntry new];entry.owner=owner;entry.button=[UIButton buttonWithType:UIButtonTypeSystem];entry.button.accessibilityIdentifier=@"vietnamese-captions-button";[entry.button setTitle:@"Phụ đề Việt" forState:UIControlStateNormal];[entry.button addTarget:entry action:@selector(open) forControlEvents:UIControlEventTouchUpInside];
        entry.button.backgroundColor=[UIColor.blackColor colorWithAlphaComponent:0.65];entry.button.tintColor=UIColor.whiteColor;entry.button.layer.cornerRadius=12;entry.button.titleLabel.font=[UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        entry.status=[UILabel new];entry.status.accessibilityIdentifier=@"vietnamese-captions-status";entry.status.numberOfLines=0;entry.status.font=[UIFont systemFontOfSize:12];entry.status.textColor=UIColor.whiteColor;entry.status.backgroundColor=[UIColor.blackColor colorWithAlphaComponent:0.5];
        entry.caption=[UILabel new];entry.caption.accessibilityIdentifier=@"vietnamese-captions-text";entry.caption.numberOfLines=0;entry.caption.font=[UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];entry.caption.textAlignment=NSTextAlignmentCenter;entry.caption.textColor=UIColor.whiteColor;entry.caption.backgroundColor=[UIColor.blackColor colorWithAlphaComponent:0.75];entry.caption.layer.cornerRadius=8;entry.caption.clipsToBounds=YES;entry.caption.hidden=YES;
        for (UIView *view in @[entry.button,entry.status,entry.caption]) {view.translatesAutoresizingMaskIntoConstraints=NO;[owner.view addSubview:view];}
        [NSLayoutConstraint activateConstraints:@[[entry.button.topAnchor constraintEqualToAnchor:owner.view.safeAreaLayoutGuide.topAnchor constant:58],[entry.button.leadingAnchor constraintEqualToAnchor:owner.view.safeAreaLayoutGuide.leadingAnchor constant:12],[entry.button.widthAnchor constraintEqualToConstant:156],[entry.button.heightAnchor constraintEqualToConstant:36],
            [entry.status.topAnchor constraintEqualToAnchor:entry.button.bottomAnchor constant:4],[entry.status.leadingAnchor constraintEqualToAnchor:entry.button.leadingAnchor],[entry.status.widthAnchor constraintEqualToConstant:230],
            [entry.caption.leadingAnchor constraintEqualToAnchor:owner.view.safeAreaLayoutGuide.leadingAnchor constant:18],[entry.caption.trailingAnchor constraintEqualToAnchor:owner.view.safeAreaLayoutGuide.trailingAnchor constant:-66],[entry.caption.centerYAnchor constraintEqualToAnchor:owner.view.centerYAnchor constant:90]]];
        objc_setAssociatedObject(owner,&DGCaptionKey,entry,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [NSNotificationCenter.defaultCenter addObserver:entry selector:@selector(stop) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    entry.button.hidden=NO;entry.status.hidden=NO;[owner.view bringSubviewToFront:entry.button];[owner.view bringSubviewToFront:entry.status];[owner.view bringSubviewToFront:entry.caption];
}
static void DGAttachComments(UIViewController *owner) {
    DGCommentEntry *entry=objc_getAssociatedObject(owner,&DGCommentKey);
    if (!entry) {
        entry=[DGCommentEntry new];entry.owner=owner;entry.button=[UIButton buttonWithType:UIButtonTypeSystem];entry.button.accessibilityIdentifier=@"gtx-comments-button";entry.button.backgroundColor=UIColor.secondarySystemBackgroundColor;entry.button.layer.cornerRadius=10;entry.button.titleLabel.font=[UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];[entry.button setTitle:@"Dịch bình luận" forState:UIControlStateNormal];[entry.button addTarget:entry action:@selector(open) forControlEvents:UIControlEventTouchUpInside];entry.button.translatesAutoresizingMaskIntoConstraints=NO;[owner.view addSubview:entry.button];
        [NSLayoutConstraint activateConstraints:@[[entry.button.topAnchor constraintEqualToAnchor:owner.view.safeAreaLayoutGuide.topAnchor constant:50],[entry.button.trailingAnchor constraintEqualToAnchor:owner.view.safeAreaLayoutGuide.trailingAnchor constant:-12],[entry.button.widthAnchor constraintEqualToConstant:132],[entry.button.heightAnchor constraintEqualToConstant:34]]];objc_setAssociatedObject(owner,&DGCommentKey,entry,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }entry.button.hidden=NO;[owner.view bringSubviewToFront:entry.button];
}
static BOOL DGMediaHook(Class cls,NSString *name,NSString *types,id (^factory)(IMP)) {
    NSString *key=[NSString stringWithFormat:@"%@ %@",NSStringFromClass(cls),name];if ([DGMediaHooks containsObject:key]) return YES;
    Method method=class_getInstanceMethod(cls,NSSelectorFromString(name));if (!method || strcmp(method_getTypeEncoding(method),types.UTF8String)) return NO;
    IMP replacement=imp_implementationWithBlock(factory(method_getImplementation(method)));if (!class_addMethod(cls,NSSelectorFromString(name),replacement,types.UTF8String)) class_replaceMethod(cls,NSSelectorFromString(name),replacement,types.UTF8String);[DGMediaHooks addObject:key];return YES;
}
void DGMediaInstall(void (^record)(NSString *,NSUInteger)) {
    DGMediaRecord=[record copy];if (!DGMediaConfig) DGMediaConfig=DGMediaResource(@"media-private");if (!DGMediaGemini) DGMediaGemini=DGMediaResource(@"gemini-private");if (!DGMediaHooks) DGMediaHooks=[NSMutableSet new];
    Class player=NSClassFromString(@"AWEPlayVideoViewController");
    if (player && [player isSubclassOfClass:UIViewController.class]) {
        DGMediaHook(player,@"viewDidAppear:",@"v20@0:8B16",^id(IMP original) {return ^(UIViewController *owner,BOOL animated) {((void (*)(id,SEL,BOOL))original)(owner,@selector(viewDidAppear:),animated);if (NSThread.isMainThread) DGAttachCaption(owner);};});
        DGMediaHook(player,@"viewWillDisappear:",@"v20@0:8B16",^id(IMP original) {return ^(UIViewController *owner,BOOL animated) {DGCaptionEntry *entry=objc_getAssociatedObject(owner,&DGCaptionKey);[entry stop];entry.button.hidden=YES;entry.status.hidden=YES;((void (*)(id,SEL,BOOL))original)(owner,@selector(viewWillDisappear:),animated);};});
        DGMediaHook(player,@"setModel:",@"v24@0:8@16",^id(IMP original) {return ^(UIViewController *owner,id model) {[objc_getAssociatedObject(owner,&DGCaptionKey) stop];((void (*)(id,SEL,id))original)(owner,NSSelectorFromString(@"setModel:"),model);};});
    }
    for (NSString *name in @[@"AWECommentContainerViewController",@"AWECommentFullScreenContainerViewController"]) {
        Class cls=NSClassFromString(name);if (!cls || ![cls isSubclassOfClass:UIViewController.class]) continue;
        DGMediaHook(cls,@"viewDidAppear:",@"v20@0:8B16",^id(IMP original) {return ^(UIViewController *owner,BOOL animated) {((void (*)(id,SEL,BOOL))original)(owner,@selector(viewDidAppear:),animated);if (NSThread.isMainThread) DGAttachComments(owner);};});
        DGMediaHook(cls,@"viewWillDisappear:",@"v20@0:8B16",^id(IMP original) {return ^(UIViewController *owner,BOOL animated) {DGCommentEntry *entry=objc_getAssociatedObject(owner,&DGCommentKey);entry.button.hidden=YES;((void (*)(id,SEL,BOOL))original)(owner,@selector(viewWillDisappear:),animated);};});
    }
}
NSDictionary *DGMediaSnapshot(void) {return @{@"caption_configured":@([DGMediaConfig[@"apify_api_key"] length]>0 && [DGMediaConfig[@"deepgram_api_key"] length]>0 && [DGMediaGemini[@"api_key"] length]>0),@"actor":@"apple_yang/douyin-video-audio-downloader",@"asr_model":@"nova-3",@"source_language":@"zh-CN",@"target_language":@"vi",@"translation_model":@"gemini-3.5-flash-lite",@"hooks_installed":@(DGMediaHooks.count),@"caption_running":@(DGActiveCaption.running),@"caption_showing":@(DGActiveCaption.showing),@"automatic_retries":@0,@"maximum_video_seconds":@3600,@"gtx_opt_in":@YES};}
#ifdef DG_GEMINI_FIXTURE
void DGMediaFixtureConfiguration(NSURLSessionConfiguration *configuration,NSURL *cacheURL) {DGMediaConfiguration=configuration;DGMediaCache=[[DGCaptionStore alloc] initWithURL:cacheURL];}
void DGMediaFixtureTick(UIViewController *owner) {[objc_getAssociatedObject(owner,&DGCaptionKey) tick];}
#endif
