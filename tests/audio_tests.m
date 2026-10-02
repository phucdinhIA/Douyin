#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "DGVbee.h"
#include <math.h>
#include <stdatomic.h>
static NSUInteger checks;
static atomic_int synthCalls,audioCalls,unsafe;
static BOOL authFailure;
static NSDictionary *config;
static void check(BOOL value,NSString *name) {checks++;if (!value) {NSLog(@"FAIL: %@",name);exit(1);}}
static NSData *json(id object) {return [NSJSONSerialization dataWithJSONObject:object options:0 error:NULL];}
static NSData *wave(void) {
    NSUInteger frames=66150;NSMutableData *data=[NSMutableData dataWithLength:44+frames*2];uint8_t *p=data.mutableBytes;
    memcpy(p,"RIFF",4);uint32_t size=(uint32_t)data.length-8;memcpy(p+4,&size,4);memcpy(p+8,"WAVEfmt ",8);uint32_t fmt=16;memcpy(p+16,&fmt,4);
    uint16_t pcm=1,channels=1,bits=16,align=2;uint32_t rate=44100,bytes=88200;memcpy(p+20,&pcm,2);memcpy(p+22,&channels,2);memcpy(p+24,&rate,4);memcpy(p+28,&bytes,4);memcpy(p+32,&align,2);memcpy(p+34,&bits,2);memcpy(p+36,"data",4);uint32_t count=(uint32_t)frames*2;memcpy(p+40,&count,4);
    int16_t *samples=(int16_t *)(p+44);for (NSUInteger i=0;i<frames;i++) samples[i]=(int16_t)(10000*sin(2*M_PI*800*i/44100.0));return data;
}
@interface VoiceMock : NSURLProtocol
@end
@implementation VoiceMock
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {(void)request;return YES;}
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {return request;}
- (void)startLoading {
    NSInteger status=200;NSData *data;
    if ([self.request.URL.path isEqual:@"/api/v1/tts"]) {
        atomic_fetch_add(&synthCalls,1);if (![[self.request valueForHTTPHeaderField:@"Authorization"] isEqual:@"Bearer synthetic-vbee"]) atomic_fetch_add(&unsafe,1);
        if (authFailure) {status=401;data=json(@{@"error_message":@"private contents must never display"});}
        else data=json(@{@"status":@1,@"result":@{@"status":@"SUCCESS",@"app_id":config[@"app_id"],@"voice_code":config[@"voice_code"],@"audio_link":@"https://vbee.vn/audio/fixture.wav"}});
    } else {atomic_fetch_add(&audioCalls,1);if ([self.request valueForHTTPHeaderField:@"Authorization"]) atomic_fetch_add(&unsafe,1);data=wave();}
    [self.client URLProtocol:self didReceiveResponse:[[NSHTTPURLResponse alloc] initWithURL:self.request.URL statusCode:status HTTPVersion:@"HTTP/1.1" headerFields:nil] cacheStoragePolicy:NSURLCacheStorageNotAllowed];[self.client URLProtocol:self didLoadData:data];[self.client URLProtocolDidFinishLoading:self];
}
- (void)stopLoading {}
@end
static void waitFor(BOOL (^finished)(void)) {NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:20];while (!finished() && deadline.timeIntervalSinceNow>0) [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];}
static double rms(AVAudioPCMBuffer *buffer,double seconds) {
    NSUInteger start=(NSUInteger)(seconds*buffer.format.sampleRate),n=MIN((NSUInteger)2048,buffer.frameLength-start);double sum=0;float *p=buffer.floatChannelData[0];for (NSUInteger i=0;i<n;i++) sum+=p[start+i]*p[start+i];return sqrt(sum/MAX(n,1));
}
int main(void) {@autoreleasepool {
    config=@{@"app_id":@"00000000-0000-0000-0000-000000000001",@"token":@"synthetic-vbee",@"voice_code":@"hn_male_manhdung_news_48k-fhg"};
    NSURLSessionConfiguration *cfg=NSURLSessionConfiguration.ephemeralSessionConfiguration;cfg.protocolClasses=@[VoiceMock.class];
    DGVbee *client=[[DGVbee alloc] initWithConfig:config configuration:cfg];NSString *text=[@"Fixture " stringByAppendingString:NSUUID.UUID.UUIDString];
    NSArray *cues=@[@{@"id":@0,@"start":@1,@"end":@2,@"text":text},@{@"id":@1,@"start":@3,@"end":@4,@"text":text}];
    __block NSURL *file=nil;__block NSString *failure=nil;__block BOOL finished=NO;
    client.completion=^(NSURL *result,NSString *error) {file=result;failure=error;finished=YES;};[client start:cues];waitFor(^BOOL{return finished;});
    check(finished && file && !failure,@"Vbee mock synthesis download measured timing and spectral export complete");
    check(atomic_load(&synthCalls)==1 && atomic_load(&audioCalls)==1 && atomic_load(&unsafe)==0,@"identical cues share one synthesis and audio download without forwarding credentials");
    AVURLAsset *asset=[AVURLAsset URLAssetWithURL:file options:nil];check(fabs(CMTimeGetSeconds(asset.duration)-4)<0.1,@"timeline places second cue at timestamp and compresses speech to exact end");
    AVAudioFile *audio=[[AVAudioFile alloc] initForReading:file commonFormat:AVAudioPCMFormatFloat32 interleaved:NO error:NULL];AVAudioPCMBuffer *buffer=[[AVAudioPCMBuffer alloc] initWithPCMFormat:audio.processingFormat frameCapacity:(AVAudioFrameCount)audio.length];
    check(audio && [audio readIntoBuffer:buffer error:NULL],@"exported M4A decodes as real audio");
    check(rms(buffer,0.5)<0.002 && rms(buffer,2.5)<0.002 && rms(buffer,1.2)>0.02 && rms(buffer,3.2)>0.02,@"silence gaps and both speech starts follow subtitle timestamps");
    [NSFileManager.defaultManager removeItemAtURL:file error:NULL];finished=NO;[client start:cues];waitFor(^BOOL{return finished;});
    check(file && atomic_load(&synthCalls)==1,@"cached cue audio rebuilds a timeline without another paid synthesis");[NSFileManager.defaultManager removeItemAtURL:file error:NULL];
    finished=NO;[client start:cues];[client cancel];[NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];check(!finished,@"cancellation rejects old async export completion");
    NSArray *tooShort=@[@{@"id":@0,@"start":@0,@"end":@0.1,@"text":text}];finished=NO;[client start:tooShort];waitFor(^BOOL{return finished;});
    check(!file && failure && atomic_load(&synthCalls)==1,@"extreme speech compression fails explicitly using cached audio rather than drifting");
    authFailure=YES;finished=NO;NSArray *authCues=@[@{@"id":@0,@"start":@0,@"end":@5,@"text":NSUUID.UUID.UUIDString}];[client start:authCues];waitFor(^BOOL{return finished;});int calls=atomic_load(&synthCalls);
    check(failure && !file && ![failure containsString:@"private contents"],@"Vbee auth failure is sanitized");[NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
    check(atomic_load(&synthCalls)==calls,@"failed Vbee synthesis does not trigger automatic paid retries");
    printf("Audio timeline checks passed: %lu\n",(unsigned long)checks);
}return 0;}
