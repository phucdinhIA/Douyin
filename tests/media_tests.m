#import <Foundation/Foundation.h>
#import "DGMedia.h"
#import "DGTransduck.h"
#import "DGSource.h"
#import "DGGemini.h"
#include <stdatomic.h>
#include <math.h>
static NSUInteger checks;
static atomic_int apifyCalls,deepgramCalls,geminiCalls,claudeCalls,gtxCalls,unsafeHeaders,loginCalls,sourceCalls,binaryCalls;
static NSUInteger asrMode;
static BOOL sessionRenew;
static BOOL failGemini;
static BOOL residueGemini;
static BOOL throttleGTX;
static void check(BOOL value,NSString *name) {++checks;if (!value) {NSLog(@"FAIL: %@",name);exit(1);}}
static NSData *json(id root) {return [NSJSONSerialization dataWithJSONObject:root options:NSJSONWritingFragmentsAllowed error:NULL];}
static NSData *requestData(NSURLRequest *request) {
    if (request.HTTPBody) return request.HTTPBody;NSInputStream *stream=request.HTTPBodyStream;NSMutableData *data=[NSMutableData new];[stream open];uint8_t bytes[4096];NSInteger count;
    while ((count=[stream read:bytes maxLength:sizeof(bytes)])>0) [data appendBytes:bytes length:(NSUInteger)count];[stream close];return data;
}
static NSDictionary *transcript(void) {
    return @{@"metadata":@{@"duration":@10},@"results":@{@"channels":@[@{@"alternatives":@[@{@"words":@[@{@"word":@"你好",@"start":@0,@"end":@1},@{@"word":@"中国",@"start":@2,@"end":@3},@{@"word":@"谢谢",@"start":@5,@"end":@6}]}]}]}};
}
static NSData *timedWords(NSArray *words,double duration) {return json(@{@"metadata":@{@"duration":@(duration)},@"results":@{@"channels":@[@{@"alternatives":@[@{@"words":words}]}]}});}
static NSData *translated(NSArray *rows,NSString *finish) {return json(@{@"candidates":@[@{@"content":@{@"parts":@[@{@"text":[[NSString alloc] initWithData:json(@{@"translations":rows}) encoding:NSUTF8StringEncoding]}]},@"finishReason":finish}]});}
@interface MediaMock : NSURLProtocol
@end
@implementation MediaMock
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {(void)request;return YES;}
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {return request;}
- (void)startLoading {
    NSURLRequest *request=self.request;NSString *host=request.URL.host;NSInteger status=200;NSData *data;NSDictionary *headers=nil;
    if ([request valueForHTTPHeaderField:@"Cookie"] || request.HTTPShouldHandleCookies || [request.URL.absoluteString containsString:@"fixture-"]) atomic_fetch_add(&unsafeHeaders,1);
    if ([host isEqual:@"api.apify.com"]) {
        atomic_fetch_add(&apifyCalls,1);if (![[request valueForHTTPHeaderField:@"Authorization"] isEqual:@"Bearer fixture-apify"] || [request valueForHTTPHeaderField:@"x-goog-api-key"]) atomic_fetch_add(&unsafeHeaders,1);
        if ([request.URL.path containsString:@"/runs"]) {status=201;data=json(@{@"data":@{@"id":@"run1",@"status":@"SUCCEEDED",@"defaultDatasetId":@"data1"}});}
        else data=json(@[@{@"url":@"https://www.douyin.com/video/7534679152504376595",@"videoUrl":@"https://www.douyin.com/aweme/v1/play/?file_id=mock",@"audioUrl":@"https://wrong-track.example/music.mp3",@"duration":asrMode ? @2 : @10,@"errMsg":@""}]);
    } else if ([host isEqual:@"api.deepgram.com"]) {
        atomic_fetch_add(&deepgramCalls,1);NSDictionary *body=[NSJSONSerialization JSONObjectWithData:requestData(request) options:0 error:NULL];
        BOOL binary=![[request valueForHTTPHeaderField:@"Content-Type"] isEqual:@"application/json"];
        if (![[request valueForHTTPHeaderField:@"Authorization"] isEqual:@"Token fixture-deepgram"] || [request valueForHTTPHeaderField:@"x-goog-api-key"] || (!binary && (![body[@"url"] containsString:@"www.douyin.com/aweme"] || ![request.URL.query containsString:@"language=zh-CN"])) || (binary && ![request.URL.query containsString:@"language=zh-CN"])) atomic_fetch_add(&unsafeHeaders,1);
        if (binary) atomic_fetch_add(&binaryCalls,1);
        if (asrMode && (!binary || asrMode==2)) data=timedWords(@[],2);
        else if (asrMode) data=timedWords(@[@{@"word":@"你好",@"start":@0.2,@"end":@1.5}],2);
        else data=json(transcript());
    } else if ([host isEqual:@"www.douyin.com"]) {
        atomic_fetch_add(&sourceCalls,1);data=[NSData dataWithContentsOfFile:@"tests/fixtures/tone.wav"];
        if ([request valueForHTTPHeaderField:@"Authorization"] || [request valueForHTTPHeaderField:@"x-goog-api-key"] || [request valueForHTTPHeaderField:@"Ck"]) atomic_fetch_add(&unsafeHeaders,1);
    } else if ([host isEqual:@"yd.transduck.com"]) {
        if ([request.URL.path isEqual:@"/login"]) {atomic_fetch_add(&loginCalls,1);headers=@{@"Set-Cookie":@"SESSION=fresh-backend; Path=/; Secure; HttpOnly"};data=json(@{@"message":@"ok"});}
        else {
        atomic_fetch_add(&claudeCalls,1);if ((!sessionRenew && ![[request valueForHTTPHeaderField:@"Ck"] isEqual:@"synthetic-backend"]) || [request valueForHTTPHeaderField:@"Authorization"] || [request valueForHTTPHeaderField:@"x-goog-api-key"]) atomic_fetch_add(&unsafeHeaders,1);
        NSDictionary *body=[NSJSONSerialization JSONObjectWithData:requestData(request) options:0 error:NULL];NSMutableArray *rows=[NSMutableArray new];for (NSDictionary *cue in body[@"subtitles"]) [rows addObject:@{@"translateResult":residueGemini && cue==[body[@"subtitles"] lastObject] ? @"Xin ch\u00e0o \u4e2d\u56fd" : @"Xin ch\u00e0o Vi\u1ec7t Nam",@"useAiTranslate":@YES}];
        status=failGemini ? 429 : sessionRenew && [[request valueForHTTPHeaderField:@"Ck"] isEqual:@"expired-backend"] ? 401 : 200;data=json(@{@"subtitleTranslateResults":rows});}
    } else if ([host isEqual:@"generativelanguage.googleapis.com"]) {
        atomic_fetch_add(&geminiCalls,1);if (![[request valueForHTTPHeaderField:@"x-goog-api-key"] isEqual:@"fixture-gemini"] || [request valueForHTTPHeaderField:@"Authorization"]) atomic_fetch_add(&unsafeHeaders,1);
        if (failGemini) {status=429;data=json(@{@"error":@{@"message":@"must not show raw credentials"}});}
        else {
            NSDictionary *body=[NSJSONSerialization JSONObjectWithData:requestData(request) options:0 error:NULL];NSString *source=body[@"contents"][0][@"parts"][0][@"text"];NSArray *input=[NSJSONSerialization JSONObjectWithData:[source dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];NSMutableArray *rows=[NSMutableArray new];for (NSDictionary *cue in input) [rows addObject:@{@"id":cue[@"id"],@"text":residueGemini && cue==input.lastObject ? @"Xin chào 中国" : @"Xin chào Việt Nam"}];data=translated(rows,@"STOP");
        }
    } else if ([host isEqual:@"translate.googleapis.com"]) {atomic_fetch_add(&gtxCalls,1);if ([request valueForHTTPHeaderField:@"Authorization"] || [request valueForHTTPHeaderField:@"x-goog-api-key"]) atomic_fetch_add(&unsafeHeaders,1);data=json(@[@[@[@"Xin chào",@"你好",NSNull.null,NSNull.null]],NSNull.null,@"zh-CN"]);}
    else {atomic_fetch_add(&unsafeHeaders,1);status=500;data=json(@{});}
    if ([host isEqual:@"translate.googleapis.com"] && throttleGTX) {status=429;data=json(@{});}
    [self.client URLProtocol:self didReceiveResponse:[[NSHTTPURLResponse alloc] initWithURL:request.URL statusCode:status HTTPVersion:@"HTTP/1.1" headerFields:status==429 ? @{@"Retry-After":@"180"} : headers] cacheStoragePolicy:NSURLCacheStorageNotAllowed];[self.client URLProtocol:self didLoadData:data];[self.client URLProtocolDidFinishLoading:self];
}
- (void)stopLoading {}
@end
static void waitFor(BOOL (^finished)(void)) {NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:8];while (!finished() && deadline.timeIntervalSinceNow>0) [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];}
int main(void) {@autoreleasepool {
    [NSUserDefaults.standardUserDefaults removeObjectForKey:@"DGGTXBlockedUntil"];
    check(DGDeepgramNeedsUpload(json(@{@"err_code":@"REMOTE_CONTENT_ERROR"}),400),@"verified CDN rejection enables binary fallback");
    check(!DGDeepgramNeedsUpload(json(@{@"err_code":@"REMOTE_CONTENT_ERROR"}),200) && !DGDeepgramNeedsUpload(json(@{@"err_code":@"INVALID_AUTH"}),401) && !DGDeepgramNeedsUpload(json(@{@"err_code":@"INVALID_QUERY_PARAMETER"}),400) && !DGDeepgramNeedsUpload(json(@{}),400),@"successful paid transcription auth quota and invalid language do not trigger fallback");
    check(DGSourceURLAllowed([NSURL URLWithString:@"https://v95-aw.douyinvod.com/media"]) && !DGSourceURLAllowed([NSURL URLWithString:@"https://evil-douyinvod.com/media"]) && !DGSourceURLAllowed([NSURL URLWithString:@"http://www.douyin.com/media"]) && !DGSourceURLAllowed([NSURL URLWithString:@"https://user:pass@www.douyin.com/media"]),@"source download and background player restrict hosts schemes and credentials");
    check([DGCaptionVideoURL(@"7683814443658054955").absoluteString isEqual:@"https://www.douyin.com/video/7683814443658054955"],@"native video ID produces canonical HTTPS URL");
    check(!DGCaptionVideoURL(@"../wrong") && !DGCaptionVideoURL(@"123") && !DGCaptionVideoURL(@"７６８３８１４４４３６５８０５４９５５"),@"video ID rejects paths short IDs and non-ASCII digits");
    NSURLRequest *request=DGGTXRequest(@"你好 & + ? 😀");NSURLComponents *components=[NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];NSMutableDictionary *query=[NSMutableDictionary new];for (NSURLQueryItem *item in components.queryItems) query[item.name]=item.value;
    check([query[@"q"] isEqual:@"你好 & + ? 😀"] && [query[@"sl"] isEqual:@"zh-CN"] && [query[@"tl"] isEqual:@"vi"],@"GTX preserves and escapes comment text with fixed languages");
    check(![request valueForHTTPHeaderField:@"Authorization"] && !request.HTTPShouldHandleCookies && !DGGTXRequest(@" "),@"GTX is unauthenticated isolated and rejects empty source");
    NSString *error=nil;check([DGGTXAnswer(json(@[@[@[@"Xin ",@"你"],@[@"chào",@"好"]]]),200,&error) isEqual:@"Xin chào"],@"GTX joins translation pieces without dropping spaces");
    check(!DGGTXAnswer(json(@[]),200,&error) && !DGGTXAnswer(json(@{}),200,&error) && !DGGTXAnswer(json(@[@[@1]]),200,&error),@"malformed GTX roots and segments fail safely");
    check(!DGGTXAnswer(json(@{}),429,&error) && [error containsString:@"giới hạn"],@"rate limit is surfaced without retry");
    NSArray *commentSources=@[@"你好",@"谢谢"];
    NSData *commentBatch=json(@[@[@[@"__DG_COMMENT_0__\nXin chào\n__DG_COMMENT_1__\nCảm ơn",@"source"]]]);
    check([DGGTXBatchAnswer(commentBatch,200,commentSources,&error) isEqual:@[@"Xin chào",@"Cảm ơn"]],@"GTX markers map a batch to exact source comments");
    check(!DGGTXBatchAnswer(json(@[@[@[@"Cảm ơn, xin chào",@"source"]]]),200,commentSources,&error),@"missing GTX markers cannot put another comment's translation in a cell");
    NSArray *cues=DGCaptionSegments(json(transcript()),&error);check(cues.count==3 && DGCaptionValidCues(cues),@"word gaps create separately timed Chinese cues");
    NSData *blank=timedWords(@[],37.243);
    check(!DGCaptionSegments(blank,&error) && [error containsString:@"chưa trả lời nói"] && ![error containsString:@"60 phút"],@"short empty successful ASR is not misreported as a 60-minute video");
    check(DGDeepgramNeedsUpload(blank,200) && !DGDeepgramNeedsUpload(timedWords(@[],3601),200) && !DGDeepgramNeedsUpload(blank,429),@"only valid empty short ASR allows bounded audio verification recovery");
    check(!DGCaptionSegments(json(@{@"metadata":@{@"duration":@YES},@"results":@{}}),&error) && [error containsString:@"thời lượng"],@"boolean metadata is rejected with its actual category");
    check(!DGCaptionSegments(json(@{@"metadata":@{@"duration":@2},@"results":@{}}),&error) && [error containsString:@"cấu trúc"],@"missing channels cannot masquerade as silence");
    NSMutableDictionary *multi=[transcript() mutableCopy];NSMutableDictionary *multiResults=[multi[@"results"] mutableCopy];multiResults[@"channels"]=@[@{@"alternatives":@[@{@"words":@[]}]},multi[@"results"][@"channels"][0]];multi[@"results"]=multiResults;
    check(DGCaptionSegments(json(multi),&error).count==3 && !DGDeepgramNeedsUpload(json(multi),200),@"silent first channel does not discard later speech or add a paid recovery");
    multiResults[@"channels"]=@[@{@"alternatives":@[@{@"words":@[]},transcript()[@"results"][@"channels"][0][@"alternatives"][0]]}];
    check(DGCaptionSegments(json(multi),&error).count==3,@"empty first alternative does not hide a valid timed alternative");
    NSDictionary *utterances=@{@"metadata":@{@"duration":@10},@"results":@{@"channels":@[@{@"alternatives":@[@{@"words":@[],@"transcript":@"你好。谢谢。"}]}],@"utterances":@[@{@"transcript":@"你好。",@"start":@1,@"end":@2},@{@"transcript":@"谢谢。",@"start":@5,@"end":@6}]}};
    NSArray *utteranceCues=DGCaptionSegments(json(utterances),&error);
    check(utteranceCues.count==2 && [utteranceCues[0][@"timing_utterance"] boolValue] && !DGCaptionTextAt(utteranceCues,3) && !DGDeepgramNeedsUpload(json(utterances),200),@"timed utterances retain provider speech intervals and silence without invented word timings or retry");
    AVURLAsset *toneAsset=[AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:@"tests/fixtures/tone.wav"] options:nil];
    check(!DGSourceAssetFailure(toneAsset),@"source verifier accepts a real two-second audio track");
    AVURLAsset *silent=[AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:@"tests/fixtures/source-silent.mp4"] options:nil];
    check([DGSourceAssetFailure(silent) containsString:@"track âm thanh"],@"two-second container without audio is rejected before another paid transcription");
    check([DGSourceAssetFailure(nil) containsString:@"thời lượng"],@"unreadable source reports an asset error instead of silence");
    NSArray *tail=DGCaptionCoalesceShortCues(@[@{@"id":@0,@"start":@0,@"end":@3,@"text":@"这是最后一句"},@{@"id":@1,@"start":@3,@"end":@3.25,@"text":@"谢谢"}]);
    check(tail.count==1 && [tail[0][@"end"] isEqual:@3.25] && [tail[0][@"text"] isEqual:@"这是最后一句谢谢"],@"tiny adjacent tail joins its sentence before translation and TTS instead of demanding impossible speech rate");
    check([cues[0][@"text"] isEqual:@"你好"] && [cues[2][@"start"] doubleValue]==5,@"original speech text and timestamp preserved");
    NSDictionary *overlap=@{@"metadata":@{@"duration":@8},@"results":@{@"channels":@[@{@"alternatives":@[@{@"words":@[@{@"word":@"甲",@"start":@0,@"end":@2},@{@"word":@"乙",@"start":@1,@"end":@3},@{@"word":@"丙",@"start":@5,@"end":@9},@{@"word":@"丁",@"start":@8.5,@"end":@9.5}]}]}]}};
    NSArray *merged=DGCaptionSegments(json(overlap),&error);
    check(merged.count==2 && [merged[0][@"text"] isEqual:@"甲乙"] && [merged[0][@"end"] isEqual:@3],@"overlapping Mandarin words keep all text in one interval envelope");
    check(![merged[0][@"timing_clamped"] boolValue] && [merged[1][@"timing_clamped"] boolValue] && [merged[1][@"text"] isEqual:@"丙丁"] && [merged[1][@"end"] isEqual:@8],@"small tail overshoot clamps only affected cue and preserves late words");
    NSMutableDictionary *drift=[overlap mutableCopy];drift[@"metadata"]=@{@"duration":@7};check(!DGCaptionSegments(json(drift),&error),@"excessive timestamp drift rejects track rather than hiding error");
    NSArray *points=DGCaptionSegments(timedWords(@[@{@"word":@"Hello",@"start":@0,@"end":@0},@{@"word":@"world",@"start":@1,@"end":@2},@{@"word":@"again",@"start":@2,@"end":@2}],5),&error);
    check(points.count==1 && [points[0][@"text"] isEqual:@"Hello world again"] && [points[0][@"start"] isEqual:@1] && [points[0][@"end"] isEqual:@2] && [points[0][@"timing_repaired"] boolValue],@"leading and trailing zero-length words retain text in a real neighboring interval without fabricated duration");
    NSArray *regression=DGCaptionSegments(timedWords(@[@{@"word":@"甲",@"start":@1,@"end":@2},@{@"word":@"乙",@"start":@0.98,@"end":@1.8},@{@"word":@"丙",@"start":@2.001,@"end":@2},@{@"word":@"丁",@"start":@3,@"end":@4}],5),&error);
    check(DGCaptionValidCues(regression) && [regression[0][@"text"] isEqual:@"甲乙丙"] && [regression[0][@"start"] isEqual:@1] && [regression[0][@"end"] isEqual:@2],@"small backwards starts and millisecond rounding inversions no longer reject the whole transcript");
    NSArray *negative=DGCaptionSegments(timedWords(@[@{@"word":@"甲",@"start":@-0.01,@"end":@0.5}],1),&error);check(negative.count==1 && [negative[0][@"start"] isEqual:@0] && [negative[0][@"end"] isEqual:@0.5],@"tiny negative start rounding clamps at the media boundary");
    NSArray *gap=DGCaptionSegments(timedWords(@[@{@"word":@"甲",@"start":@0,@"end":@1},@{@"word":@"乙",@"start":@5,@"end":@5},@{@"word":@"丙",@"start":@5.2,@"end":@6}],8),&error);check(gap.count==2 && [gap[1][@"text"] isEqual:@"乙丙"] && [gap[1][@"start"] isEqual:@5.2] && !DGCaptionTextAt(gap,3),@"zero-length word after silence joins following speech without filling a silent gap");
    NSArray *tailPoints=DGCaptionSegments(timedWords(@[@{@"word":@"甲",@"start":@0,@"end":@1},@{@"word":@"乙",@"start":@5,@"end":@5}],8),&error);check(tailPoints.count==1 && [tailPoints[0][@"text"] isEqual:@"甲乙"] && [tailPoints[0][@"end"] isEqual:@1],@"isolated trailing point retains text but cannot create an invented speech interval");
    check(!DGCaptionSegments(timedWords(@[@{@"word":@"甲",@"start":@0,@"end":@0}],1),&error) && [error containsString:@"không trả khoảng"],@"all-point transcript reports missing speech intervals instead of pretending to synchronize voice");
    check(!DGCaptionSegments(timedWords(@[@{@"word":@"甲",@"start":@3,@"end":@4},@{@"word":@"乙",@"start":@0,@"end":@1}],5),&error) && [error containsString:@"từ 2"],@"large timestamp reset is rejected with the exact word position");
    check(!DGCaptionSegments(timedWords(@[@{@"word":@"甲",@"start":@2,@"end":@1}],5),&error) && [error containsString:@"kết thúc"],@"substantial inverted interval remains an explicit provider error");
    NSArray *repairedTail=DGCaptionCoalesceShortCues(@[@{@"id":@0,@"start":@0,@"end":@3,@"text":@"甲"},@{@"id":@1,@"start":@3,@"end":@3.25,@"text":@"乙",@"timing_repaired":@YES}]);check([repairedTail[0][@"timing_repaired"] boolValue],@"coalescing retains timing repair diagnostics");
    NSData *realTiming=[NSData dataWithContentsOfFile:@"tests/fixtures/deepgram-timing-real.json"];NSDictionary *realRoot=realTiming ? [NSJSONSerialization JSONObjectWithData:realTiming options:NSJSONReadingMutableContainers error:NULL] : nil;
    NSArray *realWords=realRoot[@"results"][@"channels"][0][@"alternatives"][0][@"words"];NSArray *realCues=DGCaptionSegments(realTiming,&error);check(realWords.count==209 && DGCaptionValidCues(realCues),@"anonymized real Mandarin timing track still parses after repair changes");
    NSMutableString *expected=[NSMutableString new],*retained=[NSMutableString new];for (NSDictionary *w in realWords) [expected appendString:w[@"word"]];for (NSDictionary *c in realCues) [retained appendString:c[@"text"]];check([expected isEqual:retained],@"real-track replay preserves every speech token and its order");
    NSMutableDictionary *point=realWords[30],*backwards=realWords[65];point[@"end"]=point[@"start"];backwards[@"start"]=@([realWords[64][@"start"] doubleValue]-0.01);
    NSArray *replayed=DGCaptionCoalesceShortCues(DGCaptionSegments(json(realRoot),&error));[retained setString:@""];BOOL hasRepair=NO;for (NSDictionary *c in replayed) {[retained appendString:c[@"text"]];hasRepair=hasRepair || [c[@"timing_repaired"] boolValue];}
    check(DGCaptionValidCues(replayed) && [expected isEqual:retained] && hasRepair,@"real-length transcript with point and regressive words repairs without losing text or breaking the cue timeline");
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
    NSMutableArray *shortTrack=[NSMutableArray new];for (NSUInteger i=0;i<150;i++) [shortTrack addObject:@{@"id":@(i),@"start":@(i*3),@"end":@(i*3+2),@"text":@"这是完整上下文中的一句话。"}];
    NSURLRequest *full=DGCaptionTranslationRequest(@"fixture-gemini",shortTrack);NSDictionary *fullBody=[NSJSONSerialization JSONObjectWithData:full.HTTPBody options:0 error:NULL];
    NSArray *fullInput=[NSJSONSerialization JSONObjectWithData:[fullBody[@"contents"][0][@"parts"][0][@"text"] dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
    check(fullInput.count==150 && [fullInput.lastObject[@"id"] isEqual:@149] && [fullBody[@"generationConfig"][@"maxOutputTokens"] unsignedIntegerValue]>8192,@"short-video request contains entire 150-cue context with expanded output budget");
    NSDictionary *claudeBody=DGClaudeBody(shortTrack,@"douyin_test",@"Whole context");
    check([claudeBody[@"model"] isEqual:DGClaudeModel] && [claudeBody[@"toLanguage"] isEqual:@"vi-VN"] && [claudeBody[@"subtitles"] count]==150 && [claudeBody[@"subtitles"][149][@"contextBefore"] count]==3,@"Claude receives the entire short track and neighboring context in one fixed-language request");
    check([claudeBody[@"subtitles"][149][@"contextBefore"][0][@"text"] isEqual:shortTrack[146][@"text"]] && [claudeBody[@"subtitles"][0][@"contextAfter"][0][@"text"] isEqual:shortTrack[1][@"text"]],@"live backend context contract uses text objects rather than rejected strings");
    NSArray *one=@[@{@"id":@0,@"start":@0,@"end":@1,@"text":@"你好"}];
    NSArray *parsedClaude=DGClaudeAnswer(json(@{@"subtitleTranslateResults":@[@{@"translateResult":@"Xin chào",@"useAiTranslate":@YES}]}),200,one,&error);
    check([parsedClaude[0][@"id"] isEqual:@0] && [parsedClaude[0][@"start"] isEqual:@0] && [parsedClaude[0][@"end"] isEqual:@1],@"Claude output retains authoritative local IDs and timestamps");
    check(!DGClaudeAnswer(json(@{@"subtitleTranslateResults":@[]}),200,one,&error) && !DGClaudeAnswer(json(@{@"subtitleTranslateResults":@[@{@"index":@9,@"translateResult":@"Xin chào",@"useAiTranslate":@YES}]}),200,one,&error),@"Claude count mismatch and wrong explicit index fail before changing the track");
    NSString *largeAnswer=[@"x" stringByPaddingToLength:40000 withString:@"x" startingAtIndex:0];NSData *largeData=json(@{@"candidates":@[@{@"content":@{@"parts":@[@{@"text":largeAnswer}]},@"finishReason":@"STOP"}]});
    check([DGGeminiTranslationAnswerLimit(largeData,200,500000,&error) length]==40000 && !DGGeminiTranslationAnswer(largeData,200,&error),@"subtitle output beyond 32k is complete while AI-analysis limit stays bounded");
    NSURL *cacheURL=[NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString]];DGCaptionStore *large=[[DGCaptionStore alloc] initWithURL:cacheURL];NSString *longText=[@"x" stringByPaddingToLength:40000 withString:@"x" startingAtIndex:0];[large saveTranslation:longText source:@"long-video"];
    DGCaptionStore *reopened=[[DGCaptionStore alloc] initWithURL:cacheURL];check([[reopened translationForSource:@"long-video"] isEqual:longText],@"long transcript beyond old 32k cache limit persists");[NSFileManager.defaultManager removeItemAtURL:cacheURL error:NULL];
    NSURLSessionConfiguration *config=NSURLSessionConfiguration.ephemeralSessionConfiguration;config.protocolClasses=@[MediaMock.class];DGCaptionStore *store=[[DGCaptionStore alloc] initWithURL:nil];NSDictionary *keys=@{@"apify_api_key":@"fixture-apify",@"deepgram_api_key":@"fixture-deepgram",@"apify_actor":@"apple_yang~douyin-video-audio-downloader",@"backend":@{@"email":@"fixture@example.test",@"session":@"synthetic-backend"}};
    DGMediaClient *client=[[DGMediaClient alloc] initWithConfig:keys geminiKey:@"fixture-gemini" store:store configuration:config];__block NSString *stage=nil;__block NSArray *result=nil;
    client.update=^(NSString *state,NSArray *track,NSString *failure) {stage=state;result=track;check(!failure || [state isEqual:@"failed"],@"errors remain explicit stages");};
    check(atomic_load(&apifyCalls)==0 && atomic_load(&deepgramCalls)==0 && atomic_load(&geminiCalls)==0,@"constructing client makes no API requests");
    [client startVideo:@"7534679152504376595" at:5];waitFor(^BOOL{return [stage isEqual:@"ready"] || [stage isEqual:@"failed"];});
    check([stage isEqual:@"ready"] && result.count==3 && atomic_load(&apifyCalls)==2 && atomic_load(&deepgramCalls)==1 && atomic_load(&claudeCalls)==1,@"explicit opt-in runs extraction ASR one full-context translation and full track through mock transport");
    int paid=atomic_load(&deepgramCalls)+atomic_load(&geminiCalls),apify=atomic_load(&apifyCalls);[client startVideo:@"7534679152504376595"];
    check([stage isEqual:@"cached"] && atomic_load(&deepgramCalls)+atomic_load(&geminiCalls)==paid && atomic_load(&apifyCalls)==apify,@"completed cache skips every cloud provider");
    DGCaptionStore *retryStore=[[DGCaptionStore alloc] initWithURL:nil];client=[[DGMediaClient alloc] initWithConfig:keys geminiKey:@"fixture-gemini" store:retryStore configuration:config];client.update=^(NSString *state,NSArray *track,NSString *failure) {(void)track;(void)failure;stage=state;};failGemini=YES;stage=nil;[client startVideo:@"7534679152504376595"];waitFor(^BOOL{return [stage isEqual:@"failed"];});
    check([stage isEqual:@"failed"],@"Gemini quota failure surfaces without retry");paid=atomic_load(&deepgramCalls);apify=atomic_load(&apifyCalls);failGemini=NO;[client startVideo:@"7534679152504376595"];waitFor(^BOOL{return [stage isEqual:@"ready"];});
    check([stage isEqual:@"ready"] && atomic_load(&deepgramCalls)==paid && atomic_load(&apifyCalls)==apify,@"manual retry reuses ASR and does not repeat extraction/transcription");
    int geminiBefore=atomic_load(&claudeCalls),gtxBefore=atomic_load(&gtxCalls);residueGemini=YES;stage=nil;
    client=[[DGMediaClient alloc] initWithConfig:keys geminiKey:@"fixture-gemini" store:[[DGCaptionStore alloc] initWithURL:nil] configuration:config];
    client.update=^(NSString *state,NSArray *track,NSString *failure) {(void)failure;stage=state;result=track;};
    [client startVideo:@"7534679152504376595"];waitFor(^BOOL{return [stage isEqual:@"ready"] || [stage isEqual:@"failed"];});residueGemini=NO;
    check([stage isEqual:@"failed"] && atomic_load(&claudeCalls)==geminiBefore+1 && atomic_load(&gtxCalls)==gtxBefore,@"Chinese residue is rejected without a hidden paid retry or timing mutation");
    __block BOOL done=NO;[client translateComment:@"你好" completion:^(NSString *answer,NSString *failure) {check([answer isEqual:@"Xin chào"] && !failure,@"comment uses GTX instead of paid providers");done=YES;}];waitFor(^BOOL{return done;});int gtx=atomic_load(&gtxCalls);done=NO;[client translateComment:@"你好" completion:^(NSString *answer,NSString *failure) {(void)answer;(void)failure;done=YES;}];check(done && atomic_load(&gtxCalls)==gtx,@"GTX cache hit makes no request");
    __block BOOL stale=NO;[client translateComment:@"取消" completion:^(NSString *answer,NSString *failure) {(void)answer;(void)failure;stale=YES;}];[client cancel];[NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.15]];check(!stale,@"cancelled response cannot update newer UI");
    check(atomic_load(&unsafeHeaders)==0,@"all provider credentials isolated no cookies no key-bearing URLs no audio-track mixup");
    asrMode=1;stage=nil;int beforeASR=atomic_load(&deepgramCalls),beforeBinary=atomic_load(&binaryCalls),beforeSource=atomic_load(&sourceCalls);
    client=[[DGMediaClient alloc] initWithConfig:keys geminiKey:@"fixture-gemini" store:[[DGCaptionStore alloc] initWithURL:nil] configuration:config];
    client.update=^(NSString *state,NSArray *track,NSString *failure) {stage=state;result=track;if (failure) NSLog(@"Recovery fixture failure: %@",failure);};
    client.event=^(NSString *event) {NSLog(@"Recovery fixture: %@",event);};
    [client startVideo:@"7534679152504376595"];waitFor(^BOOL{return [stage isEqual:@"ready"] || [stage isEqual:@"failed"];});
    NSLog(@"Recovery fixture terminal=%@ cues=%lu ASR=%d binary=%d source=%d",stage,(unsigned long)result.count,atomic_load(&deepgramCalls)-beforeASR,atomic_load(&binaryCalls)-beforeBinary,atomic_load(&sourceCalls)-beforeSource);
    check([stage isEqual:@"ready"] && result.count==1 && atomic_load(&deepgramCalls)==beforeASR+2 && atomic_load(&binaryCalls)==beforeBinary+1 && atomic_load(&sourceCalls)==beforeSource+1,@"HTTP 200 empty Mandarin result recovers once through verified aligned audio with fixed Mandarin");
    asrMode=2;stage=nil;beforeASR=atomic_load(&deepgramCalls);int beforeTranslation=atomic_load(&claudeCalls);
    client=[[DGMediaClient alloc] initWithConfig:keys geminiKey:@"fixture-gemini" store:[[DGCaptionStore alloc] initWithURL:nil] configuration:config];
    __block NSString *asrFailure=nil;client.update=^(NSString *state,NSArray *track,NSString *failure) {(void)track;stage=state;asrFailure=failure;};
    [client startVideo:@"7534679152504376595"];waitFor(^BOOL{return [stage isEqual:@"failed"];});
    check([stage isEqual:@"failed"] && [asrFailure containsString:@"vẫn chưa nhận dạng"] && atomic_load(&deepgramCalls)==beforeASR+2 && atomic_load(&claudeCalls)==beforeTranslation,@"second empty result terminates without retry loops translating silence or a false duration message");
    asrMode=1;stage=nil;beforeASR=atomic_load(&deepgramCalls);apify=atomic_load(&apifyCalls);
    client=[[DGMediaClient alloc] initWithConfig:keys geminiKey:@"fixture-gemini" store:[[DGCaptionStore alloc] initWithURL:nil] configuration:config];client.update=^(NSString *state,NSArray *track,NSString *failure) {(void)track;(void)failure;stage=state;};
    [client startVideo:@"7534679152504376595" at:0 sourceURL:[NSURL URLWithString:@"https://www.douyin.com/verified-source.wav"] title:@"fixture title"];
    waitFor(^BOOL{return [stage isEqual:@"ready"] || [stage isEqual:@"failed"];});
    check([stage isEqual:@"ready"] && atomic_load(&deepgramCalls)==beforeASR+1 && atomic_load(&apifyCalls)==apify,@"native verified source bypasses the entire actor and sends just one fixed-Mandarin audio upload");
    stage=nil;__block BOOL staleNative=NO;[client cancel];client=[[DGMediaClient alloc] initWithConfig:keys geminiKey:@"fixture-gemini" store:[[DGCaptionStore alloc] initWithURL:nil] configuration:config];client.update=^(NSString *state,NSArray *track,NSString *failure) {(void)state;(void)track;(void)failure;staleNative=YES;};
    [client startVideo:@"7534679152504376595" at:0 sourceURL:[NSURL URLWithString:@"https://www.douyin.com/verified-source.wav"] title:nil];staleNative=NO;[client cancel];[NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
    check(!staleNative,@"native download cancellation cannot update a different video");asrMode=0;
    check(atomic_load(&unsafeHeaders)==0,@"binary recovery and native downloads never share backend or Google credentials");
    throttleGTX=YES;done=NO;gtx=atomic_load(&gtxCalls);int beforeFallback=atomic_load(&geminiCalls);
    [client translateComments:@[@"第一条",@"第二条"] completion:^(NSDictionary *answers,NSString *failure) {check(answers.count==2 && !failure,@"GTX 429 uses authorized structured Gemini comment fallback");done=YES;}];waitFor(^BOOL{return done;});
    check(done && atomic_load(&gtxCalls)==gtx+1 && atomic_load(&geminiCalls)==beforeFallback+1 && [DGGTXSnapshot()[@"gtx_cooldown_seconds"] doubleValue]>170,@"one throttled GTX batch respects provider Retry-After across clients");
    DGMediaClient *newPanel=[[DGMediaClient alloc] initWithConfig:keys geminiKey:@"fixture-gemini" store:store configuration:config];done=NO;
    [newPanel translateComment:@"新的评论" completion:^(NSString *answer,NSString *failure) {check(answer.length && !failure,@"another panel translates during cooldown via Gemini");done=YES;}];waitFor(^BOOL{return done;});
    check(done && atomic_load(&gtxCalls)==gtx+1,@"panel reopen cannot bypass shared GTX cooldown");
    sessionRenew=YES;[NSUserDefaults.standardUserDefaults removeObjectForKey:@"DGTransduckSession:renew@example.test"];
    DGTransduckClient *backend=[[DGTransduckClient alloc] initWithConfig:@{@"email":@"renew@example.test",@"password":@"synthetic-password",@"session":@"expired-backend"} configuration:config];
    __block NSUInteger renewed=0;for (NSUInteger i=0;i<3;i++) [backend post:@"/api/v2/ai-translate/translate" body:DGClaudeBody(one,@"douyin_auth_test",@"") completion:^(NSData *data,NSInteger status,NSString *failure) {if (!failure && DGClaudeAnswer(data,status,one,NULL)) renewed++;}];
    waitFor(^BOOL{return renewed==3;});check(renewed==3 && atomic_load(&loginCalls)==1,@"concurrent expired requests renew the authorized account once and reuse its fresh session");
    failGemini=YES;__block BOOL limited=NO;int beforeLimit=atomic_load(&claudeCalls);[backend post:@"/api/v2/ai-translate/translate" body:DGClaudeBody(one,@"douyin_auth_test",@"") completion:^(__unused NSData *data,NSInteger status,__unused NSString *failure) {limited=status==429;}];waitFor(^BOOL{return limited;});
    check(limited && atomic_load(&claudeCalls)==beforeLimit+1,@"backend quota limit makes no automatic paid retry");[backend cancel];failGemini=NO;sessionRenew=NO;[NSUserDefaults.standardUserDefaults removeObjectForKey:@"DGTransduckSession:renew@example.test"];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:@"DGGTXBlockedUntil"];
    printf("Media contract checks passed: %lu\n",(unsigned long)checks);
}return 0;}
