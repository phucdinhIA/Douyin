#import "DGNarration.h"
#import "DGMedia.h"
#import "DGTransduck.h"
#import <AVFoundation/AVFoundation.h>
#import <CommonCrypto/CommonDigest.h>
#include <math.h>
static NSString *const DGVoice=@"vi-VN-NamMinhNeural";
static BOOL DGVoiceURL(NSURL *url) {return DGBackendAudioURL(url);}
static NSString *DGVoiceDigest(NSString *text) {
    NSData *data=[text dataUsingEncoding:NSUTF8StringEncoding];unsigned char bytes[CC_SHA256_DIGEST_LENGTH];CC_SHA256(data.bytes,(CC_LONG)data.length,bytes);NSMutableString *hex=[NSMutableString new];for (NSUInteger i=0;i<sizeof(bytes);i++) [hex appendFormat:@"%02x",bytes[i]];return hex;
}
@interface DGNarration ()
@property(nonatomic,strong) NSDictionary *config;
@property(nonatomic,strong) NSURLSessionConfiguration *configuration;
@property(nonatomic,strong) NSURLSession *session;
@property(nonatomic,strong) DGTransduckClient *backend;
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
@property(nonatomic,readwrite) double videoRateFactor;
@end
@implementation DGNarration
- (instancetype)initWithConfig:(NSDictionary *)config configuration:(NSURLSessionConfiguration *)configuration {
    if ((self=[super init])) {_config=config;_configuration=configuration;_tasks=[NSMutableSet new];
        NSURL *base=[NSFileManager.defaultManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask].firstObject;_cache=[base URLByAppendingPathComponent:@"DouyinGuest/namminh-v1"];
        [NSFileManager.defaultManager createDirectoryAtURL:_cache withIntermediateDirectories:YES attributes:nil error:NULL];
    }return self;
}
- (void)finish:(NSURL *)file failure:(NSString *)failure {
    [self.backend cancel];self.backend=nil;
    if (failure) {[self cancel];if (self.event) self.event(@"Nam Minh failed");}
    if (self.completion) self.completion(file,failure);
}
- (void)start:(NSArray *)cues {
    [self cancel];if (!DGCaptionValidCues(cues) || ![self.config[@"voice"] isEqual:DGNamMinhVoice] || ![self.config[@"email"] length]) {[self finish:nil failure:@"Chưa cấu hình Nam Minh hoặc phụ đề chưa hợp lệ."];return;}
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
    self.session=[NSURLSession sessionWithConfiguration:cfg delegate:self delegateQueue:nil];self.backend=[[DGTransduckClient alloc] initWithConfig:self.config configuration:self.configuration];self.backend.event=self.event;[self pump];
}
- (void)pump {
    while (self.inflight<3 && self.next<self.unique.count) {
        NSUInteger index=[self.unique[self.next++] unsignedIntegerValue];NSDictionary *cue=self.cues[index];NSString *digest=DGVoiceDigest([DGVoice stringByAppendingString:cue[@"text"]]);NSURL *file=[self.cache URLByAppendingPathComponent:[digest stringByAppendingString:@".mp3"]];
        if ([NSFileManager.defaultManager fileExistsAtPath:file.path]) {for (NSNumber *i in self.groups[digest]) self.files[i]=file;if (self.event) self.event(@"Nam Minh cached cue");continue;}
        self.inflight++;NSUInteger generation=self.generation;__weak DGNarration *weakSelf=self;
        if (self.event) self.event(@"Nam Minh sent");
        [self.backend post:@"/api/v2/dubbing/generateDubbing" body:DGNamMinhBodyForCue(cue,self.config[@"video_id"]) completion:^(NSData *data,NSInteger status,NSString *error) {
            dispatch_async(dispatch_get_main_queue(),^{
                DGNarration *owner=weakSelf;if (!owner || owner.generation!=generation) return;
                                if (owner.event) owner.event([NSString stringWithFormat:@"Nam Minh HTTP %ld",(long)status]);NSString *failure=nil;NSURL *url=error ? nil : DGNamMinhAudioURL(data,status,&failure);
                if (!url) {[owner finish:nil failure:failure ?: @"Kết nối Nam Minh bị gián đoạn."];return;}
                NSURLSessionDataTask *download=[owner.session dataTaskWithURL:url completionHandler:^(NSData *audio,NSURLResponse *audioResponse,NSError *audioError) {
                    BOOL valid=!audioError && [(NSHTTPURLResponse *)audioResponse statusCode]==200 && DGVoiceURL(audioResponse.URL);
                    valid=valid && audio.length>0 && audio.length<=8*1024*1024;
                    NSURL *tmp=[file URLByAppendingPathExtension:NSUUID.UUID.UUIDString];BOOL saved=valid && [audio writeToURL:tmp options:NSDataWritingAtomic error:NULL];
                    dispatch_async(dispatch_get_main_queue(),^{
                        DGNarration *current=weakSelf;if (!current || current.generation!=generation) {[NSFileManager.defaultManager removeItemAtURL:tmp error:NULL];return;}
                        if (!saved || ![NSFileManager.defaultManager moveItemAtURL:tmp toURL:file error:NULL]) {[NSFileManager.defaultManager removeItemAtURL:tmp error:NULL];[current finish:nil failure:@"Không tải hoặc lưu được audio Nam Minh."];return;}
                        for (NSNumber *i in current.groups[digest]) current.files[i]=file;current.inflight--;[current pump];
                    });
                }];[owner.tasks addObject:download];[download resume];
            });
        }];
    }
    if (!self.inflight && self.files.count==self.cues.count && !self.assembling) [self assemble];
}
- (void)assemble {
    self.assembling=YES;NSUInteger generation=self.generation;NSArray *cues=self.cues;NSDictionary *files=[self.files copy];double timelineDuration=self.timelineDuration;
    __weak DGNarration *weakSelf=self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0),^{
        AVMutableComposition *composition=[AVMutableComposition composition];AVMutableCompositionTrack *track=[composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];NSString *failure=nil;double maximumFit=1;
        for (NSUInteger i=0;i<cues.count;i++) {
            AVURLAsset *asset=[AVURLAsset URLAssetWithURL:files[@(i)] options:nil];AVAssetTrack *source=[asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
            double duration=CMTimeGetSeconds(asset.duration),start=[cues[i][@"start"] doubleValue],slot=(i+1<cues.count ? [cues[i+1][@"start"] doubleValue] : MAX([cues[i][@"end"] doubleValue],timelineDuration))-start;
            if (!source || !isfinite(duration) || duration<=0 || slot<=0 || duration/slot>3.0) {failure=@"Một câu lồng tiếng quá dài so với mốc video. Giữ phụ đề để tránh giọng đọc bị méo hoặc lệch.";break;}
            maximumFit=MAX(maximumFit,duration/slot);
            CMTime position=CMTimeMakeWithSeconds(start,600),length=asset.duration;
            if (![track insertTimeRange:CMTimeRangeMake(kCMTimeZero,length) ofTrack:source atTime:position error:NULL]) {failure=@"Không ghép được mốc audio Nam Minh.";break;}
            if (duration>slot) [track scaleTimeRange:CMTimeRangeMake(position,length) toDuration:CMTimeMakeWithSeconds(slot,600)];
        }
        double end=CMTimeGetSeconds(composition.duration);NSURL *padding=nil;
        // M4A export drops a trailing empty composition range. Insert actual silent
        // PCM so the queued file ends exactly at the next video's chunk offset.
        if (!failure && isfinite(timelineDuration) && timelineDuration>end) {
            padding=[NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSUUID.UUID.UUIDString stringByAppendingString:@"-silence.caf"]]];
            AVAudioFormat *format=[[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatInt16 sampleRate:16000 channels:1 interleaved:YES];
            AVAudioFile *silent=[[AVAudioFile alloc] initForWriting:padding settings:format.settings commonFormat:AVAudioPCMFormatInt16 interleaved:YES error:NULL];
            AVAudioPCMBuffer *buffer=[[AVAudioPCMBuffer alloc] initWithPCMFormat:format frameCapacity:4096];memset(buffer.int16ChannelData[0],0,4096*sizeof(int16_t));
            NSUInteger remaining=(NSUInteger)ceil((timelineDuration-end)*16000);BOOL written=silent!=nil;
            while (written && remaining) {buffer.frameLength=(AVAudioFrameCount)MIN(remaining,4096);written=[silent writeFromBuffer:buffer error:NULL];remaining-=buffer.frameLength;}silent=nil;
            AVURLAsset *asset=[AVURLAsset URLAssetWithURL:padding options:nil];AVAssetTrack *source=[asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
            if (!written || !source || ![track insertTimeRange:CMTimeRangeMake(kCMTimeZero,CMTimeMakeWithSeconds(timelineDuration-end,600)) ofTrack:source atTime:composition.duration error:NULL]) failure=@"Không đệm được khoảng lặng giữa các đoạn.";
        }
        dispatch_async(dispatch_get_main_queue(),^{
            DGNarration *owner=weakSelf;if (!owner || owner.generation!=generation) {if (padding) [NSFileManager.defaultManager removeItemAtURL:padding error:NULL];return;}
            if (failure) {if (padding) [NSFileManager.defaultManager removeItemAtURL:padding error:NULL];[owner finish:nil failure:failure];return;}
            owner.videoRateFactor=MAX(0.5,MIN(1,1.5/maximumFit));
            AVAssetExportSession *exporter=[[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetAppleM4A];owner.exporter=exporter;
            NSURL *file=[NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSUUID.UUID.UUIDString stringByAppendingString:@"-vi.m4a"]]];exporter.outputURL=file;exporter.outputFileType=AVFileTypeAppleM4A;
            AVMutableAudioMixInputParameters *parameters=[AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:track];parameters.audioTimePitchAlgorithm=AVAudioTimePitchAlgorithmSpectral;
            AVMutableAudioMix *mix=[AVMutableAudioMix audioMix];mix.inputParameters=@[parameters];exporter.audioMix=mix;
            [exporter exportAsynchronouslyWithCompletionHandler:^{dispatch_async(dispatch_get_main_queue(),^{
                if (padding) [NSFileManager.defaultManager removeItemAtURL:padding error:NULL];
                DGNarration *current=weakSelf;if (!current || current.generation!=generation) {[NSFileManager.defaultManager removeItemAtURL:file error:NULL];return;}
                if (exporter.status!=AVAssetExportSessionStatusCompleted) {[NSFileManager.defaultManager removeItemAtURL:file error:NULL];[current finish:nil failure:@"Không xuất được giọng lồng tiếng."];return;}
                if (current.event) current.event(@"Nam Minh timeline ready");[current.session finishTasksAndInvalidate];[current finish:file failure:nil];
            });}];
        });
    });
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *))completionHandler {
    (void)session;(void)response;(void)task;completionHandler(DGVoiceURL(request.URL) ? request : nil);
}
- (void)cancel {self.generation++;[self.backend cancel];self.backend=nil;[self.exporter cancelExport];self.exporter=nil;for (NSURLSessionTask *task in self.tasks) [task cancel];[self.tasks removeAllObjects];[self.session invalidateAndCancel];self.session=nil;}
- (void)dealloc {[_backend cancel];[_session invalidateAndCancel];[_exporter cancelExport];}
@end

NSArray *DGVoiceChunks(NSArray *cues) {
    if (!DGCaptionValidCues(cues)) return nil;NSMutableArray *chunks=[NSMutableArray new];
    for (NSUInteger first=0;first<cues.count;first+=3) {
        NSUInteger last=MIN(first+3,cues.count);double start=first ? [cues[first][@"start"] doubleValue] : 0;
        double end=last<cues.count ? [cues[last][@"start"] doubleValue] : [cues.lastObject[@"end"] doubleValue];NSMutableArray *local=[NSMutableArray new];
        for (NSUInteger i=first;i<last;i++) {NSMutableDictionary *cue=[cues[i] mutableCopy];cue[@"start"]=@([cue[@"start"] doubleValue]-start);cue[@"end"]=@([cue[@"end"] doubleValue]-start);[local addObject:cue];}
        [chunks addObject:@{@"index":@(chunks.count),@"start":@(start),@"end":@(end),@"cues":local}];
    }return chunks;
}
@interface DGRollingVoice ()
@property(nonatomic,strong) NSDictionary *config;
@property(nonatomic,strong) NSURLSessionConfiguration *configuration;
@property(nonatomic,strong) NSArray *chunks;
@property(nonatomic,strong) NSMutableSet *done;
@property(nonatomic,strong) DGNarration *job;
@property(nonatomic) NSTimeInterval time;
@property(nonatomic) NSUInteger generation;
- (void)pump;
@end
@implementation DGRollingVoice
- (instancetype)initWithConfig:(NSDictionary *)config configuration:(NSURLSessionConfiguration *)configuration {if ((self=[super init])) {_config=config;_configuration=configuration;}return self;}
- (void)start:(NSArray *)cues at:(NSTimeInterval)time {
    [self cancel];self.chunks=DGVoiceChunks(cues);self.done=[NSMutableSet new];self.time=isfinite(time) && time>=0 ? time : 0;[self pump];
}
- (void)prioritizeTime:(NSTimeInterval)time {if (isfinite(time) && time>=0) {self.time=time;[self pump];}}
- (void)pump {
    if (self.job || !self.chunks.count) return;NSDictionary *next=nil;
    for (NSDictionary *chunk in self.chunks) {
        if ([chunk[@"end"] doubleValue]<=self.time || [chunk[@"start"] doubleValue]>self.time+60 || [self.done containsObject:chunk[@"index"]]) continue;
        next=chunk;break;
    }if (!next) return;
    DGNarration *job=[[DGNarration alloc] initWithConfig:self.config configuration:self.configuration];self.job=job;job.timelineDuration=[next[@"end"] doubleValue]-[next[@"start"] doubleValue];
    job.event=self.event;NSUInteger generation=self.generation;__weak DGRollingVoice *weakSelf=self;
    job.completion=^(NSURL *file,NSString *failure) {
        DGRollingVoice *owner=weakSelf;if (!owner || owner.generation!=generation) {if (file) [NSFileManager.defaultManager removeItemAtURL:file error:NULL];return;}
        double factor=owner.job.videoRateFactor;owner.job=nil;[owner.done addObject:next[@"index"]];NSMutableDictionary *ready=[next mutableCopy];if (file) {ready[@"file"]=file;ready[@"video_rate_factor"]=@(factor);}else ready[@"failure"]=failure ?: @"Nam Minh chưa tạo được đoạn này.";
        if (owner.event) owner.event(file ? @"Nam Minh rolling chunk ready" : @"Nam Minh rolling chunk failed");if (owner.chunkReady) owner.chunkReady(ready);[owner pump];
    };[job start:next[@"cues"]];
}
- (void)cancel {self.generation++;[self.job cancel];self.job=nil;self.chunks=nil;self.done=nil;}
- (void)dealloc {[_job cancel];}
@end
