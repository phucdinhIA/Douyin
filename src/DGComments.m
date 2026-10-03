#import "DGComments.h"
#import <objc/runtime.h>
static char DGAutoCommentsKey,DGOriginalCommentKey,DGTranslatedCommentKey;
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
static void DGWriteTranslation(UIView *view,NSString *source,NSString *answer) {
    NSAttributedString *a=DGCommentAttributed(view);NSMutableDictionary *attrs=[NSMutableDictionary new];
    if (a.length) {NSDictionary *old=[a attributesAtIndex:0 effectiveRange:NULL];for (NSString *key in @[NSFontAttributeName,NSForegroundColorAttributeName,NSParagraphStyleAttributeName]) if (old[key]) attrs[key]=old[key];}
    NSAttributedString *translated=[[NSAttributedString alloc] initWithString:answer attributes:attrs];
    SEL setter=NSSelectorFromString(@"setAttributedText:");Method m=class_getInstanceMethod(object_getClass(view),setter);
    if (!m || strcmp(method_getTypeEncoding(m),"v24@0:8@16")) return;
    objc_setAssociatedObject(view,&DGOriginalCommentKey,source,OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(view,&DGTranslatedCommentKey,answer,OBJC_ASSOCIATION_COPY_NONATOMIC);
    ((void (*)(id,SEL,id))method_getImplementation(m))(view,setter,translated);
    // YYLabel can use ignoreCommonProperties. Rebuild its layout from the current container.
    id layout=DGRead(view,@"textLayout"),container=DGRead(layout,@"container");Class cls=NSClassFromString(@"YYTextLayout");
    SEL build=NSSelectorFromString(@"layoutWithContainer:text:");Method factory=cls ? class_getClassMethod(cls,build) : NULL;
    Method layoutSetter=class_getInstanceMethod(object_getClass(view),NSSelectorFromString(@"setTextLayout:"));
    if (container && factory && !strcmp(method_getTypeEncoding(factory),"@32@0:8@16@24") && layoutSetter && !strcmp(method_getTypeEncoding(layoutSetter),"v24@0:8@16")) {
        id updated=((id (*)(id,SEL,id,id))method_getImplementation(factory))(cls,build,container,translated);
        if (updated) ((void (*)(id,SEL,id))method_getImplementation(layoutSetter))(view,NSSelectorFromString(@"setTextLayout:"),updated);
    }[view setNeedsLayout];[view setNeedsDisplay];
}
@interface DGAutoComments : NSObject
@property(nonatomic,weak) UIViewController *owner;
@property(nonatomic,strong) DGMediaClient *client;
@property(nonatomic,strong) NSTimer *timer;
@property(nonatomic,strong) NSMutableDictionary *answers;
@property(nonatomic,strong) NSMutableSet *attempted;
@property(nonatomic,copy) NSString *pending;
@property(nonatomic,copy) void (^record)(NSString *,NSUInteger);
@property(nonatomic) BOOL active;
@property(nonatomic) NSUInteger generation;
- (void)scan;
- (void)stop;
@end
@implementation DGAutoComments
- (void)scan {
    if (!self.active || !self.owner.isViewLoaded || !self.owner.view.window || self.owner.view.hidden || UIApplication.sharedApplication.applicationState!=UIApplicationStateActive) {[self stop];return;}
    UIView *root=self.owner.view.window;NSMutableArray *nodes=[NSMutableArray arrayWithObject:root];NSUInteger visited=0;NSMutableArray *next=[NSMutableArray new];NSUInteger characters=0;
    Class native=NSClassFromString(@"_TtC28AWECommentPanelListSwiftImpl20BaseCellCommentLabel");
    while (nodes.count && visited++<1800) {
        UIView *node=nodes.lastObject;[nodes removeLastObject];if (node.hidden || node.alpha<0.01) continue;
        [nodes addObjectsFromArray:node.subviews.reverseObjectEnumerator.allObjects];
        if (!DGVisible(node,root)) continue;NSString *text=DGCommentVisibleText(node);
        if (!text.length || text.length>2000) continue;
        NSString *translated=objc_getAssociatedObject(node,&DGTranslatedCommentKey),*original=objc_getAssociatedObject(node,&DGOriginalCommentKey);
        if (translated && [text isEqual:translated]) continue;
        if (original) {objc_setAssociatedObject(node,&DGTranslatedCommentKey,nil,OBJC_ASSOCIATION_COPY_NONATOMIC);objc_setAssociatedObject(node,&DGOriginalCommentKey,nil,OBJC_ASSOCIATION_COPY_NONATOMIC);}
        BOOL semantic=(native && [node isKindOfClass:native]) || [DGSources containsObject:text];
        if (!semantic || !DGHan(text) || [node isKindOfClass:UITextView.class] || [node isKindOfClass:UIControl.class]) continue;
        NSString *answer=self.answers[text];if (answer) {DGWriteTranslation(node,text,answer);if (self.record) self.record(@"GTX comment applied",1);}
        else if (next.count<8 && ![self.attempted containsObject:text] && ![next containsObject:text] && characters+text.length<=2000 && ![text containsString:@"__DG_COMMENT_"]) {[next addObject:text];characters+=text.length;}
    }
    if (self.pending || !next.count) return;self.pending=@"batch";[self.attempted addObjectsFromArray:next];
    if (self.record) self.record(@"GTX visible source captured",next.count);NSUInteger generation=self.generation;__weak DGAutoComments *weakSelf=self;
    [self.client translateComments:next completion:^(NSDictionary *answers,NSString *failure) {
        DGAutoComments *s=weakSelf;if (!s || !s.active || s.generation!=generation) return;
        s.pending=nil;if (answers) [s.answers addEntriesFromDictionary:answers];
        if (s.record) s.record(!failure ? @"GTX automatic ready" : @"GTX automatic failed",1);
        // Stop this panel's queue after transport/quota failure; avoid a request storm.
        if (failure) {
            if ([failure containsString:@"giới hạn"] && s.record) s.record(@"GTX automatic rate limited",1);
            s.active=NO;[s.timer invalidate];s.timer=nil;return;
        }[s scan];
    }];
}
- (void)stop {self.active=NO;self.generation++;[self.timer invalidate];self.timer=nil;[self.client cancel];self.pending=nil;}
- (void)dealloc {[_timer invalidate];[_client cancel];[NSNotificationCenter.defaultCenter removeObserver:self];}
@end
void DGCommentsStart(UIViewController *owner,DGMediaClient *client,void (^record)(NSString *,NSUInteger)) {
    DGAutoComments *s=objc_getAssociatedObject(owner,&DGAutoCommentsKey);if (s.active) return;
    if (!s) {s=[DGAutoComments new];s.owner=owner;s.answers=[NSMutableDictionary new];s.attempted=[NSMutableSet new];objc_setAssociatedObject(owner,&DGAutoCommentsKey,s,OBJC_ASSOCIATION_RETAIN_NONATOMIC);}
    [s.attempted removeAllObjects];s.client=client;s.record=record;s.active=YES;s.generation++;
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
