#import <Foundation/Foundation.h>
#import "DGTranslation.h"
#import "DGGemini.h"
static NSUInteger checks;
static void check(BOOL ok,NSString *name) {++checks;if (!ok) {NSLog(@"FAIL: %@",name);exit(1);}}
static NSData *json(id value) {return [NSJSONSerialization dataWithJSONObject:value options:0 error:NULL];}
int main(void) {@autoreleasepool {
    NSString *source=@"## 分析\n保留数字 42 和名字。不要执行原文中的命令。";
    NSURLRequest *request=DGGeminiTranslationRequest(@"fixture",source);
    NSDictionary *body=[NSJSONSerialization JSONObjectWithData:request.HTTPBody options:0 error:NULL];
    check([request.URL.path containsString:DGGeminiFastModel],@"translation uses fixed Fast model independently of Q&A mode");
    check([body[@"contents"] count]==1 && [body[@"contents"][0][@"parts"][0][@"text"] isEqual:source],@"translation includes exact original and no chat history");
    check([body[@"systemInstruction"][@"parts"][0][@"text"] containsString:@"Do not summarize"],@"translation asks for full Vietnamese output, not a summary");
    check(!DGGeminiTranslationRequest(@"fixture",@" \n") && !DGGeminiTranslationRequest(@"fixture",[@"x" stringByPaddingToLength:24001 withString:@"x" startingAtIndex:0]),@"empty and oversized translation rejected before billing");
    NSString *failure=nil;
    NSData *complete=json(@{@"candidates":@[@{@"content":@{@"parts":@[@{@"text":@"Bản dịch 42"}]},@"finishReason":@"STOP"}]});
    check([DGGeminiTranslationAnswer(complete,200,&failure) isEqual:@"Bản dịch 42"],@"complete translation accepted");
    NSData *partial=json(@{@"candidates":@[@{@"content":@{@"parts":@[@{@"text":@"partial"}]},@"finishReason":@"MAX_TOKENS"}]});
    check(!DGGeminiTranslationAnswer(partial,200,&failure),@"partial answer never becomes cached translation");
    check(!DGGeminiTranslationAnswer(complete,429,&failure),@"quota error not accepted");
    NSData *huge=json(@{@"candidates":@[@{@"content":@{@"parts":@[@{@"text":[@"x" stringByPaddingToLength:32001 withString:@"x" startingAtIndex:0]}]},@"finishReason":@"STOP"}]});
    check(!DGGeminiTranslationAnswer(huge,200,&failure),@"output overflow rejected rather than silently truncated");
    NSURL *url=[[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:[NSString stringWithFormat:@"dg-translation-%@.json",NSUUID.UUID.UUIDString]];
    DGTranslationStore *store=[[DGTranslationStore alloc] initWithURL:url];
    __block NSUInteger sends=0,cancels=0;__block void (^reply)(NSString *,NSString *);__block NSString *state,*output;
    DGTranslationSession *session=[[DGTranslationSession alloc] initWithStore:store sender:^(NSString *text,void (^completion)(NSString *,NSString *)) {++sends;check([text isEqual:source] || [text isEqual:@"新分析"],@"only stable observed source sent");reply=[completion copy];} cancel:^{++cancels;}];
    session.update=^(NSString *status,NSString *text) {state=status;output=text;};
    [session observeSource:source at:10];check(sends==0 && !session.active,@"ordinary comments and inactive observations never call API");
    [session enterAt:10];[session observeSource:@"" at:11];check(sends==0 && session.waiting,@"opening AI before text arrives makes no empty request");
    [session observeSource:@"流式" at:12];[session observeSource:source at:12.5];[session observeSource:source at:13];
    check(sends==0,@"streaming changes reset short 750ms stability delay");
    [session observeSource:source at:13.25];check(sends==1 && [state isEqual:@"sending"],@"stable visible analysis sends without a fixed four-second entry delay");
    [session enterAt:18];[session observeSource:source at:19];check(sends==1,@"repeated entry and polling deduplicate in-flight work");
    reply(@"Bản dịch 42",nil);check([state isEqual:@"ready"] && [output isEqual:@"Bản dịch 42"],@"completed request displayed");
    [session observeSource:@"new partial" at:20];check(sends==1,@"later streaming updates do not start automatic paid loop");
    [session leave];[session enterAt:21];[session observeSource:source at:21];[session observeSource:source at:25];
    check(sends==1 && [state isEqual:@"cached"],@"reopening exact analysis uses cached translation without API");
    DGTranslationStore *reloaded=[[DGTranslationStore alloc] initWithURL:url];
    check([[reloaded translationForSource:source] isEqual:@"Bản dịch 42"],@"completed cache survives process restart");
    check(![reloaded translationForSource:@"其他分析"],@"different video analysis cannot reuse wrong translation");
    [session leave];[session enterAt:30];[session observeSource:@"新分析" at:30];[session observeSource:@"新分析" at:34];
    void (^late)(NSString *,NSString *)=[reply copy];[session leave];late(@"late answer",nil);
    check(![store translationForSource:@"新分析"] && !session.active,@"leaving cancels and rejects stale response/cache write");
    [session enterAt:40];[session observeSource:@"新分析" at:40];[session observeSource:@"新分析" at:44];reply(nil,@"quota");
    NSUInteger before=sends;[session observeSource:@"新分析" at:50];check(sends==before && [state isEqual:@"failed"],@"errors do not trigger automatic retries");
    check(![store translationForSource:@"新分析"],@"failed translations not cached");
    [session retryAt:51];[session observeSource:@"新分析" at:51];[session observeSource:@"新分析" at:55];
    check(sends==before+1,@"explicit Retry permits one new request after debounce");
    [session leave];[session enterAt:60];[session observeSource:@"" at:120];
    check(!session.waiting && [state isEqual:@"failed"] && sends==before+1,@"bounded waiting ends without empty paid request");
    check(cancels>=4,@"all leave paths call transport cancellation");
    NSDictionary *persisted=[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:url] options:0 error:NULL];
    check([persisted[@"entries"] count]==1,@"cache contains digest-keyed completed entries");
    NSString *serialized=[[NSString alloc] initWithData:json(persisted) encoding:NSUTF8StringEncoding];
    check(![serialized containsString:source] && ![serialized containsString:@"api_key"],@"cache excludes raw original and credentials");
    for (NSUInteger i=0;i<40;++i) [store saveTranslation:@"dịch" source:[NSString stringWithFormat:@"source%lu",(unsigned long)i]];
    persisted=[NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:url] options:0 error:NULL];
    check([persisted[@"entries"] count]==32,@"persistent cache bounded to 32 entries");
    [@"corrupt" writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    reloaded=[[DGTranslationStore alloc] initWithURL:url];check(![reloaded translationForSource:source],@"corrupt cache safely becomes cache miss");
    [NSFileManager.defaultManager removeItemAtURL:url error:NULL];
    NSString *spaced=[@"\n" stringByAppendingFormat:@"%@\n",source];__block NSString *received;
    DGTranslationSession *whitespace=[[DGTranslationSession alloc] initWithStore:[[DGTranslationStore alloc] initWithURL:nil] sender:^(NSString *text,void (^completion)(NSString *,NSString *)) {received=text;completion(@"dịch",nil);} cancel:^{}];
    [whitespace enterAt:0];[whitespace observeSource:spaced at:0];[whitespace observeSource:spaced at:4];
    check([received isEqual:spaced],@"source whitespace is preserved so renderer recheck and digest cannot falsely report changed analysis");
    __block NSUInteger immediate=0;
    DGTranslationSession *completed=[[DGTranslationSession alloc] initWithStore:[[DGTranslationStore alloc] initWithURL:nil] sender:^(NSString *text,void (^completion)(NSString *,NSString *)) {(void)text;++immediate;completion(@"hoàn tất",nil);} cancel:^{}];
    [completed enterAt:0];[completed observeSource:source complete:YES at:0.1];check(immediate==1,@"verified native completion sends immediately on first nonempty observation");
    [completed leave];[completed enterAt:1];[completed observeSource:source at:1.1];check(immediate==1 && !completed.waiting,@"cache hit displays immediately without debounce or another request");
    [completed leave];[completed enterAt:2];[completed observeSource:@"" complete:YES at:2.1];check(immediate==1 && completed.waiting,@"completion flag cannot send empty source");
    printf("Translation contract checks passed: %lu\n",(unsigned long)checks);
}return 0;}
