#import <UIKit/UIKit.h>
FOUNDATION_EXPORT void DGAudioInstall(void (^record)(NSString *,NSUInteger));
FOUNDATION_EXPORT void DGAudioOwner(UIViewController *owner);
FOUNDATION_EXPORT void DGAudioLeave(UIViewController *owner);
FOUNDATION_EXPORT BOOL DGAudioVoice(UIViewController *owner,NSURL *file);
FOUNDATION_EXPORT void DGAudioPrepareVoice(UIViewController *owner,NSURL *file,void (^completion)(BOOL));
FOUNDATION_EXPORT void DGAudioStopVoice(UIViewController *owner);
FOUNDATION_EXPORT BOOL DGAudioBeginRolling(UIViewController *owner,NSArray<NSDictionary *> *chunks,void (^buffering)(BOOL));
FOUNDATION_EXPORT void DGAudioRollingChunk(UIViewController *owner,NSDictionary *chunk);
FOUNDATION_EXPORT NSDictionary *DGAudioSnapshot(void);
#ifdef DG_GEMINI_FIXTURE
FOUNDATION_EXPORT void DGAudioFixtureTick(void);
#endif
