#import "DGTransduck.h"
#import "DGMedia.h"
#import <CommonCrypto/CommonDigest.h>
NSString *const DGClaudeModel=@"claude-sonnet-5";
NSString *const DGNamMinhVoice=@"vi-VN-NamMinhNeural";
static BOOL DGBackendString(id text,NSUInteger max) {return [text isKindOfClass:NSString.class] && [text length]>0 && [text length]<=max;}
NSDictionary *DGBackendConfig(void) {
    NSURL *url=[NSBundle.mainBundle URLForResource:@"transduck-private" withExtension:@"json" subdirectory:@"DouyinGuest.bundle"];
    NSData *data=url ? [NSData dataWithContentsOfURL:url] : nil;id root=data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL] : nil;
    return [root isKindOfClass:NSDictionary.class] ? root : @{};
}
static id DGBackendJSON(NSData *data) {return data.length && data.length<=8*1024*1024 ? [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL] : nil;}
static NSString *DGBackendFailure(NSInteger status) {
    if (status==401 || status==403) return @"Tài khoản dịch/lồng tiếng chưa được cấp quyền. Kiểm tra đăng nhập và quyền sử dụng.";
    if (status==429 || status==402) return @"Dịch/lồng tiếng đang bị giới hạn hoặc hết hạn mức. Không tự gửi lại yêu cầu.";
    return @"Dịch/lồng tiếng chưa trả kết quả hợp lệ. Bấm thử lại khi kết nối ổn định.";
}
NSDictionary *DGClaudeBody(NSArray *cues,NSString *videoID,NSString *title) {
    if (!DGCaptionValidCues(cues) || !DGBackendString(videoID,160)) return nil;
    NSMutableArray *items=[NSMutableArray new];NSUInteger total=0;
    for (NSUInteger i=0;i<cues.count;i++) {
        NSDictionary *cue=cues[i];total+=[cue[@"text"] length];if (total>60000) return nil;
        NSMutableDictionary *item=[@{@"index":cue[@"id"],@"text":cue[@"text"],@"start":cue[@"start"],@"end":cue[@"end"],@"googleTranslation":@""} mutableCopy];
        NSMutableArray *before=[NSMutableArray new],*after=[NSMutableArray new];
        for (NSUInteger j=i>3 ? i-3 : 0;j<i;j++) [before addObject:@{@"text":cues[j][@"text"]}];
        for (NSUInteger j=i+1;j<MIN(i+3,cues.count);j++) [after addObject:@{@"text":cues[j][@"text"]}];
        if (before.count) item[@"contextBefore"]=before;if (after.count) item[@"contextAfter"]=after;[items addObject:item];
    }
    return @{@"videoId":videoID,@"title":title ?: @"",@"model":DGClaudeModel,@"toLanguage":@"vi-VN",@"translationRulesEnabled":@NO,@"skipTranslation":@NO,@"subtitles":items};
}
NSArray *DGClaudeAnswer(NSData *data,NSInteger status,NSArray *source,NSString **failure) {
    id root=DGBackendJSON(data),items=[root isKindOfClass:NSDictionary.class] ? root[@"subtitleTranslateResults"] : nil;
    if (status!=200 || !DGCaptionValidCues(source) || ![items isKindOfClass:NSArray.class] || [items count]!=source.count) {if (failure) *failure=DGBackendFailure(status);return nil;}
    NSMutableArray *result=[NSMutableArray new];
    for (NSUInteger i=0;i<source.count;i++) {
        id item=items[i];NSString *text=[item isKindOfClass:NSDictionary.class] ? item[@"translateResult"] : nil;
        if (!DGBackendString(text,2000) || ![item[@"useAiTranslate"] isEqual:@YES] || (item[@"index"] && ![item[@"index"] isEqual:source[i][@"id"]])) {if (failure) *failure=@"AI chưa trả đủ bản dịch theo từng mốc phụ đề.";return nil;}
        for (NSUInteger j=0;j<text.length;j++) {unichar c=[text characterAtIndex:j];if (c>=0x3400 && c<=0x9fff) {if (failure) *failure=@"AI còn trả chữ Trung trong bản dịch. Giữ bản gốc để thử lại.";return nil;}}
        NSMutableDictionary *cue=[source[i] mutableCopy];cue[@"text"]=text;[result addObject:cue];
    }return result;
}
NSDictionary *DGNamMinhBody(NSString *text) {
    if (!DGBackendString(text,2000)) return nil;
    NSData *bytes=[[DGNamMinhVoice stringByAppendingString:text] dataUsingEncoding:NSUTF8StringEncoding];unsigned char hash[CC_SHA256_DIGEST_LENGTH];CC_SHA256(bytes.bytes,(CC_LONG)bytes.length,hash);NSMutableString *identity=[NSMutableString stringWithString:@"douyin_tts_"];for (NSUInteger i=0;i<sizeof(hash);i++) [identity appendFormat:@"%02x",hash[i]];
    return @{@"subtitles":@[@{@"index":@0,@"text":text,@"aiTranslation":text,@"googleTranslation":@"",@"start":@0,@"end":@10}],@"config":@{@"model":DGClaudeModel,@"voice":DGNamMinhVoice,@"voiceType":@"azure",@"toLanguage":@"vi-VN",@"skipTranslation":@YES},@"videoDetails":@{@"videoId":identity,@"title":@""},@"v2Version":@YES};
}
NSDictionary *DGNamMinhBodyForCue(NSDictionary *cue,NSString *videoID) {
    NSMutableDictionary *body=[DGNamMinhBody(cue[@"text"]) mutableCopy];if (!body) return nil;
    if (DGCaptionVideoURL(videoID)) {body[@"videoDetails"]=@{@"videoId":[@"douyin_" stringByAppendingString:videoID],@"title":@""};NSMutableDictionary *item=[body[@"subtitles"][0] mutableCopy];item[@"index"]=cue[@"id"];item[@"start"]=cue[@"start"];item[@"end"]=cue[@"end"];body[@"subtitles"]=@[item];}return body;
}
BOOL DGBackendAudioURL(NSURL *url) {
    NSString *host=url.host.lowercaseString;
    return [url.scheme isEqual:@"https"] && !url.user && !url.password && (url.port==nil || url.port.integerValue==443) &&
        ([host isEqual:@"yd.transduck.com"] || [host isEqual:@"youtube-dubbing.com"] || [host hasSuffix:@".youtube-dubbing.com"]);
}
NSURL *DGNamMinhAudioURL(NSData *data,NSInteger status,NSString **failure) {
    id root=DGBackendJSON(data),items=[root isKindOfClass:NSDictionary.class] ? root[@"subtitleDubbingResults"] : nil;
    id item=[items isKindOfClass:NSArray.class] && [items count]==1 ? items[0] : nil;
    id value=[item isKindOfClass:NSDictionary.class] ? item[@"ttsUrl"] : nil;
    NSURL *url=DGBackendString(value,4096) ? [NSURL URLWithString:value] : nil;
    if (status!=200 || !DGBackendAudioURL(url)) {if (failure) *failure=DGBackendFailure(status);return nil;}return url;
}
NSURL *DGNamMinhAudioForText(NSData *data,NSInteger status,NSString *text,NSString **failure) {
    NSURL *url=DGNamMinhAudioURL(data,status,failure);if (!url) return nil;
    NSDictionary *root=DGBackendJSON(data);NSDictionary *item=root[@"subtitleDubbingResults"][0];
    if (![item[@"translateResult"] isEqual:text] || ![item[@"useAiTranslate"] isEqual:@YES]) {if (failure) *failure=@"Giọng trả về chưa khớp câu phụ đề. Giữ tiếng gốc để tránh đọc sai đoạn.";return nil;}
    return url;
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
    if (![@[@"/api/v2/ai-translate/translate",@"/api/v2/dubbing/generateDubbing"] containsObject:path] || ![body isKindOfClass:NSDictionary.class]) {completion(nil,0,@"Cấu hình dịch/lồng tiếng chưa hợp lệ.");return;}
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
            completion(data,status,error ? @"Kết nối dịch/lồng tiếng bị gián đoạn. Bấm thử lại." : nil);
        });
    }];[self.tasks addObject:task];[task resume];
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *))completionHandler {(void)session;(void)task;(void)response;(void)request;completionHandler(nil);}
- (void)cancel {self.generation++;for (NSURLSessionTask *task in self.tasks) [task cancel];[self.tasks removeAllObjects];[self.loginWaiters removeAllObjects];[self.session invalidateAndCancel];self.session=nil;}
- (void)dealloc {[_session invalidateAndCancel];}
@end
