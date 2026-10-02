#import "DGGeminiUI.h"
#import "DGGemini.h"
#import <objc/runtime.h>
#include <string.h>

static NSDictionary *DGConfig;
static void (^DGRecordAI)(NSString *,NSUInteger);
static BOOL DGSendHookInstalled, DGEntryHookInstalled, DGLeaveHookInstalled;
static char DGEntryKey;
static NSString *const DGCommentAIClass=@"AWEFeedDoubleColumnCommentAIParseViewController";

static id DGAIGetter(id object,NSString *name) {
    Method method=object ? class_getInstanceMethod(object_getClass(object),NSSelectorFromString(name)) : NULL;
    if (!method || strcmp(method_getTypeEncoding(method),"@16@0:8")) return nil;
    @try {return ((id (*)(id,SEL))method_getImplementation(method))(object,NSSelectorFromString(name));}
    @catch (__unused NSException *error) {return nil;}
}
static BOOL DGIsNative(id object,NSString *name) {Class type=NSClassFromString(name);return type && [object isKindOfClass:type];}
static BOOL DGOn(void) {return [DGConfig[@"api_key"] isKindOfClass:NSString.class] && [DGConfig[@"api_key"] length]>0 && ![NSUserDefaults.standardUserDefaults boolForKey:@"DGGeminiDisabled"];}

NSString *DGGeminiReadSummary(UIView *root) {
    if (!root || !NSThread.isMainThread) return @"";
    NSMutableArray<UIView *> *pending=[NSMutableArray arrayWithObject:root];
    NSMutableArray<NSString *> *segments=[NSMutableArray new];NSMutableSet *seen=[NSMutableSet new];
    NSUInteger visited=0,total=0;
    while (pending.count && visited++<1200 && total<24000) {
        UIView *node=pending.lastObject;[pending removeLastObject];
        if (node.hidden || node.alpha<0.01 || !CGRectIntersectsRect([node convertRect:node.bounds toView:root],root.bounds)) continue;
        NSString *text=nil;
        if (DGIsNative(node,@"ServalMarkdownView")) {
            id value=DGAIGetter(node,@"getContent");if ([value isKindOfClass:NSString.class]) text=value;
        } else if (DGIsNative(node,@"LynxMarkdownViewV2")) {
            id bundle=DGAIGetter(node,@"bundle");
            if (DGIsNative(bundle,@"LynxMarkdownBundleV2")) {
                id markdown=DGAIGetter(bundle,@"markdownView");
                if (DGIsNative(markdown,@"ServalMarkdownView")) {id value=DGAIGetter(markdown,@"getContent");if ([value isKindOfClass:NSString.class]) text=value;}
            }
        }
        if (text.length) {
            text=DGGeminiBoundText(text,24000-total);
            if (![seen containsObject:text]) {[segments addObject:text];[seen addObject:text];total+=text.length+2;}
            continue; // Do not duplicate a renderer's internal text nodes.
        }
        // For the legacy markdown renderer, read only its text descendants, never arbitrary comments/cards.
        if (DGIsNative(node,@"LynxMarkdownView")) {
            NSMutableArray *children=[NSMutableArray arrayWithArray:node.subviews.reverseObjectEnumerator.allObjects];NSUInteger read=0;
            while (children.count && read++<200 && total<24000) {
                UIView *child=children.lastObject;[children removeLastObject];
                if (child.hidden || child.alpha<0.01) continue;
                NSString *value=[child isKindOfClass:UILabel.class] ? [(UILabel *)child text] : [child isKindOfClass:UITextView.class] ? [(UITextView *)child text] : nil;
                if (value.length && ![seen containsObject:value]) {value=DGGeminiBoundText(value,24000-total);[segments addObject:value];[seen addObject:value];total+=value.length+2;}
                for (UIView *descendant in child.subviews.reverseObjectEnumerator) [children addObject:descendant];
            }
            continue;
        }
        for (UIView *child in node.subviews.reverseObjectEnumerator) [pending addObject:child];
    }
    return DGGeminiBoundText([segments componentsJoinedByString:@"\n\n"],24000);
}

static UIViewController *DGFindCommentAI(UIViewController *node,NSUInteger depth) {
    if (!node || depth>12) return nil;
    if (DGIsNative(node,DGCommentAIClass) && node.isViewLoaded && node.view.window && !node.view.hidden) return node;
    for (UIViewController *child in node.childViewControllers) {UIViewController *found=DGFindCommentAI(child,depth+1);if (found) return found;}
    return nil;
}
static NSString *DGSummaryForController(UIViewController *controller) {
    if (!DGIsNative(controller,DGCommentAIClass)) return @"";
    id content=DGAIGetter(controller,@"contentVC");
    UIView *root=[content isKindOfClass:UIViewController.class] && [content isViewLoaded] ? [content view] : controller.viewIfLoaded;
    NSString *summary=DGGeminiReadSummary(root);
    if (DGRecordAI) DGRecordAI(summary.length ? @"Gemini summary captured" : @"Gemini summary unavailable",1);
    return summary;
}
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

@interface DGGeminiEntry : NSObject
@property(nonatomic,weak) UIViewController *owner;
@property(nonatomic,strong) UIButton *button;
- (void)open;
@end
@implementation DGGeminiEntry
- (void)open {if (DGOn()) DGPresentChat(self.owner,DGSummaryForController(self.owner),nil);}
@end
static void DGAttachEntry(UIViewController *owner) {
    DGGeminiEntry *entry=objc_getAssociatedObject(owner,&DGEntryKey);
    if (!DGOn()) {entry.button.hidden=YES;return;}
    if (!owner.isViewLoaded || !owner.view.window) return;
    if (!entry) {
        entry=[DGGeminiEntry new];entry.owner=owner;entry.button=[UIButton buttonWithType:UIButtonTypeSystem];
        [entry.button setTitle:@"Ask Gemini · Your AI" forState:UIControlStateNormal];entry.button.accessibilityIdentifier=@"gemini-comment-entry";
        entry.button.backgroundColor=UIColor.secondarySystemBackgroundColor;entry.button.layer.cornerRadius=14;
        entry.button.translatesAutoresizingMaskIntoConstraints=NO;
        [entry.button addTarget:entry action:@selector(open) forControlEvents:UIControlEventTouchUpInside];
        [owner.view addSubview:entry.button];
        [NSLayoutConstraint activateConstraints:@[[entry.button.leadingAnchor constraintEqualToAnchor:owner.view.safeAreaLayoutGuide.leadingAnchor constant:12],[entry.button.trailingAnchor constraintEqualToAnchor:owner.view.safeAreaLayoutGuide.trailingAnchor constant:-12],[entry.button.bottomAnchor constraintEqualToAnchor:owner.view.safeAreaLayoutGuide.bottomAnchor constant:-8],[entry.button.heightAnchor constraintEqualToConstant:48]]];
        objc_setAssociatedObject(owner,&DGEntryKey,entry,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    entry.button.hidden=NO;[owner.view bringSubviewToFront:entry.button];
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
    Class cls=NSClassFromString(DGCommentAIClass);if (!cls || ![cls isSubclassOfClass:UIViewController.class]) return;
    if (!DGSendHookInstalled) DGSendHookInstalled=DGOverride(cls,@"inputViewSendQueryContext:sourceFrom:",@"v32@0:8@16q24",^id(IMP original) {
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
    if (!DGEntryHookInstalled) DGEntryHookInstalled=DGOverride(cls,@"commentAIParseTabDidEnter",@"v16@0:8",^id(IMP original) {
        return ^(UIViewController *owner) {((void (*)(id,SEL))original)(owner,NSSelectorFromString(@"commentAIParseTabDidEnter"));DGAttachEntry(owner);};
    });
    if (!DGLeaveHookInstalled) DGLeaveHookInstalled=DGOverride(cls,@"commentAIParseTabWillLeave",@"v16@0:8",^id(IMP original) {
        return ^(UIViewController *owner) {((void (*)(id,SEL))original)(owner,NSSelectorFromString(@"commentAIParseTabWillLeave"));DGGeminiEntry *entry=objc_getAssociatedObject(owner,&DGEntryKey);entry.button.hidden=YES;};
    });
}
NSDictionary *DGGeminiSnapshot(void) {
    return @{@"configured":@([DGConfig[@"api_key"] isKindOfClass:NSString.class] && [DGConfig[@"api_key"] length]>0),@"enabled":@(DGOn()),@"native_send_hook":@(DGSendHookInstalled),@"native_entry_hook":@(DGEntryHookInstalled),@"native_leave_hook":@(DGLeaveHookInstalled),@"model":[NSUserDefaults.standardUserDefaults boolForKey:@"DGGeminiFast"] ? DGGeminiFastModel : DGGeminiQualityModel};
}
