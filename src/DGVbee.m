#import "DGVbee.h"
#import "DGMedia.h"
#import <AVFoundation/AVFoundation.h>
#import <CommonCrypto/CommonDigest.h>
#include <math.h>
static NSString *const DGVoice=@"hn_male_manhdung_news_48k-fhg";
static BOOL DGVoiceURL(NSURL *url) {
    NSString *host=url.host.lowercaseString;
    return [url.scheme isEqual:@"https"] && !url.user && !url.password &&
        ([host isEqual:@"vbee.vn"] || [host hasSuffix:@".vbee.vn"] || ([host hasPrefix:@"vbee"] && [host hasSuffix:@".s3.ap-southeast-1.amazonaws.com"]));
}
NSURLRequest *DGVbeeRequest(NSDictionary *config,NSString *text) {
    if (![config[@"voice_code"] isEqual:DGVoice] || ![config[@"app_id"] isKindOfClass:NSString.class] || ![[NSUUID alloc] initWithUUIDString:config[@"app_id"]] || ![config[@"token"] isKindOfClass:NSString.class] || ![config[@"token"] length] || ![text isKindOfClass:NSString.class] || !text.length || text.length>2000) return nil;
    NSMutableURLRequest *r=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://vbee.vn/api/v1/tts"]];r.HTTPMethod=@"POST";r.timeoutInterval=90;
    r.HTTPShouldHandleCookies=NO;
    [r setValue:[@"Bearer " stringByAppendingString:config[@"token"]] forHTTPHeaderField:@"Authorization"];[r setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    r.HTTPBody=[NSJSONSerialization dataWithJSONObject:@{@"app_id":config[@"app_id"],@"response_type":@"direct",@"input_text":text,@"voice_code":DGVoice,@"audio_type":@"mp3",@"bitrate":@128,@"speed_rate":@1.0} options:0 error:NULL];return r;
}
NSURL *DGVbeeAudioURL(NSData *data,NSInteger status,NSDictionary *config,NSString **failure) {
    id root=data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL] : nil;id result=[root isKindOfClass:NSDictionary.class] ? root[@"result"] : nil;
    if (status!=200 || ![root isKindOfClass:NSDictionary.class] || ![root[@"status"] isEqual:@1] || ![result isKindOfClass:NSDictionary.class] || ![result[@"status"] isEqual:@"SUCCESS"] || ![result[@"app_id"] isEqual:config[@"app_id"]] || ![result[@"voice_code"] isEqual:DGVoice] || ![result[@"audio_link"] isKindOfClass:NSString.class]) {
        if (failure) *failure=@"Vbee chưa trả audio. Kiểm tra quyền API, token hoặc số dư; không tự gửi lại.";return nil;
    }
    NSURL *url=[NSURL URLWithString:result[@"audio_link"]];if (!DGVoiceURL(url)) {if (failure) *failure=@"Vbee trả nguồn audio không hợp lệ.";return nil;}return url;
}
static NSString *DGVoiceDigest(NSString *text) {
    NSData *data=[text dataUsingEncoding:NSUTF8StringEncoding];unsigned char bytes[CC_SHA256_DIGEST_LENGTH];CC_SHA256(data.bytes,(CC_LONG)data.length,bytes);NSMutableString *hex=[NSMutableString new];for (NSUInteger i=0;i<sizeof(bytes);i++) [hex appendFormat:@"%02x",bytes[i]];return hex;
}
@interface DGVbee ()
@property(nonatomic,strong) NSDictionary *config;
@property(nonatomic,strong) NSURLSessionConfiguration *configuration;
@property(nonatomic,strong) NSURLSession *session;
@property(nonatomic,strong) NSMutableSet *tasks;
@property(nonatomic,strong) NSArray *cues;
@property(nonatomic,strong) NSMutableDictionary *files;
@property(nonatomic,strong) NSMutableDictionary *groups;
@property(nonatomic,strong) NSMutableArray *unique;
@property(nonatomic,strong) NSURL *cache;
@property(nonatomic,strong) AVAssetExportSession *exporter;
@property(nonatomic) NSUInteger generation;
@property(nonatomic) NSUInteger next;
@property(nonatomic) NSUInteger inflight;
@property(nonatomic) BOOL assembling;
@end
@implementation DGVbee
- (instancetype)initWithConfig:(NSDictionary *)config configuration:(NSURLSessionConfiguration *)configuration {
    if ((self=[super init])) {_config=config;_configuration=configuration;_tasks=[NSMutableSet new];
        NSURL *base=[NSFileManager.defaultManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask].firstObject;_cache=[base URLByAppendingPathComponent:@"DouyinGuest/vbee-v1"];
        [NSFileManager.defaultManager createDirectoryAtURL:_cache withIntermediateDirectories:YES attributes:nil error:NULL];
    }return self;
}
- (void)finish:(NSURL *)file failure:(NSString *)failure {
    if (failure) {[self cancel];if (self.event) self.event(@"Vbee failed");}
    if (self.completion) self.completion(file,failure);
}
- (void)start:(NSArray *)cues {
    [self cancel];if (!DGCaptionValidCues(cues) || !DGVbeeRequest(self.config,cues.firstObject[@"text"])) {[self finish:nil failure:@"Chưa cấu hình Vbee hoặc phụ đề chưa hợp lệ."];return;}
    self.cues=cues;self.files=[NSMutableDictionary new];self.next=0;self.inflight=0;self.assembling=NO;
    // Bound durable cue audio to 128 MiB. Files in the current run remain referenced until export.
    NSArray *old=[NSFileManager.defaultManager contentsOfDirectoryAtURL:self.cache includingPropertiesForKeys:@[NSURLFileSizeKey,NSURLContentModificationDateKey] options:0 error:NULL];
    old=[old sortedArrayUsingComparator:^NSComparisonResult(NSURL *a,NSURL *b) {NSDate *x=nil,*y=nil;[a getResourceValue:&x forKey:NSURLContentModificationDateKey error:NULL];[b getResourceValue:&y forKey:NSURLContentModificationDateKey error:NULL];return [x compare:y];}];
    unsigned long long total=0;for (NSURL *file in old) {NSNumber *size=nil;[file getResourceValue:&size forKey:NSURLFileSizeKey error:NULL];total+=size.unsignedLongLongValue;}
    for (NSURL *file in old) {if (total<=128ULL*1024*1024) break;NSNumber *size=nil;[file getResourceValue:&size forKey:NSURLFileSizeKey error:NULL];if ([NSFileManager.defaultManager removeItemAtURL:file error:NULL]) total-=size.unsignedLongLongValue;}
    self.groups=[NSMutableDictionary new];self.unique=[NSMutableArray new];
    for (NSUInteger i=0;i<cues.count;i++) {
        NSString *digest=DGVoiceDigest([DGVoice stringByAppendingString:cues[i][@"text"]]);
        if (!self.groups[digest]) {self.groups[digest]=[NSMutableArray new];[self.unique addObject:@(i)];}
        [self.groups[digest] addObject:@(i)];
    }
    NSURLSessionConfiguration *cfg=self.configuration ? [self.configuration copy] : NSURLSessionConfiguration.ephemeralSessionConfiguration;cfg.HTTPCookieStorage=nil;cfg.URLCredentialStorage=nil;cfg.URLCache=nil;cfg.HTTPShouldSetCookies=NO;cfg.timeoutIntervalForResource=120;
    self.session=[NSURLSession sessionWithConfiguration:cfg delegate:self delegateQueue:nil];[self pump];
}
- (void)pump {
    while (self.inflight<3 && self.next<self.unique.count) {
        NSUInteger index=[self.unique[self.next++] unsignedIntegerValue];NSDictionary *cue=self.cues[index];NSString *digest=DGVoiceDigest([DGVoice stringByAppendingString:cue[@"text"]]);NSURL *file=[self.cache URLByAppendingPathComponent:[digest stringByAppendingString:@".mp3"]];
        if ([NSFileManager.defaultManager fileExistsAtPath:file.path]) {for (NSNumber *i in self.groups[digest]) self.files[i]=file;if (self.event) self.event(@"Vbee cached cue");continue;}
        self.inflight++;NSUInteger generation=self.generation;__weak DGVbee *weakSelf=self;
        if (self.event) self.event(@"Vbee sent");
        NSURLSessionDataTask *task=[self.session dataTaskWithRequest:DGVbeeRequest(self.config,cue[@"text"]) completionHandler:^(NSData *data,NSURLResponse *response,NSError *error) {
            dispatch_async(dispatch_get_main_queue(),^{
                DGVbee *owner=weakSelf;if (!owner || owner.generation!=generation) return;
                NSInteger status=[response isKindOfClass:NSHTTPURLResponse.class] ? [(NSHTTPURLResponse *)response statusCode] : 0;
                if (owner.event) owner.event([NSString stringWithFormat:@"Vbee HTTP %ld",(long)status]);NSString *failure=nil;NSURL *url=error ? nil : DGVbeeAudioURL(data,status,owner.config,&failure);
                if (!url) {[owner finish:nil failure:failure ?: @"Kết nối Vbee bị gián đoạn."];return;}
                NSURLSessionDataTask *download=[owner.session dataTaskWithURL:url completionHandler:^(NSData *audio,NSURLResponse *audioResponse,NSError *audioError) {
                    BOOL valid=!audioError && [(NSHTTPURLResponse *)audioResponse statusCode]==200 && DGVoiceURL(audioResponse.URL);
                    valid=valid && audio.length>0 && audio.length<=8*1024*1024;
                    NSURL *tmp=[file URLByAppendingPathExtension:NSUUID.UUID.UUIDString];BOOL saved=valid && [audio writeToURL:tmp options:NSDataWritingAtomic error:NULL];
                    dispatch_async(dispatch_get_main_queue(),^{
                        DGVbee *current=weakSelf;if (!current || current.generation!=generation) {[NSFileManager.defaultManager removeItemAtURL:tmp error:NULL];return;}
                        if (!saved || ![NSFileManager.defaultManager moveItemAtURL:tmp toURL:file error:NULL]) {[NSFileManager.defaultManager removeItemAtURL:tmp error:NULL];[current finish:nil failure:@"Không tải hoặc lưu được audio Vbee."];return;}
                        for (NSNumber *i in current.groups[digest]) current.files[i]=file;current.inflight--;[current pump];
                    });
                }];[owner.tasks addObject:download];[download resume];
            });
        }];[self.tasks addObject:task];[task resume];
    }
    if (!self.inflight && self.files.count==self.cues.count && !self.assembling) [self assemble];
}
- (void)assemble {
    self.assembling=YES;NSUInteger generation=self.generation;NSArray *cues=self.cues;NSDictionary *files=[self.files copy];
    __weak DGVbee *weakSelf=self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0),^{
        AVMutableComposition *composition=[AVMutableComposition composition];AVMutableCompositionTrack *track=[composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];NSString *failure=nil;
        for (NSUInteger i=0;i<cues.count;i++) {
            AVURLAsset *asset=[AVURLAsset URLAssetWithURL:files[@(i)] options:nil];AVAssetTrack *source=[asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
            double duration=CMTimeGetSeconds(asset.duration),start=[cues[i][@"start"] doubleValue],slot=[cues[i][@"end"] doubleValue]-start;
            if (!source || !isfinite(duration) || duration<=0 || slot<=0 || duration/slot>3.0) {failure=@"Một câu lồng tiếng quá dài so với mốc video. Giữ phụ đề để tránh giọng đọc bị méo hoặc lệch.";break;}
            CMTime position=CMTimeMakeWithSeconds(start,600),length=asset.duration;
            if (![track insertTimeRange:CMTimeRangeMake(kCMTimeZero,length) ofTrack:source atTime:position error:NULL]) {failure=@"Không ghép được mốc audio Vbee.";break;}
            if (duration>slot) [track scaleTimeRange:CMTimeRangeMake(position,length) toDuration:CMTimeMakeWithSeconds(slot,600)];
        }
        dispatch_async(dispatch_get_main_queue(),^{
            DGVbee *owner=weakSelf;if (!owner || owner.generation!=generation) return;
            if (failure) {[owner finish:nil failure:failure];return;}
            AVAssetExportSession *exporter=[[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetAppleM4A];owner.exporter=exporter;
            NSURL *file=[NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSUUID.UUID.UUIDString stringByAppendingString:@"-vi.m4a"]]];exporter.outputURL=file;exporter.outputFileType=AVFileTypeAppleM4A;
            AVMutableAudioMixInputParameters *parameters=[AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:track];parameters.audioTimePitchAlgorithm=AVAudioTimePitchAlgorithmSpectral;
            AVMutableAudioMix *mix=[AVMutableAudioMix audioMix];mix.inputParameters=@[parameters];exporter.audioMix=mix;
            [exporter exportAsynchronouslyWithCompletionHandler:^{dispatch_async(dispatch_get_main_queue(),^{
                DGVbee *current=weakSelf;if (!current || current.generation!=generation) {[NSFileManager.defaultManager removeItemAtURL:file error:NULL];return;}
                if (exporter.status!=AVAssetExportSessionStatusCompleted) {[NSFileManager.defaultManager removeItemAtURL:file error:NULL];[current finish:nil failure:@"Không xuất được giọng lồng tiếng."];return;}
                if (current.event) current.event(@"Vbee timeline ready");[current.session finishTasksAndInvalidate];[current finish:file failure:nil];
            });}];
        });
    });
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *))completionHandler {
    (void)session;(void)response;BOOL synthesis=[task.originalRequest.URL.path isEqual:@"/api/v1/tts"];completionHandler(!synthesis && DGVoiceURL(request.URL) ? request : nil);
}
- (void)cancel {self.generation++;[self.exporter cancelExport];self.exporter=nil;for (NSURLSessionTask *task in self.tasks) [task cancel];[self.tasks removeAllObjects];[self.session invalidateAndCancel];self.session=nil;}
- (void)dealloc {[_session invalidateAndCancel];[_exporter cancelExport];}
@end
