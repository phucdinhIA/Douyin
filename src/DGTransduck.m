#import "DGTransduck.h"
#import "DGMedia.h"
NSString *const DGClaudeModel=@"claude-sonnet-5";
static BOOL DGBackendString(id text,NSUInteger max) {return [text isKindOfClass:NSString.class] && [text length]>0 && [text length]<=max;}
NSDictionary *DGBackendConfig(void) {
    NSURL *url=[NSBundle.mainBundle URLForResource:@"transduck-private" withExtension:@"json" subdirectory:@"DouyinGuest.bundle"];
    NSData *data=url ? [NSData dataWithContentsOfURL:url] : nil;id root=data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL] : nil;
    return [root isKindOfClass:NSDictionary.class] ? root : @{};
}
static id DGBackendJSON(NSData *data) {return data.length && data.length<=8*1024*1024 ? [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL] : nil;}
static NSString *DGBackendFailure(NSInteger status) {
    if (status==401 || status==403) return @"Tài khoản dịch chưa được cấp quyền. Kiểm tra đăng nhập và quyền sử dụng.";
    if (status==429 || status==402) return @"Dịch đang bị giới hạn hoặc hết hạn mức. Không tự gửi lại yêu cầu.";
    return @"Dịch chưa trả kết quả hợp lệ. Bấm thử lại khi kết nối ổn định.";
}
NSDictionary *DGClaudeBody(NSArray *cues,NSString *videoID,NSString *title) {
    return DGClaudeBodyWithContext(cues,cues,videoID,title);
}
NSDictionary *DGClaudeBodyWithContext(NSArray *cues,NSArray *context,NSString *videoID,NSString *title) {
    if (!DGCaptionValidCues(cues) || !DGBackendString(videoID,160)) return nil;
    if (!DGCaptionValidCues(context)) return nil;
    NSUInteger contextCharacters=0;for (NSDictionary *cue in context) contextCharacters+=[cue[@"text"] length];
    BOOL full=[context.lastObject[@"end"] doubleValue]<=600 && contextCharacters<=12000;
    NSMutableArray *items=[NSMutableArray new];NSUInteger total=0;
    for (NSUInteger i=0;i<cues.count;i++) {
        NSDictionary *cue=cues[i];total+=[cue[@"text"] length];if (total>60000 || !DGBackendString(cue[@"text"],500)) return nil;
        NSUInteger at=[context indexOfObject:cue];if (at==NSNotFound) return nil;
        NSMutableDictionary *item=[@{@"index":cue[@"id"],@"text":cue[@"text"],@"start":cue[@"start"],@"end":cue[@"end"],@"googleTranslation":@""} mutableCopy];
        NSMutableArray *before=[NSMutableArray new],*after=[NSMutableArray new];
        // Include the whole short transcript once across the boundary items,
        // while translating only the bounded target batch. Other rows use the
        // extension's three preceding / two following context sentences.
        for (NSUInteger j=full && i==0 ? 0 : at>3 ? at-3 : 0;j<at;j++) [before addObject:@{@"text":context[j][@"text"]}];
        for (NSUInteger j=at+1;j<(full && i==cues.count-1 ? context.count : MIN(at+3,context.count));j++) [after addObject:@{@"text":context[j][@"text"]}];
        if (before.count) item[@"contextBefore"]=before;if (after.count) item[@"contextAfter"]=after;[items addObject:item];
    }
    return @{@"videoId":videoID,@"title":title ?: @"",@"model":DGClaudeModel,@"toLanguage":@"vi-VN",@"translationRulesEnabled":@NO,@"skipTranslation":@NO,@"subtitles":items};
}
static NSArray *DGClaudeRows(NSData *data,NSInteger status,NSArray *source,NSUInteger max,NSUInteger totalMax,NSString **failure) {
    id root=DGBackendJSON(data),items=[root isKindOfClass:NSDictionary.class] ? root[@"subtitleTranslateResults"] : nil;
    if (status!=200) {if (failure) *failure=DGBackendFailure(status);return nil;}
    if (!DGCaptionValidCues(source) || ![items isKindOfClass:NSArray.class]) {if (failure) *failure=@"Claude trả cấu trúc bản dịch không hợp lệ.";return nil;}
    if ([items count]!=source.count) {if (failure) *failure=[NSString stringWithFormat:@"Claude trả %lu/%lu đoạn dịch. Bản gốc và mốc thời gian đã được giữ lại.",(unsigned long)[items count],(unsigned long)source.count];return nil;}
    NSMutableDictionary *indexed=[NSMutableDictionary new];NSUInteger indexedCount=0;
    for (id item in items) {
        if (![item isKindOfClass:NSDictionary.class]) {if (failure) *failure=@"Claude trả đoạn dịch không hợp lệ.";return nil;}
        if (item[@"index"]) {
            id value=item[@"index"];NSString *key=[value isKindOfClass:NSNumber.class] ? [value stringValue] : [value isKindOfClass:NSString.class] ? value : nil;
            // IDs are exact nonnegative decimal integers, never inferred from timestamps.
            if (!key.length || [key rangeOfCharacterFromSet:NSCharacterSet.decimalDigitCharacterSet.invertedSet].location!=NSNotFound || indexed[key]) {if (failure) *failure=@"Claude trả ID đoạn dịch trùng hoặc không hợp lệ.";return nil;}
            indexed[key]=item;indexedCount++;
        }
    }
    if (indexedCount && indexedCount!=source.count) {if (failure) *failure=@"Claude trả ID không đầy đủ; chưa thể ghép đúng bản dịch.";return nil;}
    NSMutableArray *result=[NSMutableArray new];
    NSUInteger total=0;
    for (NSUInteger i=0;i<source.count;i++) {
        id item=indexedCount ? indexed[[source[i][@"id"] stringValue]] : items[i];NSString *text=item[@"translateResult"];
        if (!item) {if (failure) *failure=@"Claude trả ID khác bản gốc; chưa thể ghép đúng bản dịch.";return nil;}
        if (![text isKindOfClass:NSString.class] || ![text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].length) {if (failure) *failure=[NSString stringWithFormat:@"Claude chưa dịch đoạn %lu/%lu.",(unsigned long)i+1,(unsigned long)source.count];return nil;}
        total+=text.length;if (text.length>max || total>totalMax) {if (failure) *failure=@"Bản dịch vượt giới hạn dung lượng an toàn; không cắt bỏ nội dung.";return nil;}
        // useAiTranslate reports the provider's choice of engine, not completeness.
        for (NSUInteger j=0;j<text.length;j++) {unichar c=[text characterAtIndex:j];if (c>=0x3400 && c<=0x9fff) {if (failure) *failure=@"AI còn trả chữ Trung trong bản dịch. Giữ bản gốc để thử lại.";return nil;}}
        NSMutableDictionary *cue=[source[i] mutableCopy];cue[@"text"]=text;[result addObject:cue];
    }return result;
}
NSArray *DGClaudeAnswer(NSData *data,NSInteger status,NSArray *source,NSString **failure) {
    NSArray *result=DGClaudeRows(data,status,source,2000,200000,failure);return DGCaptionValidCues(result) ? result : nil;
}
NSArray *DGClaudeAnalysisSegments(NSString *source) {
    if (!DGBackendString(source,24000) || ![source stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].length) return nil;
    NSMutableArray *segments=[NSMutableArray new];NSUInteger offset=0;
    while (offset<source.length) {
        NSUInteger length=MIN((NSUInteger)400,source.length-offset);
        // Prefer paragraph/sentence boundaries; never cut a composed character.
        if (length<source.length-offset) {
            NSRange search=NSMakeRange(offset+length/2,length-length/2);
            NSRange end=[source rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\n。！？"] options:NSBackwardsSearch range:search];if (end.location!=NSNotFound) length=NSMaxRange(end)-offset;
        }
        NSRange range=[source rangeOfComposedCharacterSequencesForRange:NSMakeRange(offset,length)];NSUInteger index=segments.count;
        [segments addObject:@{@"id":@(index),@"start":@(index),@"end":@(index+1),@"text":[source substringWithRange:range]}];offset=NSMaxRange(range);
    }return segments;
}
NSString *DGClaudeAnalysisAnswer(NSData *data,NSInteger status,NSArray *segments,NSString **failure) {
    NSArray *rows=DGClaudeRows(data,status,segments,4096,96000,failure);if (!rows) return nil;
    NSMutableArray *pieces=[NSMutableArray new];for (NSDictionary *row in rows) [pieces addObject:row[@"text"]];
    NSString *answer=[pieces componentsJoinedByString:@"\n\n"];if (answer.length>96000) {if (failure) *failure=@"Bản dịch phân tích quá lớn; không cắt bỏ nội dung.";return nil;}return answer;
}
NSDictionary *DGClaudeResponseDiagnostics(NSData *data,NSInteger status,NSUInteger expected) {
    id root=DGBackendJSON(data),rows=[root isKindOfClass:NSDictionary.class] ? root[@"subtitleTranslateResults"] : nil;
    NSUInteger count=[rows isKindOfClass:NSArray.class] ? [rows count] : 0,max=0,empty=0,han=0;
    if ([rows isKindOfClass:NSArray.class]) for (id row in rows) {
        NSString *text=[row isKindOfClass:NSDictionary.class] ? row[@"translateResult"] : nil;
        if (![text isKindOfClass:NSString.class] || ![text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].length) {empty++;continue;}max=MAX(max,text.length);
        for (NSUInteger j=0;j<text.length;j++) {unichar c=[text characterAtIndex:j];if (c>=0x3400 && c<=0x9fff) {han++;break;}}
    }
    return @{@"http_status":@(status),@"expected_rows":@(expected),@"returned_rows":@(count),@"largest_row_characters":@(max),@"empty_rows":@(empty),@"han_rows":@(han)};
}
@interface DGTransduckClient ()
@property(nonatomic,strong) NSDictionary *config;
@property(nonatomic,strong) NSURLSession *session;
@property(nonatomic,strong) NSMutableSet *tasks;
@property(nonatomic,strong) NSMutableArray *loginWaiters;
@property(nonatomic,copy) NSString *sessionKey;
@property(nonatomic,copy) NSString *token;
@property(nonatomic) NSUInteger generation;
@end
@implementation DGTransduckClient
- (instancetype)initWithConfig:(NSDictionary *)config configuration:(NSURLSessionConfiguration *)configuration {
    if ((self=[super init])) {
        _config=[config copy];_tasks=[NSMutableSet new];_loginWaiters=[NSMutableArray new];_sessionKey=[@"DGTransduckSession:" stringByAppendingString:config[@"email"] ?: @"unconfigured"];_token=[NSUserDefaults.standardUserDefaults stringForKey:_sessionKey] ?: config[@"session"];
        NSURLSessionConfiguration *cfg=configuration ? [configuration copy] : NSURLSessionConfiguration.ephemeralSessionConfiguration;
        cfg.HTTPCookieStorage=nil;cfg.URLCredentialStorage=nil;cfg.URLCache=nil;cfg.HTTPShouldSetCookies=NO;cfg.timeoutIntervalForResource=120;
        _session=[NSURLSession sessionWithConfiguration:cfg delegate:self delegateQueue:nil];
    }return self;
}
- (void)login:(void (^)(BOOL))completion {
    if (!DGBackendString(self.config[@"email"],256) || !DGBackendString(self.config[@"password"],256)) {completion(NO);return;}
    [self.loginWaiters addObject:[completion copy]];if (self.loginWaiters.count>1) return;
    NSMutableURLRequest *r=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://yd.transduck.com/login"]];r.HTTPMethod=@"POST";r.timeoutInterval=30;r.HTTPShouldHandleCookies=NO;
    NSMutableCharacterSet *allowed=[NSCharacterSet.URLQueryAllowedCharacterSet mutableCopy];[allowed removeCharactersInString:@"&+=?#"];
    NSString *body=[NSString stringWithFormat:@"username=%@&password=%@",[self.config[@"email"] stringByAddingPercentEncodingWithAllowedCharacters:allowed],[self.config[@"password"] stringByAddingPercentEncodingWithAllowedCharacters:allowed]];
    r.HTTPBody=[body dataUsingEncoding:NSUTF8StringEncoding];[r setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    NSUInteger generation=self.generation;__weak DGTransduckClient *weakSelf=self;
    NSURLSessionDataTask *task=[self.session dataTaskWithRequest:r completionHandler:^(__unused NSData *data,NSURLResponse *response,NSError *error) {
        dispatch_async(dispatch_get_main_queue(),^{
            DGTransduckClient *owner=weakSelf;if (!owner || owner.generation!=generation) return;
            NSHTTPURLResponse *http=[response isKindOfClass:NSHTTPURLResponse.class] ? (id)response : nil;NSString *token=nil;
            if (!error && http.statusCode==200) for (NSHTTPCookie *cookie in [NSHTTPCookie cookiesWithResponseHeaderFields:http.allHeaderFields forURL:r.URL]) if ([cookie.name isEqual:@"SESSION"]) token=cookie.value;
            if (token.length) {owner.token=token;[NSUserDefaults.standardUserDefaults setObject:token forKey:owner.sessionKey];}else {owner.token=nil;[NSUserDefaults.standardUserDefaults removeObjectForKey:owner.sessionKey];}
            if (owner.event) owner.event(token.length ? @"Backend session ready" : @"Backend authentication failed");NSArray *waiters=[owner.loginWaiters copy];[owner.loginWaiters removeAllObjects];for (void (^waiter)(BOOL) in waiters) waiter(token.length>0);
        });
    }];[self.tasks addObject:task];[task resume];
}
- (void)post:(NSString *)path body:(NSDictionary *)body completion:(void (^)(NSData *,NSInteger,NSString *))completion {
    [self send:path body:body renew:YES completion:completion];
}
- (void)send:(NSString *)path body:(NSDictionary *)body renew:(BOOL)renew completion:(void (^)(NSData *,NSInteger,NSString *))completion {
    if (![path isEqual:@"/api/v2/ai-translate/translate"] || ![body isKindOfClass:NSDictionary.class]) {completion(nil,0,@"Cấu hình dịch chưa hợp lệ.");return;}
    if (!self.token.length) {[self login:^(BOOL ok) {if (ok) [self send:path body:body renew:NO completion:completion];else completion(nil,401,DGBackendFailure(401));}];return;}
    NSMutableURLRequest *r=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:[@"https://yd.transduck.com" stringByAppendingString:path]]];r.HTTPMethod=@"POST";r.timeoutInterval=120;r.HTTPShouldHandleCookies=NO;
    [r setValue:self.token forHTTPHeaderField:@"Ck"];[r setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];r.HTTPBody=[NSJSONSerialization dataWithJSONObject:body options:0 error:NULL];
    NSUInteger generation=self.generation;__weak DGTransduckClient *weakSelf=self;
    NSURLSessionDataTask *task=[self.session dataTaskWithRequest:r completionHandler:^(NSData *data,NSURLResponse *response,NSError *error) {
        dispatch_async(dispatch_get_main_queue(),^{
            DGTransduckClient *owner=weakSelf;if (!owner || owner.generation!=generation) return;
            NSInteger status=[response isKindOfClass:NSHTTPURLResponse.class] ? [(NSHTTPURLResponse *)response statusCode] : 0;
            if (owner.event) owner.event([NSString stringWithFormat:@"Backend HTTP %ld",(long)status]);
            if (status==401 && renew && !error) {
                if (owner.token.length && ![[r valueForHTTPHeaderField:@"Ck"] isEqual:owner.token]) {[owner send:path body:body renew:NO completion:completion];return;}
                [owner login:^(BOOL ok) {if (ok) [owner send:path body:body renew:NO completion:completion];else completion(nil,401,DGBackendFailure(401));}];return;
            }
            completion(data,status,error ? @"Kết nối dịch bị gián đoạn. Bấm thử lại." : nil);
        });
    }];[self.tasks addObject:task];[task resume];
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *))completionHandler {(void)session;(void)task;(void)response;(void)request;completionHandler(nil);}
- (void)cancel {self.generation++;for (NSURLSessionTask *task in self.tasks) [task cancel];[self.tasks removeAllObjects];[self.loginWaiters removeAllObjects];[self.session invalidateAndCancel];self.session=nil;}
- (void)dealloc {[_session invalidateAndCancel];}
@end
