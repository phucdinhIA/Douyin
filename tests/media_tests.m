#import <Foundation/Foundation.h>
#import "DGMedia.h"
#import "DGVbee.h"
#import "DGSource.h"
#include <stdatomic.h>
#include <math.h>
static NSUInteger checks;
static atomic_int apifyCalls,deepgramCalls,geminiCalls,gtxCalls,unsafeHeaders;
static BOOL failGemini;
static BOOL residueGemini;
static void check(BOOL value,NSString *name) {++checks;if (!value) {NSLog(@"FAIL: %@",name);exit(1);}}
static NSData *json(id root) {return [NSJSONSerialization dataWithJSONObject:root options:NSJSONWritingFragmentsAllowed error:NULL];}
static NSData *requestData(NSURLRequest *request) {
    if (request.HTTPBody) return request.HTTPBody;NSInputStream *stream=request.HTTPBodyStream;NSMutableData *data=[NSMutableData new];[stream open];uint8_t bytes[4096];NSInteger count;
    while ((count=[stream read:bytes maxLength:sizeof(bytes)])>0) [data appendBytes:bytes length:(NSUInteger)count];[stream close];return data;
}
static NSDictionary *transcript(void) {
    return @{@"metadata":@{@"duration":@10},@"results":@{@"channels":@[@{@"alternatives":@[@{@"words":@[@{@"word":@"你好",@"start":@0,@"end":@1},@{@"word":@"中国",@"start":@2,@"end":@3},@{@"word":@"谢谢",@"start":@5,@"end":@6}]}]}]}};
}
static NSData *translated(NSArray *rows,NSString *finish) {return json(@{@"candidates":@[@{@"content":@{@"parts":@[@{@"text":[[NSString alloc] initWithData:json(@{@"translations":rows}) encoding:NSUTF8StringEncoding]}]},@"finishReason":finish}]});}
@interface MediaMock : NSURLProtocol
@end
@implementation MediaMock
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {(void)request;return YES;}
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {return request;}
- (void)startLoading {
    NSURLRequest *request=self.request;NSString *host=request.URL.host;NSInteger status=200;NSData *data;
    if ([request valueForHTTPHeaderField:@"Cookie"] || request.HTTPShouldHandleCookies || [request.URL.absoluteString containsString:@"fixture-"]) atomic_fetch_add(&unsafeHeaders,1);
    if ([host isEqual:@"api.apify.com"]) {
        atomic_fetch_add(&apifyCalls,1);if (![[request valueForHTTPHeaderField:@"Authorization"] isEqual:@"Bearer fixture-apify"] || [request valueForHTTPHeaderField:@"x-goog-api-key"]) atomic_fetch_add(&unsafeHeaders,1);
        if ([request.URL.path containsString:@"/runs"]) {status=201;data=json(@{@"data":@{@"id":@"run1",@"status":@"SUCCEEDED",@"defaultDatasetId":@"data1"}});}
        else data=json(@[@{@"url":@"https://www.douyin.com/video/7534679152504376595",@"videoUrl":@"https://www.douyin.com/aweme/v1/play/?file_id=mock",@"audioUrl":@"https://wrong-track.example/music.mp3",@"duration":@10,@"errMsg":@""}]);
    } else if ([host isEqual:@"api.deepgram.com"]) {
        atomic_fetch_add(&deepgramCalls,1);NSDictionary *body=[NSJSONSerialization JSONObjectWithData:requestData(request) options:0 error:NULL];
        if (![[request valueForHTTPHeaderField:@"Authorization"] isEqual:@"Token fixture-deepgram"] || [request valueForHTTPHeaderField:@"x-goog-api-key"] || ![body[@"url"] containsString:@"www.douyin.com/aweme"] || ![request.URL.query containsString:@"language=zh-CN"]) atomic_fetch_add(&unsafeHeaders,1);
        data=json(transcript());
    } else if ([host isEqual:@"generativelanguage.googleapis.com"]) {
        atomic_fetch_add(&geminiCalls,1);if (![[request valueForHTTPHeaderField:@"x-goog-api-key"] isEqual:@"fixture-gemini"] || [request valueForHTTPHeaderField:@"Authorization"]) atomic_fetch_add(&unsafeHeaders,1);
        if (failGemini) {status=429;data=json(@{@"error":@{@"message":@"must not show raw credentials"}});}
        else {
            NSDictionary *body=[NSJSONSerialization JSONObjectWithData:requestData(request) options:0 error:NULL];NSString *source=body[@"contents"][0][@"parts"][0][@"text"];NSArray *input=[NSJSONSerialization JSONObjectWithData:[source dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];NSMutableArray *rows=[NSMutableArray new];for (NSDictionary *cue in input) [rows addObject:@{@"id":cue[@"id"],@"text":residueGemini && cue==input.lastObject ? @"Xin chào 中国" : @"Xin chào Việt Nam"}];data=translated(rows,@"STOP");
        }
    } else if ([host isEqual:@"translate.googleapis.com"]) {atomic_fetch_add(&gtxCalls,1);if ([request valueForHTTPHeaderField:@"Authorization"] || [request valueForHTTPHeaderField:@"x-goog-api-key"]) atomic_fetch_add(&unsafeHeaders,1);data=json(@[@[@[@"Xin chào",@"你好",NSNull.null,NSNull.null]],NSNull.null,@"zh-CN"]);}
    else {atomic_fetch_add(&unsafeHeaders,1);status=500;data=json(@{});}
    [self.client URLProtocol:self didReceiveResponse:[[NSHTTPURLResponse alloc] initWithURL:request.URL statusCode:status HTTPVersion:@"HTTP/1.1" headerFields:nil] cacheStoragePolicy:NSURLCacheStorageNotAllowed];[self.client URLProtocol:self didLoadData:data];[self.client URLProtocolDidFinishLoading:self];
}
- (void)stopLoading {}
@end
static void waitFor(BOOL (^finished)(void)) {NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:8];while (!finished() && deadline.timeIntervalSinceNow>0) [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];}
int main(void) {@autoreleasepool {
    check(DGDeepgramNeedsUpload(json(@{@"err_code":@"REMOTE_CONTENT_ERROR"}),400),@"verified CDN rejection enables binary fallback");
    check(!DGDeepgramNeedsUpload(json(@{@"err_code":@"REMOTE_CONTENT_ERROR"}),200) && !DGDeepgramNeedsUpload(json(@{@"err_code":@"INVALID_AUTH"}),401) && !DGDeepgramNeedsUpload(json(@{@"err_code":@"INVALID_QUERY_PARAMETER"}),400) && !DGDeepgramNeedsUpload(json(@{}),400),@"successful paid transcription auth quota and invalid language do not trigger fallback");
    check(DGSourceURLAllowed([NSURL URLWithString:@"https://v95-aw.douyinvod.com/media"]) && !DGSourceURLAllowed([NSURL URLWithString:@"https://evil-douyinvod.com/media"]) && !DGSourceURLAllowed([NSURL URLWithString:@"http://www.douyin.com/media"]) && !DGSourceURLAllowed([NSURL URLWithString:@"https://user:pass@www.douyin.com/media"]),@"source download and background player restrict hosts schemes and credentials");
    NSDictionary *voice=@{@"app_id":@"00000000-0000-0000-0000-000000000001",@"token":@"synthetic-vbee",@"voice_code":@"hn_male_manhdung_news_48k-fhg"};
    NSURLRequest *vr=DGVbeeRequest(voice,@"Xin chào");NSDictionary *vb=[NSJSONSerialization JSONObjectWithData:vr.HTTPBody options:0 error:NULL];
    check([vr.URL.absoluteString isEqual:@"https://vbee.vn/api/v1/tts"] && [vb[@"response_type"] isEqual:@"direct"] && [vb[@"voice_code"] isEqual:voice[@"voice_code"] && !vr.HTTPShouldHandleCookies && !vb[@"callback_url"],@"Vbee uses validated direct mode male Vietnamese voice and isolated credentials");
    check(!DGVbeeRequest(voice,@"") && !DGVbeeRequest(@{},@"Xin chào"),@"unconfigured Vbee never makes a request");
    NSDictionary *voiceResult=@{@"status":@1,@"result":@{@"status":@"SUCCESS",@"app_id":voice[@"app_id"],@"voice_code":voice[@"voice_code"],@"audio_link":@"https://vbee.vn/audio/sample.mp3"}};NSString *voiceFailure=nil;
    check(DGVbeeAudioURL(json(voiceResult),200,voice,&voiceFailure)!=nil,@"verified direct Vbee success yields audio URL");
    NSMutableDictionary *badVoice=[voiceResult mutableCopy];NSMutableDictionary *badResult=[voiceResult[@"result"] mutableCopy];badResult[@"audio_link"]=@"https://evil.example/steal";badVoice[@"result"]=badResult;
    check(!DGVbeeAudioURL(json(badVoice),200,voice,&voiceFailure) && !DGVbeeAudioURL(json(voiceResult),401,voice,&voiceFailure),@"Vbee rejects untrusted audio host and auth failures without leaking response text");
    check([DGCaptionVideoURL(@"7683814443658054955").absoluteString isEqual:@"https://www.douyin.com/video/7683814443658054955"],@"native video ID produces canonical HTTPS URL");
    check(!DGCaptionVideoURL(@"../wrong") && !DGCaptionVideoURL(@"123") && !DGCaptionVideoURL(@"７６８３８１４４４３６５８０５４９５５"),@"video ID rejects paths short IDs and non-ASCII digits");
    NSURLRequest *request=DGGTXRequest(@"你好 & + ? 😀");NSURLComponents *components=[NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];NSMutableDictionary *query=[NSMutableDictionary new];for (NSURLQueryItem *item in components.queryItems) query[item.name]=item.value;
    check([query[@"q"] isEqual:@"你好 & + ? 😀"] && [query[@"sl"] isEqual:@"zh-CN"] && [query[@"tl"] isEqual:@"vi"],@"GTX preserves and escapes comment text with fixed languages");
    check(![request valueForHTTPHeaderField:@"Authorization"] && !request.HTTPShouldHandleCookies && !DGGTXRequest(@" "),@"GTX is unauthenticated isolated and rejects empty source");
    NSString *error=nil;check([DGGTXAnswer(json(@[@[@[@"Xin ",@"你"],@[@"chào",@"好"]]]),200,&error) isEqual:@"Xin chào"],@"GTX joins translation pieces without dropping spaces");
    check(!DGGTXAnswer(json(@[]),200,&error) && !DGGTXAnswer(json(@{}),200,&error) && !DGGTXAnswer(json(@[@[@1]]),200,&error),@"malformed GTX roots and segments fail safely");
    check(!DGGTXAnswer(json(@{}),429,&error) && [error containsString:@"giới hạn"],@"rate limit is surfaced without retry");
    NSArray *cues=DGCaptionSegments(json(transcript()),&error);check(cues.count==3 && DGCaptionValidCues(cues),@"word gaps create separately timed Chinese cues");
    check([cues[0][@"text"] isEqual:@"你好"] && [cues[2][@"start"] doubleValue]==5,@"original speech text and timestamp preserved");
    NSDictionary *overlap=@{@"metadata":@{@"duration":@8},@"results":@{@"channels":@[@{@"alternatives":@[@{@"words":@[@{@"word":@"甲",@"start":@0,@"end":@2},@{@"word":@"乙",@"start":@1,@"end":@3},@{@"word":@"丙",@"start":@5,@"end":@9},@{@"word":@"丁",@"start":@8.5,@"end":@9.5}]}]}]}};
    NSArray *merged=DGCaptionSegments(json(overlap),&error);
    check(merged.count==2 && [merged[0][@"text"] isEqual:@"甲乙"] && [merged[0][@"end"] isEqual:@3],@"overlapping Mandarin words keep all text in one interval envelope");
    check(![merged[0][@"timing_clamped"] boolValue] && [merged[1][@"timing_clamped"] boolValue] && [merged[1][@"text"] isEqual:@"丙丁"] && [merged[1][@"end"] isEqual:@8],@"small tail overshoot clamps only affected cue and preserves late words");
    NSMutableDictionary *drift=[overlap mutableCopy];drift[@"metadata"]=@{@"duration":@7};check(!DGCaptionSegments(json(drift),&error),@"excessive timestamp drift rejects track rather than hiding error");
    check([DGCaptionTextAt(cues,0) isEqual:@"你好"] && !DGCaptionTextAt(cues,1) && !DGCaptionTextAt(cues,1.5),@"cue start included end excluded and silence hides captions");
    check([DGCaptionTextAt(cues,5.5) isEqual:@"谢谢"] && [DGCaptionTextAt(cues,0.5) isEqual:@"你好"],@"seek backwards and loop use playback time not wall clock");
    check(!DGCaptionTextAt(cues,NAN) && !DGCaptionTextAt(cues,-1) && !DGCaptionTextAt(cues,11),@"invalid or out of range player times display nothing");
    NSMutableDictionary *bad=[transcript() mutableCopy];bad[@"metadata"]=@{@"duration":@3601};check(!DGCaptionSegments(json(bad),&error),@"duration over one hour blocked");bad[@"metadata"]=@{@"duration":@2707.94};check(DGCaptionSegments(json(bad),&error).count==3,@"45-minute user video duration accepted");
    check(!DGCaptionSegments(json(@[]),&error) && !DGCaptionSegments(json(@{@"metadata":@{@"duration":@1},@"results":@{}}),&error),@"missing words and bad root rejected");
    check(!DGCaptionValidCues(@[@{@"id":@0,@"start":@2,@"end":@1,@"text":@"wrong"}]) && !DGCaptionValidCues(@[@{@"id":@YES,@"start":@0,@"end":@1,@"text":@"wrong"}]),@"inverted timing and boolean IDs rejected");
    check(DGCaptionValidCues(@[cues[1],cues[2]]) && !DGCaptionTextAt(@[cues[1],cues[2]],0.5),@"sparse partial cache supports prioritized later video segments");
    request=DGCaptionTranslationRequest(@"fixture-gemini",cues);NSDictionary *body=[NSJSONSerialization JSONObjectWithData:request.HTTPBody options:0 error:NULL];
    check([body[@"generationConfig"][@"responseMimeType"] isEqual:@"application/json"] && body[@"generationConfig"][@"responseSchema"],@"Gemini uses structured output schema");
    NSDictionary *translationSchema=body[@"generationConfig"][@"responseSchema"][@"properties"][@"translations"];
    check([translationSchema[@"minItems"] isEqual:@3] && [translationSchema[@"maxItems"] isEqual:@3] && [translationSchema[@"items"][@"properties"][@"text"][@"minLength"] isEqual:@1],@"provider schema requires every cue and a nonempty translation");
    NSString *source=body[@"contents"][0][@"parts"][0][@"text"];check(![source containsString:@"start"] && ![source containsString:@"end"] && ![source containsString:@"fixture-gemini"],@"Gemini receives only cue IDs and untrusted text not timestamps or credentials");
    NSArray *rows=@[@{@"id":@0,@"text":@"Xin chào"},@{@"id":@1,@"text":@"Trung Quốc"},@{@"id":@2,@"text":@"Cảm ơn"}];NSArray *vi=DGCaptionTranslationAnswer(translated(rows,@"STOP"),200,cues,&error);
    check(vi.count==3 && [vi[2][@"start"] isEqual:cues[2][@"start"]] && [vi[2][@"end"] isEqual:cues[2][@"end"]],@"Vietnamese changes text only and retains authoritative timestamps");
    check(!DGCaptionTranslationAnswer(translated(@[rows[0]],@"STOP"),200,cues,&error),@"missing translations rejected");
    check(!DGCaptionTranslationAnswer(translated(@[rows[0],rows[0],rows[2]],@"STOP"),200,cues,&error),@"duplicate IDs rejected");
    check(!DGCaptionTranslationAnswer(translated(@[rows[1],rows[0],rows[2]],@"STOP"),200,cues,&error),@"reordered or changed IDs rejected");
    check(!DGCaptionTranslationAnswer(translated(rows,@"MAX_TOKENS"),200,cues,&error),@"truncated paid output not saved as success");
    check(!DGCaptionTranslationRequest(@"bad\nkey",cues) && !DGCaptionTranslationRequest(@"fixture",(id)@[@1]),@"header injection and malformed cue request blocked");
    NSURL *cacheURL=[NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString]];DGCaptionStore *large=[[DGCaptionStore alloc] initWithURL:cacheURL];NSString *longText=[@"x" stringByPaddingToLength:40000 withString:@"x" startingAtIndex:0];[large saveTranslation:longText source:@"long-video"];
    DGCaptionStore *reopened=[[DGCaptionStore alloc] initWithURL:cacheURL];check([[reopened translationForSource:@"long-video"] isEqual:longText],@"long transcript beyond old 32k cache limit persists");[NSFileManager.defaultManager removeItemAtURL:cacheURL error:NULL];
    NSURLSessionConfiguration *config=NSURLSessionConfiguration.ephemeralSessionConfiguration;config.protocolClasses=@[MediaMock.class];DGCaptionStore *store=[[DGCaptionStore alloc] initWithURL:nil];NSDictionary *keys=@{@"apify_api_key":@"fixture-apify",@"deepgram_api_key":@"fixture-deepgram",@"apify_actor":@"apple_yang~douyin-video-audio-downloader"};
    DGMediaClient *client=[[DGMediaClient alloc] initWithConfig:keys geminiKey:@"fixture-gemini" store:store configuration:config];__block NSString *stage=nil;__block NSArray *result=nil;
    client.update=^(NSString *state,NSArray *track,NSString *failure) {stage=state;result=track;check(!failure || [state isEqual:@"failed"],@"errors remain explicit stages");};
    check(atomic_load(&apifyCalls)==0 && atomic_load(&deepgramCalls)==0 && atomic_load(&geminiCalls)==0,@"constructing client makes no API requests");
    [client startVideo:@"7534679152504376595" at:5];waitFor(^BOOL{return [stage isEqual:@"ready"] || [stage isEqual:@"failed"];});
    check([stage isEqual:@"ready"] && result.count==3 && atomic_load(&apifyCalls)==2 && atomic_load(&deepgramCalls)==1 && atomic_load(&geminiCalls)==2,@"explicit opt-in runs extraction ASR prioritized batches and full track through mock transport");
    int paid=atomic_load(&deepgramCalls)+atomic_load(&geminiCalls),apify=atomic_load(&apifyCalls);[client startVideo:@"7534679152504376595"];
    check([stage isEqual:@"cached"] && atomic_load(&deepgramCalls)+atomic_load(&geminiCalls)==paid && atomic_load(&apifyCalls)==apify,@"completed cache skips every cloud provider");
    DGCaptionStore *retryStore=[[DGCaptionStore alloc] initWithURL:nil];client=[[DGMediaClient alloc] initWithConfig:keys geminiKey:@"fixture-gemini" store:retryStore configuration:config];client.update=^(NSString *state,NSArray *track,NSString *failure) {(void)track;(void)failure;stage=state;};failGemini=YES;stage=nil;[client startVideo:@"7534679152504376595"];waitFor(^BOOL{return [stage isEqual:@"failed"];});
    check([stage isEqual:@"failed"],@"Gemini quota failure surfaces without retry");paid=atomic_load(&deepgramCalls);apify=atomic_load(&apifyCalls);failGemini=NO;[client startVideo:@"7534679152504376595"];waitFor(^BOOL{return [stage isEqual:@"ready"];});
    check([stage isEqual:@"ready"] && atomic_load(&deepgramCalls)==paid && atomic_load(&apifyCalls)==apify,@"manual retry reuses ASR and does not repeat extraction/transcription");
    int geminiBefore=atomic_load(&geminiCalls),gtxBefore=atomic_load(&gtxCalls);residueGemini=YES;stage=nil;
    client=[[DGMediaClient alloc] initWithConfig:keys geminiKey:@"fixture-gemini" store:[[DGCaptionStore alloc] initWithURL:nil] configuration:config];
    client.update=^(NSString *state,NSArray *track,NSString *failure) {(void)failure;stage=state;result=track;};
    [client startVideo:@"7534679152504376595"];waitFor(^BOOL{return [stage isEqual:@"ready"] || [stage isEqual:@"failed"];});residueGemini=NO;
    check([stage isEqual:@"ready"] && [result.lastObject[@"text"] isEqual:@"Xin chào"] && !result.lastObject[@"needs_gtx"] && [result.lastObject[@"start"] isEqual:@5],@"free GTX repairs Chinese residue from original cue without changing timestamps");
    check(atomic_load(&geminiCalls)==geminiBefore+1 && atomic_load(&gtxCalls)==gtxBefore+1,@"language fallback sends one free request only for affected cue and never repeats paid Gemini");
    __block BOOL done=NO;[client translateComment:@"你好" completion:^(NSString *answer,NSString *failure) {check([answer isEqual:@"Xin chào"] && !failure,@"comment uses GTX instead of paid providers");done=YES;}];waitFor(^BOOL{return done;});int gtx=atomic_load(&gtxCalls);done=NO;[client translateComment:@"你好" completion:^(NSString *answer,NSString *failure) {(void)answer;(void)failure;done=YES;}];check(done && atomic_load(&gtxCalls)==gtx,@"GTX cache hit makes no request");
    __block BOOL stale=NO;[client translateComment:@"取消" completion:^(NSString *answer,NSString *failure) {(void)answer;(void)failure;stale=YES;}];[client cancel];[NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.15]];check(!stale,@"cancelled response cannot update newer UI");
    check(atomic_load(&unsafeHeaders)==0,@"all provider credentials isolated no cookies no key-bearing URLs no audio-track mixup");
    printf("Media contract checks passed: %lu\n",(unsigned long)checks);
}return 0;}
