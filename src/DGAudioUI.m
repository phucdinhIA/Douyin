#import "DGAudioUI.h"
#import "DGSource.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <objc/runtime.h>
#include <math.h>
#include <stdlib.h>
static Method DGAMethod(id object,NSString *name,NSString *types) {
    Method method=class_getInstanceMethod(object_getClass(object),NSSelectorFromString(name));return method && !strcmp(method_getTypeEncoding(method),types.UTF8String) ? method : NULL;
}
static id DGAObject(id object,NSString *name) {
    Method m=DGAMethod(object,name,@"@16@0:8");return m ? ((id (*)(id,SEL))method_getImplementation(m))(object,NSSelectorFromString(name)) : nil;
}
static BOOL DGABool(id object,NSString *name) {Method m=DGAMethod(object,name,@"B16@0:8");return m && ((BOOL (*)(id,SEL))method_getImplementation(m))(object,NSSelectorFromString(name));}
static double DGATime(id object) {Method m=DGAMethod(object,@"currentPlaybackTime",@"d16@0:8");return m ? ((double (*)(id,SEL))method_getImplementation(m))(object,NSSelectorFromString(@"currentPlaybackTime")) : NAN;}
static void DGAMute(id owner,BOOL muted) {Method m=DGAMethod(owner,@"setMuted:",@"v20@0:8B16");if (m) ((void (*)(id,SEL,BOOL))method_getImplementation(m))(owner,NSSelectorFromString(@"setMuted:"),muted);}
NSURL *DGAudioSourceURL(UIViewController *owner) {
    id raw=DGAObject(owner,@"currentPlayURL");NSURL *url=[raw isKindOfClass:NSURL.class] ? raw : [raw isKindOfClass:NSString.class] ? [NSURL URLWithString:raw] : nil;
    if (!url) {
        id model=DGAObject(owner,@"model"),video=DGAObject(model,@"video"),play=DGAObject(video,@"playURL"),list=DGAObject(play,@"URLList");
        id first=[list isKindOfClass:NSArray.class] ? [list firstObject] : nil;
        if ([first isKindOfClass:NSString.class]) url=[NSURL URLWithString:first];
    }return DGSourceURLAllowed(url) ? url : nil;
}
@interface DGAudioController : NSObject
@property(nonatomic,weak) UIViewController *owner;
@property(nonatomic,strong) AVPlayer *background;
@property(nonatomic,strong) NSTimer *timer;
@property(nonatomic,copy) void (^record)(NSString *,NSUInteger);
@property(nonatomic) BOOL mutedBefore;
@property(nonatomic) BOOL ownsMute;
@property(nonatomic) BOOL capturedPlaying;
@property(nonatomic) BOOL interrupted;
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
    NSURL *url=DGAudioSourceURL(self.owner);
    double time=DGATime(self.owner);if (!isfinite(time)) time=self.lastClock;
    if (!DGSourceURLAllowed(url) || !isfinite(time) || time<0 || !DGAMethod(self.owner,@"setPlayerSeekTime:completion:",@"v32@0:8d16@?24") || !DGAMethod(self.owner,@"setMuted:",@"v20@0:8B16")) {if (self.record) self.record(@"Background source or player ABI unavailable",1);return;}
    if (![self session]) return;[self mute];self.background=[AVPlayer playerWithURL:url];self.background.muted=NO;
    self.reportedSourceFailure=NO;self.previousNowPlaying=MPNowPlayingInfoCenter.defaultCenter.nowPlayingInfo;
    MPNowPlayingInfoCenter.defaultCenter.nowPlayingInfo=@{MPMediaItemPropertyTitle:@"Douyin",MPNowPlayingInfoPropertyElapsedPlaybackTime:@(time),MPNowPlayingInfoPropertyPlaybackRate:@1};
    NSUInteger generation=++self.generation;__weak DGAudioController *weakSelf=self;
    [self.background seekToTime:CMTimeMakeWithSeconds(time,600) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        dispatch_async(dispatch_get_main_queue(),^{DGAudioController *owner=weakSelf;if (!owner || owner.generation!=generation || !finished || UIApplication.sharedApplication.applicationState==UIApplicationStateActive) return;
            [owner.background play];
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
    if (self.ownsMute) {DGAMute(self.owner,self.mutedBefore);self.ownsMute=NO;}
    if (play && resume) ((void (*)(id,SEL))method_getImplementation(resume))(self.owner,NSSelectorFromString(@"resumePlayVideo"));
    else {Method pause=DGAMethod(self.owner,@"pause",@"B16@0:8");if (pause) ((BOOL (*)(id,SEL))method_getImplementation(pause))(self.owner,NSSelectorFromString(@"pause"));}
    if (self.record) self.record(@"Background foreground resync",1);
}
- (void)tick {
    BOOL foreground=UIApplication.sharedApplication.applicationState==UIApplicationStateActive;
    if (foreground && self.owner) {self.lastPlaying=DGABool(self.owner,@"isPlaying");self.lastClock=DGATime(self.owner);self.lastObserved=NSProcessInfo.processInfo.systemUptime;}
    if (self.background) {
        DGAMute(self.owner,YES);
        if (self.background.currentItem.status==AVPlayerItemStatusFailed && !self.reportedSourceFailure) {self.reportedSourceFailure=YES;[self.background pause];if (self.record) self.record(@"Background companion source failed",1);}
    }
}
- (void)ended:(NSNotification *)note {
    if (note.object!=self.background.currentItem || self.interrupted) return;
    __weak DGAudioController *weakSelf=self;NSUInteger generation=self.generation;
    [self.background seekToTime:kCMTimeZero completionHandler:^(BOOL done) {dispatch_async(dispatch_get_main_queue(),^{
        DGAudioController *owner=weakSelf;if (!owner || !done || owner.generation!=generation) return;[owner.background play];
    });}];
}
- (void)interruption:(NSNotification *)note {
    if ([note.userInfo[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue]==AVAudioSessionInterruptionTypeBegan) {self.interrupted=YES;[self.background pause];}
    else self.interrupted=NO; // User resumes after a call; do not start unexpected audio.
}
- (void)route:(NSNotification *)note {if ([note.userInfo[AVAudioSessionRouteChangeReasonKey] unsignedIntegerValue]==AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {[self.background pause];self.interrupted=YES;}}
- (void)stop {
    self.generation++;[self.background pause];self.background=nil;
    if (self.ownsMute) {DGAMute(self.owner,self.mutedBefore);self.ownsMute=NO;}
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
    [remote.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(__unused MPRemoteCommandEvent *event) {if (!DGAudio.background) return MPRemoteCommandHandlerStatusNoSuchContent;[DGAudio.background pause];return MPRemoteCommandHandlerStatusSuccess;}];
    [remote.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(__unused MPRemoteCommandEvent *event) {if (!DGAudio.background) return MPRemoteCommandHandlerStatusNoSuchContent;DGAudio.interrupted=NO;[DGAudio.background play];return MPRemoteCommandHandlerStatusSuccess;}];
}
void DGAudioOwner(UIViewController *owner) {if (DGAudio.owner!=owner) {[DGAudio stop];DGAudio.owner=owner;}}
void DGAudioLeave(UIViewController *owner) {if (DGAudio.owner==owner) {[DGAudio stop];DGAudio.owner=nil;}}
NSDictionary *DGAudioSnapshot(void) {
    return @{@"background_companion":@(DGAudio.background!=nil),@"audio_interrupted":@(DGAudio.interrupted)};
}
#ifdef DG_GEMINI_FIXTURE
void DGAudioFixtureTick(void) {[DGAudio tick];}
#endif
