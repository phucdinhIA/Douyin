#import "DGComments.h"
#import <objc/runtime.h>
@interface DGCommentPanel : UIView
@end
@implementation DGCommentPanel
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {UIView *hit=[super hitTest:point withEvent:event];return hit==self ? nil : hit;}
@end
static char DGAutoCommentsKey;
static NSMutableOrderedSet *DGSources;
static NSHashTable *DGCommentSessions;
static id DGRead(id object,NSString *name) {
    SEL sel=NSSelectorFromString(name);Method m=class_getInstanceMethod(object_getClass(object),sel);
    char *type=m ? method_copyReturnType(m) : NULL;BOOL safe=type && type[0]=='@' && method_getNumberOfArguments(m)==2;free(type);
    if (!safe) return nil;@try {return ((id (*)(id,SEL))method_getImplementation(m))(object,sel);}@catch (__unused NSException *error) {return nil;}
}
static NSAttributedString *DGCommentAttributed(UIView *view) {
    id layout=DGRead(view,@"textLayout"),text=DGRead(layout,@"text");
    if (![text isKindOfClass:NSAttributedString.class] || ![text length]) text=DGRead(view,@"attributedText");
    return [text isKindOfClass:NSAttributedString.class] ? text : nil;
}
NSString *DGCommentVisibleText(UIView *view) {
    NSAttributedString *a=DGCommentAttributed(view);if (a.length) return a.string;
    id text=DGRead(view,@"text");return [text isKindOfClass:NSString.class] ? text : nil;
}
static BOOL DGVisible(UIView *view,UIView *root) {
    CGRect rect=[view convertRect:view.bounds toView:root];rect=CGRectIntersection(rect,root.bounds);
    for (UIView *p=view;p && p!=root;p=p.superview) {
        if (p.hidden || p.alpha<0.01) return NO;
        if (p.clipsToBounds) rect=CGRectIntersection(rect,[p convertRect:p.bounds toView:root]);
        NSString *name=NSStringFromClass(p.class);
        if ([name containsString:@"AIParse"] || [name containsString:@"Lynx"] || [name containsString:@"Serval"] || [name containsString:@"AISummary"]) return NO;
    }return !CGRectIsEmpty(rect) && !CGRectIsNull(rect);
}
static BOOL DGHan(NSString *text) {for (NSUInteger i=0;i<text.length;i++) {unichar c=[text characterAtIndex:i];if (c>=0x3400 && c<=0x9fff) return YES;}return NO;}
@interface DGAutoComments : NSObject <UITableViewDataSource,UITableViewDelegate>
@property(nonatomic,weak) UIViewController *owner;
@property(nonatomic,weak) UIScrollView *nativeScroll;
@property(nonatomic,strong) UIView *panel;
@property(nonatomic,strong) UITableView *table;
@property(nonatomic,strong) UIButton *status;
@property(nonatomic,strong) UISegmentedControl *language;
@property(nonatomic,strong) NSMutableArray *sources;
@property(nonatomic,strong) DGMediaClient *client;
@property(nonatomic,strong) NSTimer *timer;
@property(nonatomic,strong) NSMutableDictionary *answers;
@property(nonatomic,strong) NSMutableSet *attempted;
@property(nonatomic,copy) NSString *pending;
@property(nonatomic,copy) void (^record)(NSString *,NSUInteger);
@property(nonatomic) BOOL active;
@property(nonatomic) BOOL dirty;
@property(nonatomic) NSUInteger generation;
- (void)scan;
- (void)stop;
@end
@implementation DGAutoComments
- (void)attach {
    UIView *root=self.owner.view;NSMutableArray *nodes=[NSMutableArray arrayWithObject:root];UIScrollView *scroll=nil;CGFloat area=0;
    while (nodes.count) {UIView *v=nodes.lastObject;[nodes removeLastObject];if (v.hidden || v.alpha<0.01) continue;
        if ([v isKindOfClass:UIScrollView.class] && ![v isKindOfClass:UITextView.class]) {CGRect r=[v convertRect:v.bounds toView:root];CGFloat size=r.size.width*r.size.height;if (r.size.height>150 && r.size.width>200 && size>area) {scroll=(id)v;area=size;}}
        [nodes addObjectsFromArray:v.subviews];
    }
    self.nativeScroll=scroll;self.panel=[DGCommentPanel new];self.panel.accessibilityIdentifier=@"comments-translation-panel";self.panel.backgroundColor=UIColor.systemBackgroundColor;self.panel.translatesAutoresizingMaskIntoConstraints=NO;
    UIView *surface=scroll.superview ?: root;[surface addSubview:self.panel];
    self.language=[[UISegmentedControl alloc] initWithItems:@[@"Tiếng Việt",@"Bản gốc"]];self.language.selectedSegmentIndex=0;self.language.accessibilityIdentifier=@"comments-language";[self.language addTarget:self action:@selector(languageChanged) forControlEvents:UIControlEventValueChanged];
    self.status=[UIButton buttonWithType:UIButtonTypeSystem];self.status.accessibilityIdentifier=@"gtx-comments-button";self.status.titleLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];[self.status setTitle:@"Đang dịch bình luận…" forState:UIControlStateNormal];[self.status addTarget:self action:@selector(retry) forControlEvents:UIControlEventTouchUpInside];
    self.table=[[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];self.table.accessibilityIdentifier=@"comments-vietnamese-table";self.table.dataSource=self;self.table.delegate=self;self.table.rowHeight=UITableViewAutomaticDimension;self.table.estimatedRowHeight=110;
    for (UIView *v in @[self.language,self.status,self.table]) {v.translatesAutoresizingMaskIntoConstraints=NO;[self.panel addSubview:v];}
    [NSLayoutConstraint activateConstraints:@[
        [self.panel.leadingAnchor constraintEqualToAnchor:scroll ? scroll.leadingAnchor : root.safeAreaLayoutGuide.leadingAnchor],
        [self.panel.trailingAnchor constraintEqualToAnchor:scroll ? scroll.trailingAnchor : root.safeAreaLayoutGuide.trailingAnchor],
        [self.panel.topAnchor constraintEqualToAnchor:scroll ? scroll.topAnchor : root.safeAreaLayoutGuide.topAnchor constant:scroll ? 0 : 90],
        [self.panel.bottomAnchor constraintEqualToAnchor:scroll ? scroll.bottomAnchor : root.safeAreaLayoutGuide.bottomAnchor constant:scroll ? 0 : -50],
        [self.language.topAnchor constraintEqualToAnchor:self.panel.topAnchor constant:8],[self.language.leadingAnchor constraintEqualToAnchor:self.panel.leadingAnchor constant:12],[self.language.trailingAnchor constraintEqualToAnchor:self.panel.trailingAnchor constant:-12],
        [self.status.topAnchor constraintEqualToAnchor:self.language.bottomAnchor constant:4],[self.status.leadingAnchor constraintEqualToAnchor:self.panel.leadingAnchor constant:12],[self.status.trailingAnchor constraintEqualToAnchor:self.panel.trailingAnchor constant:-12],[self.status.heightAnchor constraintEqualToConstant:30],
        [self.table.topAnchor constraintEqualToAnchor:self.status.bottomAnchor constant:4],[self.table.bottomAnchor constraintEqualToAnchor:self.panel.bottomAnchor],[self.table.leadingAnchor constraintEqualToAnchor:self.panel.leadingAnchor],[self.table.trailingAnchor constraintEqualToAnchor:self.panel.trailingAnchor]]];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(provider:) name:@"DGCommentProviderStatus" object:nil];
}
- (void)provider:(NSNotification *)note {if ([note.object isKindOfClass:NSString.class]) [self.status setTitle:note.object forState:UIControlStateNormal];}
- (void)languageChanged {BOOL original=self.language.selectedSegmentIndex==1;self.table.hidden=original;self.status.hidden=original;self.panel.backgroundColor=original ? UIColor.clearColor : UIColor.systemBackgroundColor;
    // Original mode exposes the native list below a small language switch.
    self.panel.userInteractionEnabled=YES;
}
- (void)retry {[self.attempted removeAllObjects];[self scan];}
- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {(void)table;(void)section;return self.sources.count+(self.nativeScroll ? 1 : 0);}
- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)path {
    UITableViewCell *cell=[table dequeueReusableCellWithIdentifier:@"translated-comment"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"translated-comment"];
    cell.textLabel.numberOfLines=0;cell.textLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleBody];cell.detailTextLabel.numberOfLines=0;cell.detailTextLabel.font=[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];cell.detailTextLabel.textColor=UIColor.secondaryLabelColor;
    if ((NSUInteger)path.row>=self.sources.count) {cell.textLabel.text=@"Đọc thêm bình luận";cell.detailTextLabel.text=@"Hoặc chọn Bản gốc để cuộn, xem ảnh và trả lời.";cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;return cell;}
    NSString *source=self.sources[path.row];cell.textLabel.text=self.answers[source] ?: @"Đang dịch…";cell.detailTextLabel.text=source;cell.accessoryType=UITableViewCellAccessoryNone;cell.accessibilityIdentifier=@"translated-comment-row";return cell;
}
- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)path {[table deselectRowAtIndexPath:path animated:YES];if ((NSUInteger)path.row==self.sources.count && self.nativeScroll) {CGFloat bottom=MAX(-self.nativeScroll.adjustedContentInset.top,self.nativeScroll.contentSize.height-self.nativeScroll.bounds.size.height+self.nativeScroll.adjustedContentInset.bottom);CGFloat y=MIN(bottom,self.nativeScroll.contentOffset.y+self.nativeScroll.bounds.size.height*0.65);[self.nativeScroll setContentOffset:CGPointMake(self.nativeScroll.contentOffset.x,y) animated:NO];[self scan];}}
- (void)scan {
    if (!self.active || !self.owner.isViewLoaded || !self.owner.view.window || self.owner.view.hidden || UIApplication.sharedApplication.applicationState!=UIApplicationStateActive) {[self stop];return;}
    UIView *root=self.owner.view.window;NSMutableArray *nodes=[NSMutableArray arrayWithObject:root];NSUInteger visited=0;NSMutableArray *next=[NSMutableArray new];NSUInteger characters=0;
    Class native=NSClassFromString(@"_TtC28AWECommentPanelListSwiftImpl20BaseCellCommentLabel");
    while (nodes.count && visited++<1800) {
        UIView *node=nodes.lastObject;[nodes removeLastObject];if (node.hidden || node.alpha<0.01 || [node isKindOfClass:DGCommentPanel.class]) continue;
        [nodes addObjectsFromArray:node.subviews.reverseObjectEnumerator.allObjects];
        if (!DGVisible(node,root)) continue;NSString *text=DGCommentVisibleText(node);
        if (!text.length || text.length>2000) continue;
        BOOL semantic=(native && [node isKindOfClass:native]) || [DGSources containsObject:text];
        if (!semantic || !DGHan(text) || [node isKindOfClass:UITextView.class] || [node isKindOfClass:UIControl.class]) continue;
        if (![self.sources containsObject:text]) {[self.sources addObject:text];self.dirty=YES;}
        NSString *answer=self.answers[text];if (answer) {}
        else if (next.count<8 && ![self.attempted containsObject:text] && ![next containsObject:text] && characters+text.length<=2000 && ![text containsString:@"__DG_COMMENT_"]) {[next addObject:text];characters+=text.length;}
    }
    if (self.sources.count && !self.panel) [self attach];
    if (self.panel && self.dirty) {[self.table reloadData];self.dirty=NO;}
    if (self.pending || !next.count) return;self.pending=@"batch";[self.status setTitle:@"GTX · đang dịch" forState:UIControlStateNormal];[self.attempted addObjectsFromArray:next];
    if (self.record) self.record(@"GTX visible source captured",next.count);NSUInteger generation=self.generation;__weak DGAutoComments *weakSelf=self;
    [self.client translateComments:next completion:^(NSDictionary *answers,NSString *failure) {
        DGAutoComments *s=weakSelf;if (!s || !s.active || s.generation!=generation) return;
        s.pending=nil;if (answers) {[s.answers addEntriesFromDictionary:answers];s.dirty=YES;if (s.record) s.record(@"Comments translated rows",answers.count);}
        if (!failure && ![s.status.currentTitle containsString:@"Gemini"]) [s.status setTitle:@"GTX · đã dịch" forState:UIControlStateNormal];
        if (s.record) s.record(!failure ? @"GTX automatic ready" : @"GTX automatic failed",1);
        // Stop this panel's queue after transport/quota failure; avoid a request storm.
        if (failure) {
            if ([failure containsString:@"giới hạn"] && s.record) s.record(@"GTX automatic rate limited",1);
            [s.status setTitle:@"Dịch lỗi · thử lại" forState:UIControlStateNormal];return;
        }[s scan];
    }];
}
- (void)stop {[self.panel removeFromSuperview];[NSNotificationCenter.defaultCenter removeObserver:self name:@"DGCommentProviderStatus" object:nil];self.panel=nil;self.table=nil;self.status=nil;self.language=nil;self.active=NO;self.generation++;[self.timer invalidate];self.timer=nil;[self.client cancel];self.pending=nil;}
- (void)dealloc {[_timer invalidate];[_client cancel];[NSNotificationCenter.defaultCenter removeObserver:self];}
@end
void DGCommentsStart(UIViewController *owner,DGMediaClient *client,void (^record)(NSString *,NSUInteger)) {
    DGAutoComments *s=objc_getAssociatedObject(owner,&DGAutoCommentsKey);if (s.active) return;
    if (!s) {s=[DGAutoComments new];s.owner=owner;s.answers=[NSMutableDictionary new];s.sources=[NSMutableArray new];s.attempted=[NSMutableSet new];objc_setAssociatedObject(owner,&DGAutoCommentsKey,s,OBJC_ASSOCIATION_RETAIN_NONATOMIC);}
    [s.attempted removeAllObjects];[s.sources removeAllObjects];s.client=client;s.record=record;s.active=YES;s.dirty=YES;s.generation++;
    if (!DGCommentSessions) DGCommentSessions=[NSHashTable weakObjectsHashTable];
    for (DGAutoComments *other in DGCommentSessions.allObjects) if (other!=s) [other stop];[DGCommentSessions addObject:s];
    __weak DGAutoComments *weakSelf=s;s.timer=[NSTimer timerWithTimeInterval:0.35 repeats:YES block:^(__unused NSTimer *t) {[weakSelf scan];}];[NSRunLoop.mainRunLoop addTimer:s.timer forMode:NSRunLoopCommonModes];
    [NSNotificationCenter.defaultCenter removeObserver:s];[NSNotificationCenter.defaultCenter addObserver:s selector:@selector(stop) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [s scan];
}
void DGCommentsStop(UIViewController *owner) {[objc_getAssociatedObject(owner,&DGAutoCommentsKey) stop];}
void DGCommentsInstall(void) {
    if (DGSources) return;DGSources=[NSMutableOrderedSet new];Class cls=NSClassFromString(@"AWECommentResponseModel");
    Method m=class_getInstanceMethod(cls,NSSelectorFromString(@"commentArray"));if (!m || strcmp(method_getTypeEncoding(m),"@16@0:8")) return;IMP original=method_getImplementation(m);
    IMP replacement=imp_implementationWithBlock(^id(id object) {
        id list=((id (*)(id,SEL))original)(object,NSSelectorFromString(@"commentArray"));
        if (NSThread.isMainThread && [list isKindOfClass:NSArray.class]) for (id model in list) {
            NSString *text=DGRead(model,@"content");if ([text isKindOfClass:NSString.class] && text.length && text.length<=2000) [DGSources addObject:text];
        }
        while (DGSources.count>1000) [DGSources removeObjectAtIndex:0];return list;
    });class_replaceMethod(cls,NSSelectorFromString(@"commentArray"),replacement,method_getTypeEncoding(m));
}
