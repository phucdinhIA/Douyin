#import "DGAudioUI.h"
#import "DGSource.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <objc/runtime.h>
#include <math.h>
static Method DGAMethod(id object,NSString *name,NSString *types) {
    Method method=class_getInstanceMethod(object_getClass(object),NSSelectorFromString(name));return method && !strcmp(method_getTypeEncoding(method),types.UTF8String) ? method : NULL;
}
static id DGAObject(id object,NSString *name) {
    Method m=DGAMethod(object,name,@"@16@0:8");return m ? ((id (*)(id,SEL))method_getImplementation(m))(object,NSSelectorFromString(name)) : nil;
}
static BOOL DGABool(id object,NSString *name) {Method m=DGAMethod(object,name,@"B16@0:8");return m && ((BOOL (*)(id,SEL))method_getImplementation(m))(object,NSSelectorFromString(name));}
static double DGATime(id object) {Method m=DGAMethod(object,@"currentPlaybackTime",@"d16@0:8");return m ? ((double (*)(id,SEL))method_getImplementation(m))(object,NSSelectorFromString(@"currentPlaybackTime")) : NAN;}
static void DGAMute(id owner,BOOL muted) {Method m=DGAMethod(owner,@"setMuted:",@"v20@0:8B16");if (m) ((void (*)(id,SEL,BOOL))method_getImplementation(m))(owner,NSSelectorFromString(@"setMuted:"),muted);}
static char DGAChunkIndexKey;
@interface DGAudioController : NSObject
@property(nonatomic,weak) UIViewController *owner;
@property(nonatomic,strong) AVPlayer *background;
@property(nonatomic,strong) AVPlayer *voice;
@property(nonatomic,strong) NSURL *voiceFile;
@property(nonatomic,strong) NSTimer *timer;
@property(nonatomic,copy) void (^record)(NSString *,NSUInteger);
@property(nonatomic) BOOL mutedBefore;
@property(nonatomic) BOOL ownsMute;
@property(nonatomic) BOOL capturedPlaying;
@property(nonatomic) BOOL interrupted;
@property(nonatomic) BOOL seeking;
@property(nonatomic) NSUInteger generation;
@property(nonatomic) BOOL lastPlaying;
@property(nonatomic) NSTimeInterval lastObserved;
@property(nonatomic) NSTimeInterval lastClock;
@property(nonatomic,strong) NSDictionary *previousNowPlaying;
@property(nonatomic) BOOL reportedSourceFailure;
@property(nonatomic,copy) void (^ready)(BOOL);
@property(nonatomic) NSTimeInterval readyStarted;
@property(nonatomic,strong) NSMutableArray *chunks;
@property(nonatomic,copy) void (^buffering)(BOOL);
@property(nonatomic) BOOL rollingWaiting;
@property(nonatomic) BOOL rollingReported;
@property(nonatomic) NSUInteger voiceGeneration;
@property(nonatomic) double voiceOffset;
- (void)rollingTick:(double)time playing:(BOOL)playing foreground:(BOOL)foreground;
- (void)tick;
- (void)resign;
- (void)activate;
- (void)stop;
@end
static DGAudioController *DGAudio;
@implementation DGAudioController
- (BOOL)session {
    NSError *error=nil;AVAudioSession *session=AVAudioSession.sharedInstance;
    BOOL ok=[session setCategory:AVAudioSessionCategoryPlayback mode:AVAudioSessionModeDefault options:0 error:&error] && [session setActive:YES error:&error];
    if (self.record) self.record(ok ? @"Audio playback session active" : @"Audio playback session failed",1);return ok;
}
- (void)mute {
    if (!self.ownsMute) {self.mutedBefore=DGABool(self.owner,@"isMute");self.ownsMute=YES;}DGAMute(self.owner,YES);
}
- (void)resign {
    // Native observers may already have paused on the same notification.
    self.capturedPlaying=DGABool(self.owner,@"isPlaying") || (self.lastPlaying && NSProcessInfo.processInfo.systemUptime-self.lastObserved<0.25);
    if (![NSUserDefaults.standardUserDefaults boolForKey:@"DGBackgroundEnabled"] || !self.capturedPlaying || !self.owner.view.window || self.owner.view.hidden || self.interrupted) return;
    id raw=DGAObject(self.owner,@"currentPlayURL");NSURL *url=[raw isKindOfClass:NSURL.class] ? raw : [raw isKindOfClass:NSString.class] ? [NSURL URLWithString:raw] : nil;
    if (!url) {
        id model=DGAObject(self.owner,@"model"),video=DGAObject(model,@"video"),play=DGAObject(video,@"playURL"),list=DGAObject(play,@"URLList");
        id first=[list isKindOfClass:NSArray.class] ? [list firstObject] : nil;
        if ([first isKindOfClass:NSString.class]) url=[NSURL URLWithString:first];
    }
    double time=DGATime(self.owner);if (!isfinite(time)) time=self.lastClock;
    if (!DGSourceURLAllowed(url) || !isfinite(time) || time<0 || !DGAMethod(self.owner,@"setPlayerSeekTime:completion:",@"v32@0:8d16@?24") || !DGAMethod(self.owner,@"setMuted:",@"v20@0:8B16")) {if (self.record) self.record(@"Background source or player ABI unavailable",1);return;}
    if (![self session]) return;[self mute];self.background=[AVPlayer playerWithURL:url];self.background.muted=self.voice!=nil;
    self.reportedSourceFailure=NO;self.previousNowPlaying=MPNowPlayingInfoCenter.defaultCenter.nowPlayingInfo;
    MPNowPlayingInfoCenter.defaultCenter.nowPlayingInfo=@{MPMediaItemPropertyTitle:@"Douyin",MPNowPlayingInfoPropertyElapsedPlaybackTime:@(time),MPNowPlayingInfoPropertyPlaybackRate:@1};
    NSUInteger generation=++self.generation;__weak DGAudioController *weakSelf=self;
    [self.background seekToTime:CMTimeMakeWithSeconds(time,600) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        dispatch_async(dispatch_get_main_queue(),^{DGAudioController *owner=weakSelf;if (!owner || owner.generation!=generation || !finished || UIApplication.sharedApplication.applicationState==UIApplicationStateActive) return;
            [owner.background play];if (owner.voice) {[owner.voice seekToTime:CMTimeMakeWithSeconds(MAX(0,time-owner.voiceOffset),600)];if (!owner.chunks) [owner.voice play];else [owner tick];}
            if (owner.record) owner.record(@"Background companion playing",1);
        });
    }];
    if (self.record) self.record(@"Background companion prepared",1);
}
- (void)activate {
    if (!self.background) return;double time=CMTimeGetSeconds(self.background.currentTime);BOOL play=(self.background.rate>0 || (self.reportedSourceFailure && self.capturedPlaying)) && !self.interrupted;self.generation++;
    [self.background pause];self.background=nil;
    MPNowPlayingInfoCenter.defaultCenter.nowPlayingInfo=self.previousNowPlaying;self.previousNowPlaying=nil;
    Method seek=DGAMethod(self.owner,@"setPlayerSeekTime:completion:",@"v32@0:8d16@?24");Method resume=DGAMethod(self.owner,@"resumePlayVideo",@"v16@0:8");
    // The completion block's parameter ABI is private; use the audited nullable argument.
    if (seek && isfinite(time)) ((void (*)(id,SEL,double,id))method_getImplementation(seek))(self.owner,NSSelectorFromString(@"setPlayerSeekTime:completion:"),time,nil);
    if (!self.voice && self.ownsMute) {DGAMute(self.owner,self.mutedBefore);self.ownsMute=NO;}
    if (play && resume) ((void (*)(id,SEL))method_getImplementation(resume))(self.owner,NSSelectorFromString(@"resumePlayVideo"));
    else {Method pause=DGAMethod(self.owner,@"pause",@"B16@0:8");if (pause) ((BOOL (*)(id,SEL))method_getImplementation(pause))(self.owner,NSSelectorFromString(@"pause"));}
    if (self.record) self.record(@"Background foreground resync",1);
}
- (void)tick {
    BOOL foreground=UIApplication.sharedApplication.applicationState==UIApplicationStateActive;
    if (foreground && self.owner) {self.lastPlaying=DGABool(self.owner,@"isPlaying");self.lastClock=DGATime(self.owner);self.lastObserved=NSProcessInfo.processInfo.systemUptime;}
    if (self.background) {
        DGAMute(self.owner,YES);
        if (self.background.currentItem.status==AVPlayerItemStatusFailed && !self.reportedSourceFailure) {self.reportedSourceFailure=YES;[self.background pause];[self.voice pause];if (self.record) self.record(@"Background companion source failed",1);}
    }
    if (self.chunks) {
        double time=foreground ? DGATime(self.owner) : CMTimeGetSeconds(self.background.currentTime);
        [self rollingTick:time playing:foreground ? DGABool(self.owner,@"isPlaying") : self.background.rate>0 foreground:foreground];return;
    }
    if (!self.voice) return;
    if (self.ready && (self.voice.currentItem.status==AVPlayerItemStatusFailed || NSProcessInfo.processInfo.systemUptime-self.readyStarted>8)) {
        void (^callback)(BOOL)=self.ready;self.ready=nil;[self stop];callback(NO);return;
    }
    double time=foreground ? DGATime(self.owner) : CMTimeGetSeconds(self.background.currentTime);
    BOOL playing=foreground ? DGABool(self.owner,@"isPlaying") : self.background.rate>0;
    double duration=CMTimeGetSeconds(self.voice.currentItem.duration);if (isfinite(duration) && time>=duration) {[self.voice pause];return;}
    if (self.interrupted || !isfinite(time) || time<0 || (!foreground && !self.background)) {[self.voice pause];return;}
    double delta=fabs(CMTimeGetSeconds(self.voice.currentTime)-time);float rate=1;
    Method nativeRate=DGAMethod(self.owner,@"getCurrentPlaybackRate",@"f16@0:8");if (foreground && nativeRate) rate=((float (*)(id,SEL))method_getImplementation(nativeRate))(self.owner,NSSelectorFromString(@"getCurrentPlaybackRate"));
    if (!isfinite(rate) || rate<=0 || rate>3) rate=1;
    if (delta>0.18 && !self.seeking) {self.seeking=YES;__weak DGAudioController *weakSelf=self;
        [self.voice seekToTime:CMTimeMakeWithSeconds(time,600) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(__unused BOOL done) {dispatch_async(dispatch_get_main_queue(),^{weakSelf.seeking=NO;});}];
    }
    if (playing && !self.seeking) self.voice.rate=rate;else [self.voice pause];
    if (self.ready && foreground && !self.seeking && self.voice.currentItem.status==AVPlayerItemStatusReadyToPlay && delta<0.1) {
        void (^callback)(BOOL)=self.ready;self.ready=nil;callback(YES);
    }
}
- (void)rollingReport:(BOOL)waiting {
    if (self.rollingReported && waiting==self.rollingWaiting) return;self.rollingReported=YES;self.rollingWaiting=waiting;
    if (self.record) self.record(waiting ? @"Dubbing buffer waiting" : @"Dubbing buffer ready",1);if (self.buffering) self.buffering(waiting);
}
- (void)rollingMute:(BOOL)voice {
    if (voice) {[self mute];self.background.muted=YES;}
    else if (self.background) self.background.muted=NO;
    else if (self.ownsMute) {DGAMute(self.owner,self.mutedBefore);self.ownsMute=NO;}
}
- (void)rollingTick:(double)time playing:(BOOL)playing foreground:(BOOL)foreground {
    if (!isfinite(time) || time<0 || self.interrupted) {[self.voice pause];return;}
    NSUInteger index=NSNotFound;for (NSUInteger i=0;i<self.chunks.count;i++) if (time>=[self.chunks[i][@"start"] doubleValue] && time<[self.chunks[i][@"end"] doubleValue]) {index=i;break;}
    if (index==NSNotFound) {[self.voice pause];[self rollingMute:NO];if (foreground) [self rollingReport:NO];return;}
    NSDictionary *chunk=self.chunks[index];NSURL *file=chunk[@"file"];
    if (!file && !chunk[@"failure"]) {
        [self.voice pause];if (foreground) [self rollingReport:YES];else [self rollingMute:NO];return;
    }
    if (chunk[@"failure"]) {
        [self.voice pause];self.voice=nil;self.voiceGeneration++;self.seeking=NO;[self rollingMute:NO];if (foreground) [self rollingReport:NO];return;
    }
    NSNumber *current=objc_getAssociatedObject(self.voice.currentItem,&DGAChunkIndexKey);
    if (!current || current.unsignedIntegerValue!=index) {
        [self.voice pause];self.voiceGeneration++;self.seeking=NO;AVQueuePlayer *queue=[AVQueuePlayer new];self.voice=queue;self.readyStarted=NSProcessInfo.processInfo.systemUptime;
        AVPlayerItem *item=[AVPlayerItem playerItemWithURL:file];objc_setAssociatedObject(item,&DGAChunkIndexKey,@(index),OBJC_ASSOCIATION_RETAIN_NONATOMIC);[queue insertItem:item afterItem:nil];
        if (self.record) self.record(@"Dubbing rolling anchor",1);
    }
    self.voiceOffset=[chunk[@"start"] doubleValue];AVQueuePlayer *queue=(AVQueuePlayer *)self.voice;
    // Queue consecutive local exports before their boundary; no whole-video export.
    NSArray *items=queue.items;NSUInteger tail=[objc_getAssociatedObject(items.lastObject,&DGAChunkIndexKey) unsignedIntegerValue];
    while (queue.items.count<4 && tail+1<self.chunks.count) {
        NSDictionary *next=self.chunks[tail+1];if (!next[@"file"]) break;AVPlayerItem *item=[AVPlayerItem playerItemWithURL:next[@"file"]];objc_setAssociatedObject(item,&DGAChunkIndexKey,@(++tail),OBJC_ASSOCIATION_RETAIN_NONATOMIC);[queue insertItem:item afterItem:queue.items.lastObject];
    }
    if (self.voice.currentItem.status==AVPlayerItemStatusFailed || (self.voice.currentItem.status!=AVPlayerItemStatusReadyToPlay && NSProcessInfo.processInfo.systemUptime-self.readyStarted>8)) {
        NSMutableDictionary *failed=[chunk mutableCopy];[failed removeObjectForKey:@"file"];failed[@"failure"]=@"Không đọc được audio đoạn này.";self.chunks[index]=failed;[NSFileManager.defaultManager removeItemAtURL:file error:NULL];
        if (self.record) self.record(@"Dubbing rolling playback failed",1);[self rollingTick:time playing:playing foreground:foreground];return;
    }
    [self rollingMute:YES];double local=MAX(0,time-self.voiceOffset);double actual=CMTimeGetSeconds(self.voice.currentTime);double delta=fabs(actual-local);
    if ((!isfinite(actual) || delta>0.18) && !self.seeking) {
        self.seeking=YES;NSUInteger generation=self.voiceGeneration;__weak DGAudioController *weakSelf=self;
        [self.voice seekToTime:CMTimeMakeWithSeconds(local,600) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(__unused BOOL done) {dispatch_async(dispatch_get_main_queue(),^{DGAudioController *owner=weakSelf;if (owner.voiceGeneration==generation) owner.seeking=NO;});}];
    }
    float rate=1;Method nativeRate=DGAMethod(self.owner,@"getCurrentPlaybackRate",@"f16@0:8");if (foreground && nativeRate) rate=((float (*)(id,SEL))method_getImplementation(nativeRate))(self.owner,NSSelectorFromString(@"getCurrentPlaybackRate"));if (!isfinite(rate) || rate<=0 || rate>3) rate=1;
    if (playing && !self.seeking && self.voice.currentItem.status==AVPlayerItemStatusReadyToPlay) self.voice.rate=rate;else [self.voice pause];
    if (foreground && self.voice.currentItem.status==AVPlayerItemStatusReadyToPlay && !self.seeking && isfinite(delta) && delta<0.1) [self rollingReport:NO];
}
- (void)ended:(NSNotification *)note {
    if (note.object!=self.background.currentItem || self.interrupted) return;
    __weak DGAudioController *weakSelf=self;NSUInteger generation=self.generation;
    [self.background seekToTime:kCMTimeZero completionHandler:^(BOOL done) {dispatch_async(dispatch_get_main_queue(),^{
        DGAudioController *owner=weakSelf;if (!owner || !done || owner.generation!=generation) return;[owner.background play];if (!owner.chunks) {[owner.voice seekToTime:kCMTimeZero];[owner.voice play];}else {[owner.voice pause];[owner tick];}
    });}];
}
- (void)interruption:(NSNotification *)note {
    if ([note.userInfo[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue]==AVAudioSessionInterruptionTypeBegan) {self.interrupted=YES;[self.background pause];[self.voice pause];}
    else self.interrupted=NO; // User resumes after a call; do not start unexpected audio.
}
- (void)route:(NSNotification *)note {if ([note.userInfo[AVAudioSessionRouteChangeReasonKey] unsignedIntegerValue]==AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {[self.background pause];[self.voice pause];self.interrupted=YES;}}
- (void)stop {
    self.ready=nil;
    self.voiceGeneration++;self.buffering=nil;self.rollingReported=NO;self.rollingWaiting=NO;
    for (NSDictionary *chunk in self.chunks) if (chunk[@"file"]) [NSFileManager.defaultManager removeItemAtURL:chunk[@"file"] error:NULL];self.chunks=nil;self.voiceOffset=0;
    self.generation++;[self.background pause];self.background=nil;[self.voice pause];self.voice=nil;self.seeking=NO;
    if (self.ownsMute) {DGAMute(self.owner,self.mutedBefore);self.ownsMute=NO;}
    if (self.voiceFile) [NSFileManager.defaultManager removeItemAtURL:self.voiceFile error:NULL];self.voiceFile=nil;
    self.lastPlaying=NO;self.lastObserved=0;
    if (self.previousNowPlaying) MPNowPlayingInfoCenter.defaultCenter.nowPlayingInfo=self.previousNowPlaying;self.previousNowPlaying=nil;
}
@end
void DGAudioInstall(void (^record)(NSString *,NSUInteger)) {
    if (DGAudio) {DGAudio.record=record;return;}DGAudio=[DGAudioController new];DGAudio.record=record;
    NSNotificationCenter *center=NSNotificationCenter.defaultCenter;
    [center addObserver:DGAudio selector:@selector(resign) name:UIApplicationWillResignActiveNotification object:nil];
    [center addObserver:DGAudio selector:@selector(activate) name:UIApplicationDidBecomeActiveNotification object:nil];
    [center addObserver:DGAudio selector:@selector(interruption:) name:AVAudioSessionInterruptionNotification object:nil];
    [center addObserver:DGAudio selector:@selector(route:) name:AVAudioSessionRouteChangeNotification object:nil];
    [center addObserver:DGAudio selector:@selector(ended:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    DGAudio.timer=[NSTimer timerWithTimeInterval:0.1 repeats:YES block:^(__unused NSTimer *timer) {[DGAudio tick];}];[NSRunLoop.mainRunLoop addTimer:DGAudio.timer forMode:NSRunLoopCommonModes];
    MPRemoteCommandCenter *remote=MPRemoteCommandCenter.sharedCommandCenter;
    [remote.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(__unused MPRemoteCommandEvent *event) {if (!DGAudio.background) return MPRemoteCommandHandlerStatusNoSuchContent;[DGAudio.background pause];[DGAudio.voice pause];return MPRemoteCommandHandlerStatusSuccess;}];
    [remote.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(__unused MPRemoteCommandEvent *event) {if (!DGAudio.background) return MPRemoteCommandHandlerStatusNoSuchContent;DGAudio.interrupted=NO;[DGAudio.background play];[DGAudio.voice play];return MPRemoteCommandHandlerStatusSuccess;}];
}
void DGAudioOwner(UIViewController *owner) {if (DGAudio.owner!=owner) {[DGAudio stop];DGAudio.owner=owner;}}
void DGAudioLeave(UIViewController *owner) {if (DGAudio.owner==owner) {[DGAudio stop];DGAudio.owner=nil;}}
BOOL DGAudioVoice(UIViewController *owner,NSURL *file) {
    if (!file.isFileURL || ![NSFileManager.defaultManager fileExistsAtPath:file.path]) return NO;
    AVURLAsset *asset=[AVURLAsset URLAssetWithURL:file options:nil];double duration=CMTimeGetSeconds(asset.duration);
    if (!isfinite(duration) || duration<=0 || ![asset tracksWithMediaType:AVMediaTypeAudio].count) return NO;
    if (DGAudio.owner!=owner || !DGAMethod(owner,@"setMuted:",@"v20@0:8B16") || !DGAMethod(owner,@"isMute",@"B16@0:8") || ![DGAudio session]) return NO;
    [DGAudio mute];DGAudio.voiceFile=file;DGAudio.voice=[AVPlayer playerWithURL:file];DGAudio.interrupted=NO;[DGAudio tick];return YES;
}
void DGAudioPrepareVoice(UIViewController *owner,NSURL *file,void (^completion)(BOOL)) {
    if (!DGAudioVoice(owner,file)) {completion(NO);return;}
    DGAudio.ready=completion;DGAudio.readyStarted=NSProcessInfo.processInfo.systemUptime;[DGAudio tick];
}
BOOL DGAudioBeginRolling(UIViewController *owner,NSArray *chunks,void (^buffering)(BOOL)) {
    if (!chunks.count || DGAudio.owner!=owner || !DGAMethod(owner,@"setMuted:",@"v20@0:8B16") || !DGAMethod(owner,@"isMute",@"B16@0:8") || ![DGAudio session]) return NO;
    DGAudio.chunks=[chunks mutableCopy];DGAudio.buffering=buffering;DGAudio.rollingReported=NO;DGAudio.voiceGeneration++;DGAudio.interrupted=NO;[DGAudio tick];return YES;
}
void DGAudioRollingChunk(UIViewController *owner,NSDictionary *chunk) {
    NSUInteger index=[chunk[@"index"] unsignedIntegerValue];
    if (DGAudio.owner!=owner || index>=DGAudio.chunks.count || ![DGAudio.chunks[index][@"start"] isEqual:chunk[@"start"]] || ![DGAudio.chunks[index][@"end"] isEqual:chunk[@"end"]]) {if (chunk[@"file"]) [NSFileManager.defaultManager removeItemAtURL:chunk[@"file"] error:NULL];return;}
    DGAudio.chunks[index]=chunk;[DGAudio tick];
}
void DGAudioStopVoice(UIViewController *owner) {if (DGAudio.owner==owner) [DGAudio stop];}
NSDictionary *DGAudioSnapshot(void) {
    double time=CMTimeGetSeconds(DGAudio.voice.currentTime)+DGAudio.voiceOffset;NSUInteger ready=0,failed=0;for (NSDictionary *chunk in DGAudio.chunks) {if (chunk[@"file"]) ready++;if (chunk[@"failure"]) failed++;}
    return @{@"background_companion":@(DGAudio.background!=nil),@"dubbing_active":@(DGAudio.voice!=nil),@"audio_interrupted":@(DGAudio.interrupted),@"dubbing_rate":@(DGAudio.voice.rate),@"dubbing_time":isfinite(time) ? @(time) : NSNull.null,@"dubbing_chunks_ready":@(ready),@"dubbing_chunks_failed":@(failed),@"dubbing_chunks_total":@(DGAudio.chunks.count),@"dubbing_buffering":@(DGAudio.rollingWaiting)};
}
#ifdef DG_GEMINI_FIXTURE
void DGAudioFixtureTick(void) {[DGAudio tick];}
#endif
