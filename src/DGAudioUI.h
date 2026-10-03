#import <UIKit/UIKit.h>
FOUNDATION_EXPORT void DGAudioInstall(void (^record)(NSString *,NSUInteger));
FOUNDATION_EXPORT void DGAudioOwner(UIViewController *owner);
FOUNDATION_EXPORT void DGAudioLeave(UIViewController *owner);
FOUNDATION_EXPORT NSDictionary *DGAudioSnapshot(void);
#ifdef DG_GEMINI_FIXTURE
FOUNDATION_EXPORT void DGAudioFixtureTick(void);
#endif
FOUNDATION_EXPORT NSURL *DGAudioSourceURL(UIViewController *owner);
