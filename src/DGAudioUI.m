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
            [owner.background play];if (owner.voice) {[owner.voice seekToTime:CMTimeMakeWithSeconds(time,600)];[owner.voice play];}
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
    if (!self.voice) return;
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
}
- (void)ended:(NSNotification *)note {
    if (note.object!=self.background.currentItem || self.interrupted) return;
    __weak DGAudioController *weakSelf=self;NSUInteger generation=self.generation;
    [self.background seekToTime:kCMTimeZero completionHandler:^(BOOL done) {dispatch_async(dispatch_get_main_queue(),^{
        DGAudioController *owner=weakSelf;if (!owner || !done || owner.generation!=generation) return;[owner.background play];[owner.voice seekToTime:kCMTimeZero];[owner.voice play];
    });}];
}
- (void)interruption:(NSNotification *)note {
    if ([note.userInfo[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue]==AVAudioSessionInterruptionTypeBegan) {self.interrupted=YES;[self.background pause];[self.voice pause];}
    else self.interrupted=NO; // User resumes after a call; do not start unexpected audio.
}
- (void)route:(NSNotification *)note {if ([note.userInfo[AVAudioSessionRouteChangeReasonKey] unsignedIntegerValue]==AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {[self.background pause];[self.voice pause];self.interrupted=YES;}}
- (void)stop {
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
    if (DGAudio.owner!=owner || !DGAMethod(owner,@"setMuted:",@"v20@0:8B16") || !DGAMethod(owner,@"isMute",@"B16@0:8") || ![DGAudio session]) return NO;
    [DGAudio mute];DGAudio.voiceFile=file;DGAudio.voice=[AVPlayer playerWithURL:file];DGAudio.interrupted=NO;[DGAudio tick];return YES;
}
void DGAudioStopVoice(UIViewController *owner) {if (DGAudio.owner==owner) [DGAudio stop];}
NSDictionary *DGAudioSnapshot(void) {
    double time=CMTimeGetSeconds(DGAudio.voice.currentTime);
    return @{@"background_companion":@(DGAudio.background!=nil),@"dubbing_active":@(DGAudio.voice!=nil),@"audio_interrupted":@(DGAudio.interrupted),@"dubbing_rate":@(DGAudio.voice.rate),@"dubbing_time":isfinite(time) ? @(time) : NSNull.null};
}
#ifdef DG_GEMINI_FIXTURE
void DGAudioFixtureTick(void) {[DGAudio tick];}
#endif
