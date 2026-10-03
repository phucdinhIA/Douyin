#import "DGMediaUI.h"
#import "DGMedia.h"
#import "DGComments.h"
#import "DGTransduck.h"
#import "DGAudioUI.h"
#import "DGSubtitleUI.h"
#import <objc/runtime.h>
#include <math.h>

static NSDictionary *DGMediaConfig,*DGMediaGemini,*DGMediaBackend;
static DGTranslationStore *DGMediaCache;
static DGTranslationStore *DGGTXCache;
static NSURLSessionConfiguration *DGMediaConfiguration;
static void (^DGMediaRecord)(NSString *,NSUInteger);
static NSMutableSet *DGMediaHooks;
static char DGCaptionKey,DGCommentKey,DGMediaWindowKey;
static NSUInteger DGMediaWindowCount;
static NSString *const DGNativeCommentLabel=@"_TtC28AWECommentPanelListSwiftImpl20BaseCellCommentLabel";
static void DGMediaCount(NSString *name) {if (DGMediaRecord) DGMediaRecord(name,1);}
static BOOL DGMediaGetterType(Method method,char result) {
    if (!method || method_getNumberOfArguments(method)!=2) return NO;
    char *type=method_copyReturnType(method);BOOL valid=type && type[0]==result;free(type);return valid;
}
static id DGMediaGetter(id object,NSString *name) {
    SEL selector=NSSelectorFromString(name);Method method=class_getInstanceMethod(object_getClass(object),selector);
    if (!DGMediaGetterType(method,'@')) return nil;
    @try {return ((id (*)(id,SEL))method_getImplementation(method))(object,selector);}@catch (__unused NSException *error) {return nil;}
}
static NSString *DGVideoID(UIViewController *owner) {
    id model=DGMediaGetter(owner,@"model");Class cls=NSClassFromString(@"AWEAwemeModel");
    id identifier=cls && [model isKindOfClass:cls] ? DGMediaGetter(model,@"itemID") : nil;
    // This getter is independently present in the audited player category.
    if (!identifier) identifier=DGMediaGetter(owner,@"itemID");
    return [identifier isKindOfClass:NSString.class] && DGCaptionVideoURL(identifier) ? identifier : nil;
}
static NSDictionary *DGMediaResource(NSString *name) {
    NSURL *url=[NSBundle.mainBundle URLForResource:name withExtension:@"json" subdirectory:@"DouyinGuest.bundle"];
    NSData *data=url ? [NSData dataWithContentsOfURL:url] : nil;id root=data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL] : nil;return [root isKindOfClass:NSDictionary.class] ? root : @{};
}
static DGMediaClient *DGNewMediaClient(BOOL comments) {
    if (!DGMediaCache || !DGGTXCache) {
        NSURL *base=[NSFileManager.defaultManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject;
        if (!DGMediaCache) DGMediaCache=[[DGCaptionStore alloc] initWithURL:[base URLByAppendingPathComponent:@"DouyinGuest/media-vi-v1.json"]];
        if (!DGGTXCache) DGGTXCache=[[DGTranslationStore alloc] initWithURL:[base URLByAppendingPathComponent:@"DouyinGuest/gtx-vi-v1.json"]];
    }
    DGMediaClient *client=[[DGMediaClient alloc] initWithConfig:DGMediaConfig geminiKey:DGMediaGemini[@"api_key"] store:comments ? DGGTXCache : DGMediaCache configuration:DGMediaConfiguration];
    client.event=^(NSString *name) {DGMediaCount(name);if (comments && [name hasPrefix:@"Comments Gemini fallback"]) {NSString *title=[name hasSuffix:@"sent"] ? @"Gemini \u00b7 GTX 429" : [name hasSuffix:@"ready"] ? @"Gemini \u00b7 \u0111\u00e3 d\u1ecbch" : @"Gemini \u00b7 l\u1ed7i";[[NSNotificationCenter defaultCenter] postNotificationName:@"DGCommentProviderStatus" object:title];}};return client;
}
static BOOL DGMediaVisibleText(UIView *node,UIView *root) {
    CGRect rect=[node convertRect:node.bounds toView:root];rect=CGRectIntersection(rect,root.bounds);
    for (UIView *parent=node.superview;parent && parent!=root;parent=parent.superview) {
        if (parent.clipsToBounds) rect=CGRectIntersection(rect,[parent convertRect:parent.bounds toView:root]);
    }return !CGRectIsNull(rect) && !CGRectIsEmpty(rect);
}
NSArray *DGMediaReadVisibleComments(UIView *root) {
    if (!root || !NSThread.isMainThread) return @[];Class label=NSClassFromString(DGNativeCommentLabel);
    NSMutableArray *pending=[NSMutableArray arrayWithObject:root],*comments=[NSMutableArray new];NSMutableSet *seen=[NSMutableSet new];NSUInteger visited=0;
    while (pending.count && visited++<1200 && comments.count<50) {
        UIView *node=pending.lastObject;[pending removeLastObject];
        if (node.hidden || node.alpha<0.01) continue;
        BOOL visible=DGMediaVisibleText(node,root);
        if (!visible && node.clipsToBounds) continue;
        NSString *source=nil;
        // Read only audited native comment cells/models, never arbitrary labels or AI.
        for (NSString *name in @[@"AWECommentNewFeedCell",@"AWEIMSecondaryCommentCell",@"AWESearchCardCommentConcreteCell"]) {
            Class cell=NSClassFromString(name),modelClass=NSClassFromString(@"AWECommentModel");
            if (visible && cell && [node isKindOfClass:cell]) {
                id model=DGMediaGetter(node,@"commentModel");id content=modelClass && [model isKindOfClass:modelClass] ? DGMediaGetter(model,@"content") : nil;
                if ([content isKindOfClass:NSString.class]) source=content;
                if (source.length) DGMediaCount(@"GTX native model captured");break;
            }
        }
        if (visible && label && [node isKindOfClass:label]) {
            source=DGCommentVisibleText(node);
        }
        if (source.length && source.length<=2000 && ![seen containsObject:source]) {[comments addObject:source];[seen addObject:source];}
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
    [super viewDidLoad];self.title=@"Dịch bình luận · GTX";self.answers=[NSMutableDictionary new];self.client=DGNewMediaClient(YES);self.tableView.accessibilityIdentifier=@"gtx-comments-table";
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
    [tableView deselectRowAtIndexPath:path animated:YES];if (self.loading || path.row<0 || (NSUInteger)path.row>=self.comments.count) return;
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
@property(nonatomic) BOOL gemini;
- (void)open;
@end
static void DGAttachComments(UIViewController *owner);
@implementation DGCommentEntry
- (void)provider:(NSNotification *)note {if (self.owner.view.window && [note.object isKindOfClass:NSString.class]) {self.gemini=YES;[self.button setTitle:note.object forState:UIControlStateNormal];}}
- (void)open {
    if (!self.owner.view.window || self.owner.presentedViewController) return;
    DGCommentsStop(self.owner);DGAttachComments(self.owner);DGMediaCount(@"GTX manual queue restart");
}
- (void)dealloc {[NSNotificationCenter.defaultCenter removeObserver:self];}
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
@property(nonatomic) BOOL waiting;
@property(nonatomic) BOOL failed;
@property(nonatomic,strong) NSArray *pages;
@property(nonatomic,copy) NSString *pageSource;
@property(nonatomic) CGFloat pageWidth,pageFont;
@property(nonatomic) NSUInteger pageLines;
@property(nonatomic) double readyAt;
@property(nonatomic,strong) NSLayoutConstraint *buttonTop;
- (void)open;
- (void)stop;
- (void)tick;
- (void)resumeWaiting;
- (void)background;
- (void)layoutCaption:(NSDictionary *)cue time:(double)time;
- (void)drag:(UIPanGestureRecognizer *)pan;
@end
static __weak DGCaptionEntry *DGActiveCaption;
static __weak DGCaptionEntry *DGVisibleCaption;
static BOOL DGMediaPause(UIViewController *owner) {
    Method method=class_getInstanceMethod(object_getClass(owner),NSSelectorFromString(@"pause"));
    if (!DGMediaGetterType(method,'B')) return NO;
    @try {((BOOL (*)(id,SEL))method_getImplementation(method))(owner,NSSelectorFromString(@"pause"));return YES;}@catch (__unused NSException *error) {return NO;}
}
@implementation DGCaptionEntry
- (void)resumeWaiting {
    if (!self.waiting) return;
    if (!self.owner.view.window || self.owner.view.hidden || UIApplication.sharedApplication.applicationState!=UIApplicationStateActive || ![self.videoID isEqual:DGVideoID(self.owner)]) return;
    self.waiting=NO;
    Method method=class_getInstanceMethod(object_getClass(self.owner),NSSelectorFromString(@"resumePlayVideo"));
    if (DGMediaGetterType(method,'v')) {
        @try {((void (*)(id,SEL))method_getImplementation(method))(self.owner,NSSelectorFromString(@"resumePlayVideo"));DGMediaCount(@"Captions playback resumed");}@catch (__unused NSException *error) {DGMediaCount(@"Captions resume failed");}
    }
}
- (void)open {
    if (!self.owner.view.window || self.owner.view.hidden) return;
    if (self.failed && self.waiting) {[self resumeWaiting];[self stop];return;}
    if (self.running) {[self resumeWaiting];[self stop];self.status.text=@"Đã hủy · Không tự thử lại";return;}
    if (self.showing) {[self stop];return;}
    NSString *identifier=DGVideoID(self.owner);
    if (!identifier) {self.status.text=@"Chưa đọc được ID video đang xem.";DGMediaCount(@"Captions video ID unavailable");return;}
    if (!DGMediaGetterType(class_getInstanceMethod(object_getClass(self.owner),NSSelectorFromString(@"currentPlaybackTime")),'d')) {self.status.text=@"Chưa đọc được thời gian phát video.";DGMediaCount(@"Captions playback clock unavailable");return;}
    if (!DGMediaGetterType(class_getInstanceMethod(object_getClass(self.owner),NSSelectorFromString(@"resumePlayVideo")),'v') || !DGMediaPause(self.owner)) {self.status.text=@"Chưa điều khiển được tạm dừng video.";DGMediaCount(@"Captions pause unavailable");return;}
    if (DGActiveCaption!=self) [DGActiveCaption stop];DGActiveCaption=self;
    self.videoID=identifier;self.waiting=YES;self.failed=NO;self.showing=YES;self.running=YES;self.cues=@[];self.client=DGNewMediaClient(NO);[self.button setTitle:@"Hủy phụ đề" forState:UIControlStateNormal];DGMediaCount(@"Captions playback paused");
    self.timer=[NSTimer timerWithTimeInterval:0.1 repeats:YES block:^(__unused NSTimer *timer) {[DGActiveCaption tick];}];[NSRunLoop.mainRunLoop addTimer:self.timer forMode:NSRunLoopCommonModes];
    __weak DGCaptionEntry *weakSelf=self;
    self.client.update=^(NSString *stage,NSArray *cues,NSString *failure) {
        DGCaptionEntry *entry=weakSelf;if (!entry || !entry.showing || !entry.owner.view.window || ![entry.videoID isEqual:DGVideoID(entry.owner)]) {[entry stop];return;}
        entry.cues=cues;entry.running=!([stage isEqual:@"ready"] || [stage isEqual:@"cached"] || [stage isEqual:@"failed"]);
        entry.status.text=[stage isEqual:@"apify"] ? @"Đang lấy video · Apify" : [stage isEqual:@"deepgram"] ? @"Đang nhận dạng tiếng Trung · Nova-3" : [stage isEqual:@"claude"] ? @"Đang dịch phụ đề · Claude Sonnet 5" : [stage isEqual:@"partial"] ? @"Đã có một phần phụ đề · đang dịch tiếp" : [stage isEqual:@"cached"] ? @"Phụ đề đã lưu · không gọi API lại" : [stage isEqual:@"ready"] ? @"Phụ đề Việt đã sẵn sàng" : failure;
        [entry.button setTitle:entry.running ? @"Hủy phụ đề" : [stage isEqual:@"failed"] ? @"Bỏ qua · phát video" : @"Tắt phụ đề Việt" forState:UIControlStateNormal];
        if ([stage isEqual:@"failed"]) {entry.failed=YES;entry.showing=NO;entry.caption.hidden=YES;DGMediaCount(@"Captions failed waiting for user");}
        if ([stage isEqual:@"download"]) entry.status.text=@"Đang kiểm tra và lấy âm thanh video";
        if ([stage isEqual:@"ready"] || [stage isEqual:@"cached"]) {
            entry.readyAt=NSProcessInfo.processInfo.systemUptime;
            entry.status.text=@"Phụ đề đã sẵn sàng · kéo lên/xuống để đổi vị trí";
            [entry resumeWaiting];
        }
        DGMediaCount([@"Captions stage " stringByAppendingString:stage]);[entry tick];
    };
    SEL timeSelector=NSSelectorFromString(@"currentPlaybackTime");Method timeMethod=class_getInstanceMethod(object_getClass(self.owner),timeSelector);
    double time=DGMediaGetterType(timeMethod,'d') ? ((double (*)(id,SEL))method_getImplementation(timeMethod))(self.owner,timeSelector) : 0;
    DGMediaCount(@"Captions opt-in");[self.client startVideo:identifier at:time sourceURL:DGAudioSourceURL(self.owner) title:DGMediaGetter(DGMediaGetter(self.owner,@"model"),@"videoTitle")];
}
- (void)tick {
    if (UIApplication.sharedApplication.applicationState!=UIApplicationStateActive) return;
    if (!self.owner.view.window || self.owner.view.hidden || ![self.videoID isEqual:DGVideoID(self.owner)]) {[self stop];return;}
    SEL selector=NSSelectorFromString(@"currentPlaybackTime");Method method=class_getInstanceMethod(object_getClass(self.owner),selector);
    if (self.waiting && !self.running && !self.failed) [self resumeWaiting];
    if (self.waiting) {
        Method playing=class_getInstanceMethod(object_getClass(self.owner),NSSelectorFromString(@"isPlaying"));
        if (DGMediaGetterType(playing,'B') && ((BOOL (*)(id,SEL))method_getImplementation(playing))(self.owner,NSSelectorFromString(@"isPlaying"))) DGMediaPause(self.owner);
    }
    if (!self.showing || !DGMediaGetterType(method,'d')) {self.caption.hidden=YES;return;}
    NSTimeInterval time=((double (*)(id,SEL))method_getImplementation(method))(self.owner,selector);if (self.running) [self.client prioritizeTime:time];
    if (self.running && self.cues.count) {
        if ([self.client pendingSpeechAt:time]) {
            if (!self.waiting) {self.waiting=YES;DGMediaPause(self.owner);DGMediaCount(@"Captions translation buffer waiting");}
        }else if (self.waiting) {[self resumeWaiting];DGMediaCount(@"Captions translation buffer ready");}
    }
    [self layoutCaption:DGCaptionCueAt(self.cues,time) time:time];
    self.status.hidden=self.readyAt>0 && NSProcessInfo.processInfo.systemUptime-self.readyAt>4 && !self.running && !self.failed;
}
- (void)layoutCaption:(NSDictionary *)cue time:(double)time {
    UIWindow *surface=self.owner.view.window;if (!surface) return;
    CGRect safe=UIEdgeInsetsInsetRect(surface.bounds,surface.safeAreaInsets);BOOL vertical=safe.size.height>safe.size.width;NSUInteger lines=vertical ? 3 : 2;
    self.buttonTop.constant=vertical ? 58 : 8;
    CGFloat width=MAX(40,safe.size.width-24-(vertical ? 64 : 24));
    UIFont *font=[[UIFontMetrics metricsForTextStyle:UIFontTextStyleBody] scaledFontForFont:[UIFont systemFontOfSize:19 weight:UIFontWeightMedium] maximumPointSize:24];
    NSString *source=cue[@"text"];
    if (![source isEqual:self.pageSource] || fabs(width-self.pageWidth)>0.5 || fabs(font.pointSize-self.pageFont)>0.1 || lines!=self.pageLines) {
        self.pages=DGSubtitlePages(source,width-24,font,lines);self.pageSource=source;self.pageWidth=width;self.pageFont=font.pointSize;self.pageLines=lines;
    }
    self.caption.font=font;self.caption.numberOfLines=lines;self.caption.lineBreakMode=NSLineBreakByWordWrapping;
    NSString *text=DGSubtitlePageAt(self.pages,time,[cue[@"start"] doubleValue],[cue[@"end"] doubleValue]);self.caption.text=text;self.caption.accessibilityLabel=source;self.caption.hidden=!text.length;
    CGFloat height=ceil([text boundingRectWithSize:CGSizeMake(width-24,CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:font} context:nil].size.height)+14;
    height=MIN(ceil(font.lineHeight*lines)+14,MAX(font.lineHeight+14,height));
    CGFloat top=CGRectGetMinY(safe)+(vertical ? 164 : 62),bottom=CGRectGetMaxY(safe)-(vertical ? MIN(230,MAX(144,safe.size.height*0.22)) : 48);
    double position=[NSUserDefaults.standardUserDefaults objectForKey:@"DGSubtitlePosition"] ? [NSUserDefaults.standardUserDefaults doubleForKey:@"DGSubtitlePosition"] : 1;
    if (!isfinite(position)) position=1;position=MAX(0,MIN(1,position));
    CGFloat y=top+MAX(0,bottom-height-top)*position;
    self.caption.frame=CGRectMake(CGRectGetMinX(safe)+12,y,width,height);
}
- (void)drag:(UIPanGestureRecognizer *)pan {
    if (!self.showing || self.caption.hidden) return;
    UIWindow *surface=self.owner.view.window;CGRect safe=UIEdgeInsetsInsetRect(surface.bounds,surface.safeAreaInsets);BOOL vertical=safe.size.height>safe.size.width;
    CGFloat top=CGRectGetMinY(safe)+(vertical ? 164 : 62),bottom=CGRectGetMaxY(safe)-(vertical ? MIN(230,MAX(144,safe.size.height*0.22)) : 48),range=MAX(1,bottom-self.caption.bounds.size.height-top);
    CGFloat y=self.caption.frame.origin.y+[pan translationInView:surface].y;
    [NSUserDefaults.standardUserDefaults setDouble:MAX(0,MIN(1,(y-top)/range)) forKey:@"DGSubtitlePosition"];[pan setTranslation:CGPointZero inView:surface];[self tick];
}
- (void)stop {
    [self.client cancel];self.client=nil;[self.timer invalidate];self.timer=nil;self.running=NO;self.showing=NO;self.waiting=NO;self.failed=NO;self.caption.hidden=YES;self.cues=@[];self.status.text=@"";[self.button setTitle:@"Phụ đề Việt" forState:UIControlStateNormal];
    self.pages=nil;self.pageSource=nil;self.readyAt=0;
}
- (void)background {if (self.running) [self stop];self.caption.hidden=YES;}
- (void)dealloc {[_client cancel];[_timer invalidate];[_button removeFromSuperview];[_status removeFromSuperview];[_caption removeFromSuperview];[NSNotificationCenter.defaultCenter removeObserver:self];}
@end
static void DGAttachCaption(UIViewController *owner) {
    UIWindow *surface=owner.view.window;if (!surface) return;
    DGAudioOwner(owner);
    DGCaptionEntry *entry=objc_getAssociatedObject(owner,&DGCaptionKey);
    if (DGVisibleCaption && DGVisibleCaption!=entry) {DGVisibleCaption.button.hidden=YES;DGVisibleCaption.status.hidden=YES;DGVisibleCaption.caption.hidden=YES;}
    if (!entry) {
        entry=[DGCaptionEntry new];entry.owner=owner;entry.button=[UIButton buttonWithType:UIButtonTypeCustom];entry.button.accessibilityIdentifier=@"vietnamese-captions-button";[entry.button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];[entry.button setTitle:@"Phụ đề Việt" forState:UIControlStateNormal];[entry.button addTarget:entry action:@selector(open) forControlEvents:UIControlEventTouchUpInside];
        entry.button.backgroundColor=[UIColor.blackColor colorWithAlphaComponent:0.65];entry.button.tintColor=UIColor.whiteColor;entry.button.layer.cornerRadius=12;entry.button.titleLabel.font=[UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        entry.status=[UILabel new];entry.status.accessibilityIdentifier=@"vietnamese-captions-status";entry.status.numberOfLines=0;entry.status.font=[UIFont systemFontOfSize:12];entry.status.textColor=UIColor.whiteColor;entry.status.backgroundColor=[UIColor.blackColor colorWithAlphaComponent:0.5];
        entry.caption=[DGSubtitleLabel new];entry.caption.accessibilityIdentifier=@"vietnamese-captions-text";entry.caption.textAlignment=NSTextAlignmentCenter;entry.caption.textColor=UIColor.whiteColor;entry.caption.backgroundColor=[UIColor.blackColor colorWithAlphaComponent:0.82];entry.caption.layer.cornerRadius=8;entry.caption.clipsToBounds=YES;entry.caption.hidden=YES;
        entry.status.userInteractionEnabled=NO;entry.caption.userInteractionEnabled=YES;[entry.caption addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:entry action:@selector(drag:)]];
        for (UIView *view in @[entry.button,entry.status]) {view.translatesAutoresizingMaskIntoConstraints=NO;[surface addSubview:view];}[surface addSubview:entry.caption];
        entry.buttonTop=[entry.button.topAnchor constraintEqualToAnchor:surface.safeAreaLayoutGuide.topAnchor constant:58];
        [NSLayoutConstraint activateConstraints:@[entry.buttonTop,[entry.button.leadingAnchor constraintEqualToAnchor:surface.safeAreaLayoutGuide.leadingAnchor constant:12],[entry.button.widthAnchor constraintEqualToConstant:156],[entry.button.heightAnchor constraintEqualToConstant:36],
            [entry.status.topAnchor constraintEqualToAnchor:entry.button.bottomAnchor constant:4],[entry.status.leadingAnchor constraintEqualToAnchor:entry.button.leadingAnchor],[entry.status.widthAnchor constraintEqualToConstant:230]]];
        objc_setAssociatedObject(owner,&DGCaptionKey,entry,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [NSNotificationCenter.defaultCenter addObserver:entry selector:@selector(background) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    DGVisibleCaption=entry;entry.button.hidden=NO;entry.status.hidden=NO;[surface bringSubviewToFront:entry.button];[surface bringSubviewToFront:entry.status];[surface bringSubviewToFront:entry.caption];DGMediaCount(@"Captions UI attached");
}
static void DGAttachComments(UIViewController *owner) {
    DGVisibleCaption.button.hidden=YES;DGVisibleCaption.status.hidden=YES;DGVisibleCaption.caption.hidden=YES;
    DGCommentsStart(owner,DGNewMediaClient(YES),^(NSString *name,NSUInteger count) {if (DGMediaRecord) DGMediaRecord(name,count);});
}
static BOOL DGMediaNativeController(UIViewController *owner,BOOL comments) {
    for (NSString *name in comments ? @[@"AWECommentContainerViewController",@"AWECommentFullScreenContainerViewController",@"AWECommentTreeContainerViewController",@"_TtC33AWECommentPanelContainerSwiftImpl35CommentContainerInnerViewController"] : @[@"AWEPlayVideoViewController"]) {
        Class cls=NSClassFromString(name);if (cls && [owner isKindOfClass:cls]) return YES;
    }return NO;
}
static UIViewController *DGMediaTop(UIWindow *window) {
    UIViewController *top=window.rootViewController;
    while (top.presentedViewController && !top.presentedViewController.isBeingDismissed) top=top.presentedViewController;
    return top;
}
static UIViewController *DGMediaFind(UIViewController *owner,UIWindow *window,CGPoint point,BOOL comments,NSUInteger *visited) {
    if (!owner || ++*visited>160 || !owner.isViewLoaded || owner.view.window!=window || owner.view.hidden || owner.view.alpha<0.01) return nil;
    CGRect rect=[owner.view convertRect:owner.view.bounds toView:window];
    if (!CGRectIntersectsRect(rect,window.bounds) || (!comments && !CGRectContainsPoint(rect,point))) return nil;
    NSArray *children=owner.childViewControllers;
    if ([owner isKindOfClass:UINavigationController.class]) children=((UINavigationController *)owner).visibleViewController ? @[((UINavigationController *)owner).visibleViewController] : @[];
    else if ([owner isKindOfClass:UITabBarController.class]) children=((UITabBarController *)owner).selectedViewController ? @[((UITabBarController *)owner).selectedViewController] : @[];
    for (UIViewController *child in children.reverseObjectEnumerator) {UIViewController *found=DGMediaFind(child,window,point,comments,visited);if (found) return found;}
    return DGMediaNativeController(owner,comments) ? owner : nil;
}
static BOOL DGMediaBlockedTouch(UIView *hit,UIWindow *window) {
    for (UIView *node=hit;node && node!=window;node=node.superview) {
        if ([node isKindOfClass:UIControl.class] || [node isKindOfClass:UITextView.class] || [node isKindOfClass:UINavigationBar.class] || [node isKindOfClass:UITabBar.class]) return YES;
        NSString *name=NSStringFromClass(node.class);
        if ([node.accessibilityIdentifier isEqual:@"vietnamese-captions-text"]) return YES;
        if ([name containsString:@"Comment"] || [name containsString:@"Keyboard"] || [name containsString:@"AISummary"] || [name containsString:@"Serval"]) return YES;
    }return NO;
}
static UIViewController *DGMediaPlayerAt(UIWindow *window,CGPoint point) {
    if (!window.isKeyWindow || window.hidden || !CGRectContainsPoint(window.bounds,point)) return nil;
    UIView *hit=[window hitTest:point withEvent:nil];UIViewController *top=DGMediaTop(window);
    if (!hit || DGMediaBlockedTouch(hit,window) || !top.isViewLoaded || ![hit isDescendantOfView:top.view]) return nil;
    for (UIResponder *node=hit;node && node!=window;node=node.nextResponder) {
        if ([node isKindOfClass:UIViewController.class] && DGMediaNativeController((UIViewController *)node,NO)) return (UIViewController *)node;
    }
    NSUInteger visited=0;return DGMediaFind(top,window,point,NO,&visited);
}
static BOOL DGMediaStartShortcut(UIWindow *window,CGPoint point) {
    UIViewController *player=DGMediaPlayerAt(window,point);
    if (!player) {DGMediaCount(@"Captions shortcut player unavailable");return NO;}
    DGAttachCaption(player);DGCaptionEntry *entry=objc_getAssociatedObject(player,&DGCaptionKey);
    DGMediaCount(@"Captions four taps recognized");
    if (entry.running || entry.showing || entry.waiting) {DGMediaCount(@"Captions shortcut already active");return YES;}
    [entry open];return entry.showing;
}
@interface DGMediaShortcut : NSObject <UIGestureRecognizerDelegate>
- (void)open:(UITapGestureRecognizer *)tap;
@end
@implementation DGMediaShortcut
- (void)open:(UITapGestureRecognizer *)tap {
    if (tap.state==UIGestureRecognizerStateRecognized && [tap.view isKindOfClass:UIWindow.class]) DGMediaStartShortcut((UIWindow *)tap.view,[tap locationInView:tap.view]);
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldReceiveTouch:(UITouch *)touch {
    return [gesture.view isKindOfClass:UIWindow.class] && !DGMediaBlockedTouch(touch.view,(UIWindow *)gesture.view) && DGMediaPlayerAt((UIWindow *)gesture.view,[touch locationInView:gesture.view])!=nil;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)other {(void)gesture;(void)other;return YES;}
@end
void DGMediaAttachWindow(UIWindow *window) {
    if (!NSThread.isMainThread || !window.isKeyWindow) return;
    if (!objc_getAssociatedObject(window,&DGMediaWindowKey)) {
        DGMediaShortcut *target=[DGMediaShortcut new];UITapGestureRecognizer *tap=[[UITapGestureRecognizer alloc] initWithTarget:target action:@selector(open:)];
        tap.numberOfTapsRequired=4;tap.numberOfTouchesRequired=1;tap.cancelsTouchesInView=NO;tap.delaysTouchesBegan=NO;tap.delaysTouchesEnded=NO;tap.delegate=target;
        [window addGestureRecognizer:tap];objc_setAssociatedObject(window,&DGMediaWindowKey,target,OBJC_ASSOCIATION_RETAIN_NONATOMIC);DGMediaWindowCount++;DGMediaCount(@"Media four tap gesture attached");
    }
    // Recover visible native screens when installation occurred after viewDidAppear.
    NSUInteger visited=0;UIViewController *top=DGMediaTop(window),*comments=DGMediaFind(top,window,CGPointZero,YES,&visited);
    if (comments) DGAttachComments(comments);
    visited=0;UIViewController *player=DGMediaFind(top,window,CGPointMake(CGRectGetMidX(window.bounds),CGRectGetMidY(window.bounds)),NO,&visited);
    if (player && !comments) DGAttachCaption(player);
}
void DGMediaOpenComments(UIWindow *window) {
    if (!NSThread.isMainThread || !window.isKeyWindow) return;
    UIViewController *presenter=DGMediaTop(window);if (!presenter || [presenter isKindOfClass:UIAlertController.class]) return;
    DGCommentTranslations *sheet=[DGCommentTranslations new];sheet.comments=DGMediaReadVisibleComments(window);
    [presenter presentViewController:[[UINavigationController alloc] initWithRootViewController:sheet] animated:YES completion:nil];
    DGMediaCount(sheet.comments.count ? @"GTX fallback comments captured" : @"GTX fallback comments unavailable");
}
static BOOL DGMediaHook(Class cls,NSString *name,NSString *types,id (^factory)(IMP)) {
    NSString *key=[NSString stringWithFormat:@"%@ %@",NSStringFromClass(cls),name];if ([DGMediaHooks containsObject:key]) return YES;
    Method method=class_getInstanceMethod(cls,NSSelectorFromString(name));if (!method || strcmp(method_getTypeEncoding(method),types.UTF8String)) return NO;
    IMP replacement=imp_implementationWithBlock(factory(method_getImplementation(method)));if (!class_addMethod(cls,NSSelectorFromString(name),replacement,types.UTF8String)) class_replaceMethod(cls,NSSelectorFromString(name),replacement,types.UTF8String);[DGMediaHooks addObject:key];return YES;
}
void DGMediaInstall(void (^record)(NSString *,NSUInteger)) {
    DGMediaRecord=[record copy];if (!DGMediaConfig) DGMediaConfig=DGMediaResource(@"media-private");if (!DGMediaGemini) DGMediaGemini=DGMediaResource(@"gemini-private");if (!DGMediaHooks) DGMediaHooks=[NSMutableSet new];
    if (!DGMediaBackend) DGMediaBackend=DGBackendConfig();DGAudioInstall(record);
    DGCommentsInstall();Class player=NSClassFromString(@"AWEPlayVideoViewController");
    if (player && [player isSubclassOfClass:UIViewController.class]) {
        DGMediaHook(player,@"viewDidAppear:",@"v20@0:8B16",^id(IMP original) {return ^(UIViewController *owner,BOOL animated) {((void (*)(id,SEL,BOOL))original)(owner,@selector(viewDidAppear:),animated);if (NSThread.isMainThread) DGAttachCaption(owner);};});
        DGMediaHook(player,@"viewWillDisappear:",@"v20@0:8B16",^id(IMP original) {return ^(UIViewController *owner,BOOL animated) {DGCaptionEntry *entry=objc_getAssociatedObject(owner,&DGCaptionKey);[entry stop];DGAudioLeave(owner);entry.button.hidden=YES;entry.status.hidden=YES;((void (*)(id,SEL,BOOL))original)(owner,@selector(viewWillDisappear:),animated);};});
        DGMediaHook(player,@"setModel:",@"v24@0:8@16",^id(IMP original) {return ^(UIViewController *owner,id model) {[objc_getAssociatedObject(owner,&DGCaptionKey) stop];DGAudioLeave(owner);((void (*)(id,SEL,id))original)(owner,NSSelectorFromString(@"setModel:"),model);if (owner.isViewLoaded && owner.view.window && !owner.view.hidden) DGAudioOwner(owner);};});
    }
    for (NSString *name in @[@"AWECommentContainerViewController",@"AWECommentFullScreenContainerViewController",@"AWECommentTreeContainerViewController",@"_TtC33AWECommentPanelContainerSwiftImpl35CommentContainerInnerViewController"]) {
        Class cls=NSClassFromString(name);if (!cls || ![cls isSubclassOfClass:UIViewController.class]) continue;
        DGMediaHook(cls,@"viewDidAppear:",@"v20@0:8B16",^id(IMP original) {return ^(UIViewController *owner,BOOL animated) {((void (*)(id,SEL,BOOL))original)(owner,@selector(viewDidAppear:),animated);if (NSThread.isMainThread) DGAttachComments(owner);};});
        DGMediaHook(cls,@"viewWillDisappear:",@"v20@0:8B16",^id(IMP original) {return ^(UIViewController *owner,BOOL animated) {DGCommentsStop(owner);DGCommentEntry *entry=objc_getAssociatedObject(owner,&DGCommentKey);entry.button.hidden=YES;((void (*)(id,SEL,BOOL))original)(owner,@selector(viewWillDisappear:),animated);};});
    }
}
NSDictionary *DGMediaSnapshot(void) {
    NSMutableDictionary *snapshot=[@{@"caption_configured":@([DGMediaConfig[@"apify_api_key"] length]>0 && [DGMediaConfig[@"deepgram_api_key"] length]>0 && [DGMediaBackend[@"email"] length]>0),@"actor":@"apple_yang/douyin-video-audio-downloader",@"asr_model":@"nova-3",@"source_language":@"zh-CN",@"target_language":@"vi",@"translation_model":DGClaudeModel,@"hooks_installed":@(DGMediaHooks.count),@"four_tap_windows":@(DGMediaWindowCount),@"caption_waiting":@(DGActiveCaption.waiting),@"caption_shortcut_taps":@4,@"caption_running":@(DGActiveCaption.running),@"caption_showing":@(DGActiveCaption.showing),@"automatic_retries":@0,@"maximum_video_seconds":@3600,@"gtx_automatic_visible":@YES,@"deepgram_upload_fallback":@YES,@"tts_enabled":@NO,@"deepgram_empty_recovery_max":@1,@"native_source_fast_path":@YES} mutableCopy];
    [snapshot addEntriesFromDictionary:DGAudioSnapshot()];[snapshot addEntriesFromDictionary:DGGTXSnapshot()];snapshot[@"caption_full_context_seconds"]=@600;return snapshot;
}
#ifdef DG_GEMINI_FIXTURE
void DGMediaFixtureConfiguration(NSURLSessionConfiguration *configuration,NSURL *cacheURL) {DGMediaConfiguration=configuration;DGMediaCache=[[DGCaptionStore alloc] initWithURL:cacheURL];DGGTXCache=[[DGTranslationStore alloc] initWithURL:nil];}
void DGMediaFixtureTick(UIViewController *owner) {[objc_getAssociatedObject(owner,&DGCaptionKey) tick];}
BOOL DGMediaFixtureShortcut(UIWindow *window,CGPoint point) {return DGMediaStartShortcut(window,point);}
void DGMediaFixtureBackend(NSDictionary *config) {DGMediaBackend=config;}
NSArray *DGMediaFixtureTrack(UIViewController *owner,NSArray *cues) {DGCaptionEntry *entry=objc_getAssociatedObject(owner,&DGCaptionKey);NSArray *previous=entry.cues;entry.cues=cues;[entry tick];return previous;}
void DGMediaFixtureDrag(UIViewController *owner,CGFloat dy) {DGCaptionEntry *entry=objc_getAssociatedObject(owner,&DGCaptionKey);UIPanGestureRecognizer *pan=(id)entry.caption.gestureRecognizers.firstObject;[pan setTranslation:CGPointMake(0,dy) inView:owner.view.window];[entry drag:pan];}
#endif
