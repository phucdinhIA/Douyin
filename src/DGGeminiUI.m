#import "DGGeminiUI.h"
#import "DGGemini.h"
#import "DGTranslation.h"
#import "DGTransduck.h"
#import <WebKit/WebKit.h>
#import <Vision/Vision.h>
#import <CommonCrypto/CommonDigest.h>
#import <objc/runtime.h>
#include <string.h>

static NSDictionary *DGConfig;
static void (^DGRecordAI)(NSString *,NSUInteger);
static BOOL DGSendHookInstalled, DGEntryHookInstalled, DGLeaveHookInstalled, DGDisappearHookInstalled, DGAppearHookInstalled;
static char DGEntryKey;
static char DGCapturedSourceKey;
static DGTranslationStore *DGTranslationCache;
#ifdef DG_GEMINI_FIXTURE
static NSURLSessionConfiguration *DGTranslationConfiguration;
static BOOL DGFixtureTranslationTimers;
void DGGeminiTranslationFixtureTimers(BOOL enabled) {DGFixtureTranslationTimers=enabled;}
void DGGeminiTranslationFixtureConfiguration(NSURLSessionConfiguration *configuration,NSURL *cacheURL) {
    DGTranslationConfiguration=configuration;DGTranslationCache=[[DGTranslationStore alloc] initWithURL:cacheURL];
}
#endif
static NSString *const DGCommentAIClass=@"AWEFeedDoubleColumnCommentAIParseViewController";

static id DGAIGetter(id object,NSString *name) {
    Method method=object ? class_getInstanceMethod(object_getClass(object),NSSelectorFromString(name)) : NULL;
    if (!method || strcmp(method_getTypeEncoding(method),"@16@0:8")) return nil;
    @try {return ((id (*)(id,SEL))method_getImplementation(method))(object,NSSelectorFromString(name));}
    @catch (__unused NSException *error) {return nil;}
}
static BOOL DGIsNative(id object,NSString *name) {Class type=NSClassFromString(name);return type && [object isKindOfClass:type];}
static BOOL DGOn(void) {return [DGConfig[@"api_key"] isKindOfClass:NSString.class] && [DGConfig[@"api_key"] length]>0 && ![NSUserDefaults.standardUserDefaults boolForKey:@"DGGeminiDisabled"];}

// Read only these statically verified Objective-C object fields. No raw offsets,
// guessed KVC, C++ pointers, app-wide models, cookies or network payloads.
static id DGRendererIvar(id object,NSString *declaringClass,const char *name,const char *type) {
    Class cls=NSClassFromString(declaringClass);if (!cls || ![object isKindOfClass:cls]) return nil;
    Ivar ivar=class_getInstanceVariable(cls,name);
    if (!ivar || strcmp(ivar_getTypeEncoding(ivar),type)) return nil;
    @try {return object_getIvar(object,ivar);}@catch (__unused NSException *error) {return nil;}
}
static BOOL DGRendererComplete(id bundle) {
    if (!DGIsNative(bundle,@"LynxMarkdownBundle")) return NO;
    SEL selector=NSSelectorFromString(@"content_complete");Method method=class_getInstanceMethod(object_getClass(bundle),selector);
    if (!method || strcmp(method_getTypeEncoding(method),"B16@0:8")) return NO;
    @try {return ((BOOL (*)(id,SEL))method_getImplementation(method))(bundle,selector);}@catch (__unused NSException *error) {return NO;}
}
static NSString *DGRendererText(id renderer,BOOL *complete) {
    id text=nil;
    if (DGIsNative(renderer,@"ServalMarkdownView")) {
        text=DGAIGetter(renderer,@"getContent");
    } else if (DGIsNative(renderer,@"LynxMarkdownViewV2")) {
        // V2 has no bundle getter. Its actual backing renderer is an object ivar.
        id markdown=DGRendererIvar(renderer,@"LynxMarkdownViewV2","_markdownView","@\"LynxServalMarkdownViewWrapper\"");
        if (DGIsNative(markdown,@"ServalMarkdownView")) text=DGAIGetter(markdown,@"getContent");
    } else if (DGIsNative(renderer,@"LynxMarkdownView")) {
        id bundle=DGAIGetter(renderer,@"bundle");
        id node=DGIsNative(bundle,@"LynxMarkdownBundle") ? DGAIGetter(bundle,@"node") : nil;
        text=DGRendererIvar(node,@"LynxMarkdownShadowNode","_content","@\"NSString\"");
        if ([text isKindOfClass:NSString.class] && [text length]) *complete=DGRendererComplete(bundle);
    }
    return [text isKindOfClass:NSString.class] ? text : nil;
}
static NSString *DGReadSummary(UIView *root,BOOL *complete) {
    *complete=NO;
    if (!root || !NSThread.isMainThread) return @"";
    NSMutableArray<UIView *> *pending=[NSMutableArray arrayWithObject:root];
    NSMutableArray<NSString *> *segments=[NSMutableArray new];NSMutableSet *seen=[NSMutableSet new];
    NSUInteger visited=0,total=0;BOOL allComplete=YES;
    while (pending.count && visited++<1200 && total<24000) {
        UIView *node=pending.lastObject;[pending removeLastObject];
        if (node.hidden || node.alpha<0.01) continue;
        BOOL visible=!CGRectIsEmpty(node.bounds) && CGRectIntersectsRect([node convertRect:node.bounds toView:root],root.bounds);
        // Layout wrappers can have zero bounds while unclipped descendants draw normally.
        if (!visible && node.clipsToBounds) continue;
        if ([node.accessibilityIdentifier isEqual:@"gemini-translation-panel"]) continue;
        BOOL rendererComplete=NO;NSString *text=DGRendererText(node,&rendererComplete);
        if (!visible) text=nil;
        if (text.length) {
            text=DGGeminiBoundText(text,24000-total);
            if (![seen containsObject:text]) {[segments addObject:text];[seen addObject:text];total+=text.length+2;allComplete=allComplete && rendererComplete;}
            if (DGRecordAI) DGRecordAI(DGIsNative(node,@"LynxMarkdownView") ? @"Gemini capture legacy renderer" : DGIsNative(node,@"LynxMarkdownViewV2") ? @"Gemini capture V2 renderer" : @"Gemini capture Serval renderer",1);
            continue; // Do not duplicate a renderer's internal text nodes.
        }
        // For the legacy markdown renderer, read only its text descendants, never arbitrary comments/cards.
        if (visible && (DGIsNative(node,@"LynxMarkdownView") || DGIsNative(node,@"LynxMarkdownViewV2") || DGIsNative(node,@"ServalMarkdownView"))) {
            NSMutableArray *children=[NSMutableArray arrayWithArray:node.subviews.reverseObjectEnumerator.allObjects];NSUInteger read=0;
            while (children.count && read++<200 && total<24000) {
                UIView *child=children.lastObject;[children removeLastObject];
                if (child.hidden || child.alpha<0.01) continue;
                NSString *value=[child isKindOfClass:UILabel.class] ? [(UILabel *)child text] : [child isKindOfClass:UITextView.class] ? [(UITextView *)child text] : nil;
                if (value.length && ![seen containsObject:value]) {value=DGGeminiBoundText(value,24000-total);[segments addObject:value];[seen addObject:value];total+=value.length+2;allComplete=NO;}
                for (UIView *descendant in child.subviews.reverseObjectEnumerator) [children addObject:descendant];
            }
            continue;
        }
        for (UIView *child in node.subviews.reverseObjectEnumerator) [pending addObject:child];
    }
    *complete=segments.count>0 && allComplete;
    return DGGeminiBoundText([segments componentsJoinedByString:@"\n\n"],24000);
}
NSString *DGGeminiReadSummary(UIView *root) {BOOL complete;return DGReadSummary(root,&complete);}

static UIViewController *DGFindCommentAI(UIViewController *node,NSUInteger depth) {
    if (!node || depth>12) return nil;
    if ((DGIsNative(node,DGCommentAIClass) || DGIsNative(node,@"AWESearchCommentAIParseViewController")) && node.isViewLoaded && node.view.window && !node.view.hidden) return node;
    for (UIViewController *child in node.childViewControllers) {UIViewController *found=DGFindCommentAI(child,depth+1);if (found) return found;}
    return nil;
}
static NSString *DGSummaryForControllerReady(UIViewController *controller,BOOL *complete) {
    *complete=NO;
    if (!DGIsNative(controller,DGCommentAIClass) && !DGIsNative(controller,@"AWESearchCommentAIParseViewController")) return @"";
    id content=DGAIGetter(controller,@"contentVC");if (![content isKindOfClass:UIViewController.class]) content=DGAIGetter(controller,@"getCurrentViewController");
    UIView *root=[content isKindOfClass:UIViewController.class] && [content isViewLoaded] ? [content view] : controller.viewIfLoaded;
    NSString *summary=DGReadSummary(root,complete);
    if (!summary.length && root!=controller.viewIfLoaded) {
        summary=DGReadSummary(controller.viewIfLoaded,complete);
        if (summary.length && DGRecordAI) DGRecordAI(@"Gemini capture owner fallback",1);
    }
    if (!summary.length) summary=objc_getAssociatedObject(controller,&DGCapturedSourceKey) ?: @"";
    if (DGRecordAI) DGRecordAI(summary.length ? @"Gemini summary captured" : @"Gemini summary unavailable",1);
    return summary;
}
static NSString *DGSummaryForController(UIViewController *controller) {BOOL complete;return DGSummaryForControllerReady(controller,&complete);}
static void DGPresentChat(UIViewController *presenter,NSString *summary,NSString *question) {
    if (!presenter || presenter.presentedViewController || !presenter.view.window) return;
    DGGeminiChatController *chat=[[DGGeminiChatController alloc] initWithSummary:summary question:question];
    UINavigationController *navigation=[[UINavigationController alloc] initWithRootViewController:chat];
    navigation.modalPresentationStyle=UIModalPresentationPageSheet;
    navigation.sheetPresentationController.detents=@[UISheetPresentationControllerDetent.largeDetent];
    navigation.sheetPresentationController.prefersGrabberVisible=YES;
    [presenter presentViewController:navigation animated:YES completion:nil];
}
void DGGeminiPresentFrom(UIViewController *presenter) {
    UIViewController *target=DGFindCommentAI(presenter,0);
    DGPresentChat(presenter,target ? DGSummaryForController(target) : @"",nil);
}

@interface DGContextEditor : UIViewController
@property(nonatomic,strong) UITextView *text;
@property(nonatomic,copy) NSString *initial;
@property(nonatomic,copy) void (^save)(NSString *);
@end
@implementation DGContextEditor
- (void)viewDidLoad {
    [super viewDidLoad];self.title=@"Context sent to Gemini";self.view.backgroundColor=UIColor.systemBackgroundColor;
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(done)];
    self.text=[UITextView new];self.text.translatesAutoresizingMaskIntoConstraints=NO;self.text.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody];self.text.text=self.initial ?: @"";self.text.accessibilityIdentifier=@"gemini-context";[self.view addSubview:self.text];
    [NSLayoutConstraint activateConstraints:@[[self.text.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8],[self.text.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:12],[self.text.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-12],[self.text.bottomAnchor constraintEqualToAnchor:self.view.keyboardLayoutGuide.topAnchor]]];
}
- (void)done {self.save(DGGeminiBoundText(self.text.text,24000));[self.navigationController popViewControllerAnimated:YES];}
@end

@interface DGGeminiChatController () <UITextViewDelegate,UIAdaptivePresentationControllerDelegate>
@property(nonatomic,copy) NSString *summary;
@property(nonatomic,copy) NSString *initialQuestion;
@property(nonatomic,strong) UILabel *notice;
@property(nonatomic,strong) UITextView *output;
@property(nonatomic,strong) UITextView *input;
@property(nonatomic,strong) UIButton *send;
@property(nonatomic,strong) DGGeminiClient *client;
@property(nonatomic,strong) NSMutableArray *history;
@property(nonatomic,copy) NSString *transcript;
@property(nonatomic) BOOL busy;
@property(nonatomic) NSUInteger generation;
@end
@implementation DGGeminiChatController
- (instancetype)initWithSummary:(NSString *)summary question:(NSString *)question {
    if ((self=[super init])) {_summary=DGGeminiBoundText(summary,24000);_initialQuestion=DGGeminiBoundText(question,4000);_history=[NSMutableArray new];_transcript=@"";}return self;
}
- (NSString *)model {return [NSUserDefaults.standardUserDefaults boolForKey:@"DGGeminiFast"] ? DGGeminiFastModel : DGGeminiQualityModel;}
- (void)viewDidLoad {
    [super viewDidLoad];self.title=@"Gemini Q&A";self.view.backgroundColor=UIColor.systemBackgroundColor;
    self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStylePlain target:self action:@selector(close)];
    self.navigationItem.rightBarButtonItems=@[[[UIBarButtonItem alloc] initWithTitle:@"Context" style:UIBarButtonItemStylePlain target:self action:@selector(context)],[[UIBarButtonItem alloc] initWithTitle:@"Mode" style:UIBarButtonItemStylePlain target:self action:@selector(mode)]];
    self.notice=[UILabel new];self.notice.numberOfLines=0;self.notice.font=[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];self.notice.textColor=UIColor.secondaryLabelColor;self.notice.accessibilityIdentifier=@"gemini-notice";
    self.output=[UITextView new];self.output.editable=NO;self.output.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody];self.output.accessibilityIdentifier=@"gemini-answer";
    self.input=[UITextView new];self.input.delegate=self;self.input.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody];self.input.backgroundColor=UIColor.secondarySystemBackgroundColor;self.input.layer.cornerRadius=10;self.input.text=self.initialQuestion;self.input.accessibilityLabel=@"Ask Gemini";self.input.accessibilityIdentifier=@"gemini-input";
    self.send=[UIButton buttonWithType:UIButtonTypeSystem];[self.send setTitle:@"Send" forState:UIControlStateNormal];self.send.accessibilityIdentifier=@"gemini-send";[self.send addTarget:self action:@selector(sendQuestion) forControlEvents:UIControlEventTouchUpInside];
    for (UIView *view in @[self.notice,self.output,self.input,self.send]) {view.translatesAutoresizingMaskIntoConstraints=NO;[self.view addSubview:view];}
    UILayoutGuide *safe=self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[[self.notice.topAnchor constraintEqualToAnchor:safe.topAnchor constant:8],[self.notice.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:16],[self.notice.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
        [self.output.topAnchor constraintEqualToAnchor:self.notice.bottomAnchor constant:8],[self.output.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:8],[self.output.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-8],[self.output.bottomAnchor constraintEqualToAnchor:self.input.topAnchor constant:-8],
        [self.input.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:12],[self.input.heightAnchor constraintEqualToConstant:88],[self.input.bottomAnchor constraintEqualToAnchor:self.view.keyboardLayoutGuide.topAnchor constant:-8],[self.input.trailingAnchor constraintEqualToAnchor:self.send.leadingAnchor constant:-8],
        [self.send.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-12],[self.send.widthAnchor constraintEqualToConstant:68],[self.send.centerYAnchor constraintEqualToAnchor:self.input.centerYAnchor],[self.send.heightAnchor constraintEqualToConstant:44]]];
    self.output.text=@"Ask about the original AI analysis, or request a translation. Gemini receives text only; it cannot watch this video.\n\nUse Context to review or paste the analysis. Douyin's original analysis stays unchanged.";
    [self updateNotice];
}
- (void)viewDidAppear:(BOOL)animated {[super viewDidAppear:animated];self.navigationController.presentationController.delegate=self;}
- (void)updateNotice {
    self.notice.text=[NSString stringWithFormat:@"%@ · %@\nSend shares your question, context and recent answers with Google Gemini.",[self.model isEqual:DGGeminiFastModel] ? @"3.5 Flash-Lite · Fast" : @"3.8 Flash · Quality",self.summary.length ? [NSString stringWithFormat:@"Context: %lu characters",(unsigned long)self.summary.length] : @"No analysis captured — add it in Context"];
}
- (void)context {
    if (self.busy) return;
    DGContextEditor *editor=[DGContextEditor new];editor.initial=self.summary;
    __weak DGGeminiChatController *weakSelf=self;
    editor.save=^(NSString *value) {DGGeminiChatController *owner=weakSelf;owner.summary=value;[owner.history removeAllObjects];owner.transcript=@"";owner.output.text=@"Context updated. Start a new question.";[owner updateNotice];};
    [self.navigationController pushViewController:editor animated:YES];
}
- (void)mode {
    if (self.busy) return;
    BOOL next=![NSUserDefaults.standardUserDefaults boolForKey:@"DGGeminiFast"];
    [NSUserDefaults.standardUserDefaults setBool:next forKey:@"DGGeminiFast"];[self updateNotice];
}
- (void)setWorking:(BOOL)value {self.busy=value;self.input.editable=!value;[self.send setTitle:value ? @"Cancel" : @"Send" forState:UIControlStateNormal];for (UIBarButtonItem *item in self.navigationItem.rightBarButtonItems) item.enabled=!value;}
- (void)sendQuestion {
    if (self.busy) {[self cancel];self.output.text=[self.transcript stringByAppendingString:@"\nRequest cancelled. Your question is kept."];return;}
    NSString *question=[self.input.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (!DGOn()) {self.output.text=@"Gemini is disabled or no key is configured in this personal build.";return;}
    if (!question.length || question.length>4000) {self.output.text=@"Enter a question of 1–4,000 characters.";return;}
    [self.input resignFirstResponder];[self setWorking:YES];NSUInteger request=++self.generation;
    self.output.text=[self.transcript stringByAppendingFormat:@"\nYou: %@\n\nGemini is answering…",question];
    self.client=[[DGGeminiClient alloc] initWithKey:DGConfig[@"api_key"] model:self.model];
    if (DGRecordAI) DGRecordAI(@"Gemini question sent",1);
    __weak DGGeminiChatController *weakSelf=self;
    [self.client sendQuestion:question summary:self.summary history:self.history completion:^(NSString *answer,NSString *failure) {
        DGGeminiChatController *owner=weakSelf;if (!owner || request!=owner.generation) return;
        [owner setWorking:NO];owner.client=nil;
        if (answer) {
            [owner.history addObject:@{@"question":question,@"answer":answer}];if (owner.history.count>3) [owner.history removeObjectAtIndex:0];
            NSMutableString *recent=[NSMutableString new];
            for (NSDictionary *pair in owner.history) [recent appendFormat:@"\nYou: %@\n\nGemini: %@\n",pair[@"question"],pair[@"answer"]];
            owner.transcript=DGGeminiBoundText(recent,120000);
            owner.output.text=owner.transcript;owner.input.text=@"";
            if (DGRecordAI) DGRecordAI(@"Gemini answer received",1);
        } else {owner.output.text=[owner.transcript stringByAppendingFormat:@"\n%@\nYour question is kept. Tap Send to try again.",failure];if (DGRecordAI) DGRecordAI(@"Gemini request failed",1);}
    }];
}
- (void)cancel {++self.generation;[self.client cancel];self.client=nil;[self setWorking:NO];}
- (void)close {[self cancel];[self dismissViewControllerAnimated:YES completion:nil];}
- (void)presentationControllerDidDismiss:(UIPresentationController *)presentationController {(void)presentationController;[self cancel];}
- (void)viewDidDisappear:(BOOL)animated {[super viewDidDisappear:animated];if (self.navigationController.isBeingDismissed || self.isBeingDismissed) [self cancel];}
- (void)dealloc {[_client cancel];}
@end

@interface DGTranslationPanel : UIView
@property(nonatomic) BOOL passthrough;
@end
@implementation DGTranslationPanel
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit=[super hitTest:point withEvent:event];return self.passthrough && hit==self ? nil : hit;
}
@end
@interface DGGeminiEntry : NSObject
@property(nonatomic,weak) UIViewController *owner;
@property(nonatomic,strong) UIButton *button;
@property(nonatomic,strong) DGTranslationPanel *panel;
@property(nonatomic,strong) UITextView *translation;
@property(nonatomic,strong) UILabel *status;
@property(nonatomic,strong) UISegmentedControl *language;
@property(nonatomic,strong) UIButton *retry;
@property(nonatomic,strong) NSTimer *timer;
@property(nonatomic,strong) DGTranslationSession *session;
@property(nonatomic,strong) DGGeminiClient *client;
@property(nonatomic,strong) DGTransduckClient *translator;
@property(nonatomic) BOOL hadWindow;
@property(nonatomic) BOOL capturePending;
@property(nonatomic) NSUInteger captureGeneration,captureAttempts;
@property(nonatomic) NSTimeInterval nextCapture;
@property(nonatomic,copy) NSString *ocrCandidate;
@property(nonatomic) BOOL capturedVisibleOnly;
@property(nonatomic) BOOL tabEntered;
@property(nonatomic) BOOL automaticSpent;
@property(nonatomic) BOOL hasTranslation;
@property(nonatomic) BOOL userChoseLanguage;
- (void)open;
- (void)start;
- (void)stop;
- (void)tickAt:(NSTimeInterval)time;
- (void)captureDrawnAnalysis;
@end
static __weak DGGeminiEntry *DGActiveTranslation;
@implementation DGGeminiEntry
- (void)captureDrawnAnalysis {
    id content=DGAIGetter(self.owner,@"contentVC");
    if (![content isKindOfClass:UIViewController.class]) content=DGAIGetter(self.owner,@"getCurrentViewController");
    UIView *root=[content isKindOfClass:UIViewController.class] ? [content viewIfLoaded] : self.owner.viewIfLoaded;
    if (!root.window) root=self.owner.viewIfLoaded;
    id analysis=DGAIGetter(content,@"analysisView");if ([analysis isKindOfClass:UIView.class] && [analysis window] && [analysis bounds].size.width>=40 && [analysis bounds].size.height>=40) root=analysis;
    if (!root.window || root.hidden || root.bounds.size.width<40 || root.bounds.size.height<40) return;
    self.capturePending=YES;self.captureAttempts++;self.nextCapture=NSProcessInfo.processInfo.systemUptime+3;
    NSUInteger generation=self.captureGeneration;__weak DGGeminiEntry *weakSelf=self;
    void (^finish)(NSString *)=^(NSString *text) {
        DGGeminiEntry *entry=weakSelf;if (!entry || entry.captureGeneration!=generation || !entry.tabEntered || !entry.session.waiting || !entry.owner.view.window) return;
        entry.capturePending=NO;NSString *bounded=DGGeminiBoundText(text,24000);
        if ([bounded stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].length) {objc_setAssociatedObject(entry.owner,&DGCapturedSourceKey,bounded,OBJC_ASSOCIATION_COPY_NONATOMIC);if (DGRecordAI) DGRecordAI(@"AI rendered source captured",1);}
    };
    NSMutableArray *nodes=[NSMutableArray arrayWithObject:root];WKWebView *web=nil;NSUInteger visited=0;
    while (nodes.count && visited++<1200) {UIView *view=nodes.lastObject;[nodes removeLastObject];if (view.hidden || view.alpha<0.01 || view==self.panel || view==self.button) continue;
        if ([view isKindOfClass:WKWebView.class]) {web=(id)view;break;}[nodes addObjectsFromArray:view.subviews];
    }
    if (web && self.captureAttempts<3) {
        if (DGRecordAI) DGRecordAI(@"AI scoped web capture",1);
        [web evaluateJavaScript:@"(()=>{const a=document.querySelector('[data-ai-analysis],.markdown-body,.markdown-content,[role=article],article,main');return (a||document.body)?.innerText?.slice(0,24000)||''})()" completionHandler:^(id text,__unused NSError *error) {finish([text isKindOfClass:NSString.class] ? text : @"");}];return;
    }
    // OCR runs locally on the original AI surface only; the app's translation UI
    // is hidden synchronously for the snapshot and restored before returning.
    BOOL panelHidden=self.panel.hidden,buttonHidden=self.button.hidden;self.panel.hidden=YES;self.button.hidden=YES;
    UIGraphicsImageRendererFormat *format=[UIGraphicsImageRendererFormat defaultFormat];format.scale=MIN(2,UIScreen.mainScreen.scale);
    UIGraphicsImageRenderer *renderer=[[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(MIN(root.bounds.size.width,1024),MIN(root.bounds.size.height,2048)) format:format];
    [root layoutIfNeeded];
    __block BOOL drawn=NO;
    UIImage *snapshot=[renderer imageWithActions:^(__unused UIGraphicsImageRendererContext *context) {drawn=[root drawViewHierarchyInRect:root.bounds afterScreenUpdates:YES];}];
    self.panel.hidden=panelHidden;self.button.hidden=buttonHidden;if (DGRecordAI) DGRecordAI(@"AI local OCR started",1);
    if (!drawn || !snapshot.CGImage) {self.capturePending=NO;return;}
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0),^{
        VNRecognizeTextRequest *request=[VNRecognizeTextRequest new];request.recognitionLevel=VNRequestTextRecognitionLevelAccurate;request.recognitionLanguages=@[@"zh-Hans",@"en-US"];request.usesLanguageCorrection=YES;
        VNImageRequestHandler *handler=[[VNImageRequestHandler alloc] initWithCGImage:snapshot.CGImage options:@{}];NSError *error=nil;BOOL ok=[handler performRequests:@[request] error:&error];
        NSArray *results=ok ? request.results : @[];results=[results sortedArrayUsingComparator:^NSComparisonResult(VNRecognizedTextObservation *a,VNRecognizedTextObservation *b) {
            CGFloat row=CGRectGetMidY(b.boundingBox)-CGRectGetMidY(a.boundingBox);if (fabs(row)>0.015) return row>0 ? NSOrderedAscending : NSOrderedDescending;return CGRectGetMinX(a.boundingBox)<CGRectGetMinX(b.boundingBox) ? NSOrderedAscending : NSOrderedDescending;
        }];NSMutableArray *lines=[NSMutableArray new];NSUInteger length=0;
        for (VNRecognizedTextObservation *observation in results) {VNRecognizedText *text=[observation topCandidates:1].firstObject;if (text.confidence<0.35 || !text.string.length) continue;length+=text.string.length;if (length>24000) break;[lines addObject:text.string];}
        NSString *source=[lines componentsJoinedByString:@"\n"];dispatch_async(dispatch_get_main_queue(),^{
#ifdef DG_GEMINI_FIXTURE
            NSLog(@"AI OCR fixture: drawn=%d, image=%.0fx%.0f, ok=%d, error=%ld, observations=%lu, retained=%lu",drawn,snapshot.size.width,snapshot.size.height,ok,(long)error.code,(unsigned long)request.results.count,(unsigned long)lines.count);
#endif
            DGGeminiEntry *entry=weakSelf;if (!entry || entry.captureGeneration!=generation || !entry.tabEntered) return;
            entry.capturePending=NO;entry.nextCapture=NSProcessInfo.processInfo.systemUptime+1;
            if (source.length && [entry.ocrCandidate isEqual:source]) {entry.capturedVisibleOnly=YES;finish(source);}
            else entry.ocrCandidate=source;
        });
    });
}
- (void)open {if (DGOn()) DGPresentChat(self.owner,DGSummaryForController(self.owner),nil);}
- (void)languageChanged {
    self.userChoseLanguage=YES;[self renderLanguage];
}
- (void)renderLanguage {
    BOOL original=self.language.selectedSegmentIndex==1;
    BOOL showTranslation=self.hasTranslation && !original;
    self.translation.hidden=!showTranslation;self.status.hidden=NO;self.retry.hidden=![self.retry.accessibilityValue isEqual:@"available"];
    self.panel.backgroundColor=showTranslation ? UIColor.systemBackgroundColor : UIColor.clearColor;
    self.status.backgroundColor=UIColor.systemBackgroundColor;self.panel.passthrough=!showTranslation;
}
- (void)start {
    if (self.session.active || !DGOn()) return;
    if (DGActiveTranslation!=self) [DGActiveTranslation stop];DGActiveTranslation=self;
    if (!DGTranslationCache) {
        NSURL *base=[NSFileManager.defaultManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject;
        DGTranslationCache=[[DGTranslationStore alloc] initWithURL:[base URLByAppendingPathComponent:@"DouyinGuest/ai-claude-vi-v1.json"]];
    }
    __weak DGGeminiEntry *weakSelf=self;
    self.session=[[DGTranslationSession alloc] initWithStore:DGTranslationCache sender:^(NSString *source,void (^completion)(NSString *,NSString *)) {
        DGGeminiEntry *entry=weakSelf;
        if (entry.automaticSpent) {completion(nil,@"Yêu cầu trước đã dừng. Bấm Dịch lại nếu bạn muốn thử thêm một lượt.");return;}
        entry.automaticSpent=YES;
        entry.translator=[[DGTransduckClient alloc] initWithConfig:DGBackendConfig() configuration:
#ifdef DG_GEMINI_FIXTURE
            DGTranslationConfiguration
#else
            nil
#endif
        ];
        NSMutableArray *cues=[NSMutableArray new];NSUInteger offset=0;
        while (offset<source.length) {
            NSUInteger length=MIN((NSUInteger)400,source.length-offset);NSRange range=[source rangeOfComposedCharacterSequencesForRange:NSMakeRange(offset,length)];
            NSUInteger index=cues.count;[cues addObject:@{@"id":@(index),@"start":@(index),@"end":@(index+1),@"text":[source substringWithRange:range]}];offset=NSMaxRange(range);
        }
        if (DGRecordAI) DGRecordAI(@"AI Claude translation sent",1);
        NSData *sourceBytes=[source dataUsingEncoding:NSUTF8StringEncoding];unsigned char digest[CC_SHA256_DIGEST_LENGTH];CC_SHA256(sourceBytes.bytes,(CC_LONG)sourceBytes.length,digest);NSMutableString *identity=[NSMutableString stringWithString:@"douyin_ai_"];for (NSUInteger i=0;i<sizeof(digest);i++) [identity appendFormat:@"%02x",digest[i]];
        [entry.translator post:@"/api/v2/ai-translate/translate" body:DGClaudeBody(cues,identity,@"Douyin AI analysis") completion:^(NSData *data,NSInteger status,NSString *failure) {
            NSArray *translated=failure ? nil : DGClaudeAnswer(data,status,cues,&failure);NSMutableArray *pieces=[NSMutableArray new];for (NSDictionary *cue in translated) [pieces addObject:cue[@"text"]];NSString *answer=translated ? [pieces componentsJoinedByString:@"\n\n"] : nil;
            DGGeminiEntry *current=weakSelf;[current.translator cancel];current.translator=nil;
            if (!DGOn() || !current.tabEntered || !current.owner.view.window || current.owner.view.hidden) {[current stop];return;}
            if (![DGSummaryForController(current.owner) isEqualToString:source]) {
                completion(nil,@"Phân tích đã thay đổi trong lúc dịch. Bấm Dịch lại để dịch nội dung mới.");return;
            }
            completion(answer,failure);
        }];
    } cancel:^{[weakSelf.translator cancel];weakSelf.translator=nil;}];
    self.session.update=^(NSString *state,NSString *text) {
        DGGeminiEntry *entry=weakSelf;if (!entry) return;
        BOOL ready=[state isEqual:@"ready"] || [state isEqual:@"cached"];
        entry.hasTranslation=ready;
        if (ready && !entry.userChoseLanguage) entry.language.selectedSegmentIndex=0;
        entry.status.text=ready ? (entry.capturedVisibleOnly ? @"Đã dịch vùng phân tích đang hiển thị · Claude" : [state isEqual:@"cached"] ? @"Bản dịch đã lưu · Không gọi API lại" : @"Đã dịch · Claude Sonnet 5") : text;
        // The renderer supplies HTML highlight markers; UITextView displays plain text.
        NSString *plain=text;
        if (ready) {
            NSRegularExpression *marks=[NSRegularExpression regularExpressionWithPattern:@"</?mark\\b[^>]*>" options:NSRegularExpressionCaseInsensitive error:NULL];
            plain=[marks stringByReplacingMatchesInString:text options:0 range:NSMakeRange(0,text.length) withTemplate:@""];
        }
        entry.translation.text=ready ? plain : @"Chỉ dịch phần phân tích AI đang mở. Nội dung được gửi tới Claude qua tài khoản dịch của bạn.\n\nChọn Bản gốc để xem nội dung của Douyin trong lúc chờ.";
        entry.retry.accessibilityValue=[state isEqual:@"failed"] ? @"available" : @"unavailable";
        [entry.retry setTitle:[state isEqual:@"failed"] && [text containsString:@"chưa đọc được"] ? @"Đọc lại" : @"Dịch lại" forState:UIControlStateNormal];
        [entry renderLanguage];
        if (DGRecordAI && ([state isEqual:@"cached"] || [state isEqual:@"ready"] || [state isEqual:@"failed"])) DGRecordAI([@"Gemini translation " stringByAppendingString:state],1);
        if (!entry.session.waiting) {[entry.timer invalidate];entry.timer=nil;}
    };
    self.hadWindow=NO;self.captureAttempts=0;self.ocrCandidate=nil;self.capturedVisibleOnly=NO;self.nextCapture=NSProcessInfo.processInfo.systemUptime+3;objc_setAssociatedObject(self.owner,&DGCapturedSourceKey,nil,OBJC_ASSOCIATION_COPY_NONATOMIC);self.hasTranslation=NO;self.userChoseLanguage=NO;self.panel.hidden=NO;self.button.hidden=NO;self.language.selectedSegmentIndex=1;
    [self.session enterAt:NSProcessInfo.processInfo.systemUptime];
#ifdef DG_GEMINI_FIXTURE
    if (DGFixtureTranslationTimers) {
#endif
    self.timer=[NSTimer timerWithTimeInterval:0.25 repeats:YES block:^(__unused NSTimer *timer) {[weakSelf tickAt:NSProcessInfo.processInfo.systemUptime];}];
    [NSRunLoop.mainRunLoop addTimer:self.timer forMode:NSRunLoopCommonModes];
#ifdef DG_GEMINI_FIXTURE
    }
#endif
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(stop) name:UIApplicationDidEnterBackgroundNotification object:nil];
}
- (void)tickAt:(NSTimeInterval)time {
    if (!DGOn() || !self.owner || (self.hadWindow && (!self.owner.view.window || self.owner.view.hidden)) || UIApplication.sharedApplication.applicationState!=UIApplicationStateActive) {[self stop];return;}
    if (!self.owner.view.window || self.owner.view.hidden) {
        [self.session observeSource:@"" at:time];return;
    }
    self.hadWindow=YES;
    if (DGRecordAI) DGRecordAI(@"Gemini translation poll",1);
    BOOL complete=NO;NSString *source=DGSummaryForControllerReady(self.owner,&complete);
    if (complete && DGRecordAI) DGRecordAI(@"Gemini capture complete",1);
    if (!source.length && !self.capturePending && self.captureAttempts<4 && time>=self.nextCapture) [self captureDrawnAnalysis];
    [self.session observeSource:source complete:complete at:time];
}
- (void)retryTranslation {
    if (!self.session.active || !DGOn() || !self.owner.view.window) return;
    [self stop];self.automaticSpent=NO;[self start];
}
- (void)becameActive:(NSNotification *)notification {
    (void)notification;if (self.tabEntered && self.owner.view.window && !self.owner.view.hidden) [self start];
}
- (void)stop {
    self.captureGeneration++;self.capturePending=NO;
    [self.timer invalidate];self.timer=nil;[self.session leave];self.panel.hidden=YES;self.button.hidden=YES;
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}
- (void)dealloc {[_timer invalidate];[_client cancel];[NSNotificationCenter.defaultCenter removeObserver:self];}
@end
#ifdef DG_GEMINI_FIXTURE
void DGGeminiTranslationFixtureTick(UIViewController *owner,NSTimeInterval time) {
    DGGeminiEntry *entry=objc_getAssociatedObject(owner,&DGEntryKey);[entry tickAt:time];
}
#endif
static void DGAttachEntry(UIViewController *owner) {
    DGGeminiEntry *entry=objc_getAssociatedObject(owner,&DGEntryKey);
    if (!DGOn()) {[entry stop];return;}
    if (!owner.isViewLoaded) return;
    if (!entry) {
        entry=[DGGeminiEntry new];entry.owner=owner;entry.button=[UIButton buttonWithType:UIButtonTypeSystem];
        [entry.button setTitle:@"Ask Gemini · Your AI" forState:UIControlStateNormal];entry.button.accessibilityIdentifier=@"gemini-comment-entry";
        entry.button.backgroundColor=UIColor.secondarySystemBackgroundColor;entry.button.layer.cornerRadius=14;
        entry.button.translatesAutoresizingMaskIntoConstraints=NO;
        [entry.button addTarget:entry action:@selector(open) forControlEvents:UIControlEventTouchUpInside];
        [owner.view addSubview:entry.button];
        [NSLayoutConstraint activateConstraints:@[[entry.button.leadingAnchor constraintEqualToAnchor:owner.view.safeAreaLayoutGuide.leadingAnchor constant:12],[entry.button.trailingAnchor constraintEqualToAnchor:owner.view.safeAreaLayoutGuide.trailingAnchor constant:-12],[entry.button.bottomAnchor constraintEqualToAnchor:owner.view.safeAreaLayoutGuide.bottomAnchor constant:-8],[entry.button.heightAnchor constraintEqualToConstant:48]]];
        entry.panel=[DGTranslationPanel new];entry.panel.translatesAutoresizingMaskIntoConstraints=NO;entry.panel.layer.cornerRadius=12;entry.panel.clipsToBounds=YES;entry.panel.accessibilityIdentifier=@"gemini-translation-panel";[owner.view addSubview:entry.panel];
        entry.language=[[UISegmentedControl alloc] initWithItems:@[@"Tiếng Việt",@"Bản gốc"]];entry.language.accessibilityIdentifier=@"gemini-translation-language";[entry.language addTarget:entry action:@selector(languageChanged) forControlEvents:UIControlEventValueChanged];
        entry.status=[UILabel new];entry.status.numberOfLines=0;entry.status.font=[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];entry.status.textColor=UIColor.secondaryLabelColor;entry.status.accessibilityIdentifier=@"gemini-translation-status";
        entry.translation=[UITextView new];entry.translation.editable=NO;entry.translation.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody];entry.translation.accessibilityIdentifier=@"gemini-translation-text";
        entry.retry=[UIButton buttonWithType:UIButtonTypeSystem];[entry.retry setTitle:@"Dịch lại" forState:UIControlStateNormal];entry.retry.accessibilityIdentifier=@"gemini-translation-retry";[entry.retry addTarget:entry action:@selector(retryTranslation) forControlEvents:UIControlEventTouchUpInside];
        for (UIView *view in @[entry.language,entry.status,entry.translation,entry.retry]) {view.translatesAutoresizingMaskIntoConstraints=NO;[entry.panel addSubview:view];}
        [NSLayoutConstraint activateConstraints:@[
            [entry.panel.topAnchor constraintEqualToAnchor:owner.view.safeAreaLayoutGuide.topAnchor constant:64],[entry.panel.bottomAnchor constraintEqualToAnchor:entry.button.topAnchor constant:-8],[entry.panel.leadingAnchor constraintEqualToAnchor:owner.view.safeAreaLayoutGuide.leadingAnchor constant:8],[entry.panel.trailingAnchor constraintEqualToAnchor:owner.view.safeAreaLayoutGuide.trailingAnchor constant:-8],
            [entry.language.topAnchor constraintEqualToAnchor:entry.panel.topAnchor constant:8],[entry.language.leadingAnchor constraintEqualToAnchor:entry.panel.leadingAnchor constant:12],[entry.language.trailingAnchor constraintEqualToAnchor:entry.panel.trailingAnchor constant:-12],
            [entry.status.topAnchor constraintEqualToAnchor:entry.language.bottomAnchor constant:8],[entry.status.leadingAnchor constraintEqualToAnchor:entry.panel.leadingAnchor constant:12],[entry.status.trailingAnchor constraintEqualToAnchor:entry.panel.trailingAnchor constant:-12],
            [entry.translation.topAnchor constraintEqualToAnchor:entry.status.bottomAnchor constant:8],[entry.translation.leadingAnchor constraintEqualToAnchor:entry.panel.leadingAnchor constant:4],[entry.translation.trailingAnchor constraintEqualToAnchor:entry.panel.trailingAnchor constant:-4],[entry.translation.bottomAnchor constraintEqualToAnchor:entry.retry.topAnchor],
            [entry.retry.leadingAnchor constraintEqualToAnchor:entry.panel.leadingAnchor constant:12],[entry.retry.trailingAnchor constraintEqualToAnchor:entry.panel.trailingAnchor constant:-12],[entry.retry.bottomAnchor constraintEqualToAnchor:entry.panel.bottomAnchor],[entry.retry.heightAnchor constraintEqualToConstant:44]]];
        objc_setAssociatedObject(owner,&DGEntryKey,entry,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [NSNotificationCenter.defaultCenter addObserver:entry selector:@selector(becameActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    if (!entry.tabEntered) entry.automaticSpent=NO;
    entry.tabEntered=YES;[owner.view bringSubviewToFront:entry.panel];[owner.view bringSubviewToFront:entry.button];[entry start];
}
static BOOL DGOverride(Class cls,NSString *selector,NSString *types,id (^factory)(IMP)) {
    Method method=class_getInstanceMethod(cls,NSSelectorFromString(selector));
    if (!method || strcmp(method_getTypeEncoding(method),types.UTF8String)) return NO;
    IMP replacement=imp_implementationWithBlock(factory(method_getImplementation(method)));
    if (!class_addMethod(cls,NSSelectorFromString(selector),replacement,types.UTF8String)) class_replaceMethod(cls,NSSelectorFromString(selector),replacement,types.UTF8String);
    return YES;
}
void DGGeminiInstall(void (^record)(NSString *,NSUInteger)) {
    DGRecordAI=[record copy];
    if (!DGConfig) {
        NSURL *url=[NSBundle.mainBundle URLForResource:@"gemini-private" withExtension:@"json" subdirectory:@"DouyinGuest.bundle"];
        NSData *data=url ? [NSData dataWithContentsOfURL:url] : nil;
        id config=data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL] : nil;
        DGConfig=[config isKindOfClass:NSDictionary.class] ? config : @{};
    }
    static NSMutableSet *installed;if (!installed) installed=[NSMutableSet new];
    for (NSString *name in @[DGCommentAIClass,@"AWESearchCommentAIParseViewController"]) {
    Class cls=NSClassFromString(name);if (!cls || ![cls isSubclassOfClass:UIViewController.class] || [installed containsObject:name]) continue;[installed addObject:name];
    DGSendHookInstalled=DGSendHookInstalled | DGOverride(cls,@"inputViewSendQueryContext:sourceFrom:",@"v32@0:8@16q24",^id(IMP original) {
        return ^(UIViewController *owner,id context,NSInteger source) {
            if (!DGOn() || !NSThread.isMainThread || !owner.view.window || owner.presentedViewController) {((void (*)(id,SEL,id,NSInteger))original)(owner,NSSelectorFromString(@"inputViewSendQueryContext:sourceFrom:"),context,source);return;}
            NSString *query=nil;
            if (DGIsNative(context,@"AWESearchAIGCQueryContext")) {id value=DGAIGetter(context,@"query");if ([value isKindOfClass:NSString.class]) query=value;}
            // Unknown/image input is not silently forwarded to Google or fake-authenticated.
            if (!query.length || query.length>4000) {if (DGRecordAI) DGRecordAI(@"Gemini native query unsupported",1);DGPresentChat(owner,DGSummaryForController(owner),nil);return;}
            if (DGRecordAI) DGRecordAI(@"Gemini native query routed",1);
            DGPresentChat(owner,DGSummaryForController(owner),query);
        };
    });
    DGEntryHookInstalled=DGEntryHookInstalled | DGOverride(cls,@"commentAIParseTabDidEnter",@"v16@0:8",^id(IMP original) {
        return ^(UIViewController *owner) {((void (*)(id,SEL))original)(owner,NSSelectorFromString(@"commentAIParseTabDidEnter"));DGAttachEntry(owner);};
    });
    NSString *leave=class_getInstanceMethod(cls,NSSelectorFromString(@"commentAIParseTabWillLeave")) ? @"commentAIParseTabWillLeave" : @"commentAIParseTabDidLeave";
    DGLeaveHookInstalled=DGLeaveHookInstalled | DGOverride(cls,leave,@"v16@0:8",^id(IMP original) {
        return ^(UIViewController *owner) {DGGeminiEntry *entry=objc_getAssociatedObject(owner,&DGEntryKey);entry.tabEntered=NO;[entry stop];((void (*)(id,SEL))original)(owner,NSSelectorFromString(leave));};
    });
    DGDisappearHookInstalled=DGDisappearHookInstalled | DGOverride(cls,@"viewWillDisappear:",@"v20@0:8B16",^id(IMP original) {
        return ^(UIViewController *owner,BOOL animated) {DGGeminiEntry *entry=objc_getAssociatedObject(owner,&DGEntryKey);[entry stop];((void (*)(id,SEL,BOOL))original)(owner,@selector(viewWillDisappear:),animated);};
    });
    DGAppearHookInstalled=DGAppearHookInstalled | DGOverride(cls,@"viewDidAppear:",@"v20@0:8B16",^id(IMP original) {
        return ^(UIViewController *owner,BOOL animated) {((void (*)(id,SEL,BOOL))original)(owner,@selector(viewDidAppear:),animated);DGGeminiEntry *entry=objc_getAssociatedObject(owner,&DGEntryKey);if (entry.tabEntered) DGAttachEntry(owner);};
    });
    }
}
NSDictionary *DGGeminiSnapshot(void) {
    return @{@"configured":@([DGConfig[@"api_key"] isKindOfClass:NSString.class] && [DGConfig[@"api_key"] length]>0),@"enabled":@(DGOn()),@"native_send_hook":@(DGSendHookInstalled),@"native_entry_hook":@(DGEntryHookInstalled),@"native_leave_hook":@(DGLeaveHookInstalled),@"translation_disappear_hook":@(DGDisappearHookInstalled),@"translation_active":@(DGActiveTranslation.session.active),@"translation_model":DGClaudeModel,@"translation_cache_entries_max":@32,@"translation_automatic_retries":@0,@"model":[NSUserDefaults.standardUserDefaults boolForKey:@"DGGeminiFast"] ? DGGeminiFastModel : DGGeminiQualityModel};
}
