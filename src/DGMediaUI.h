#import <UIKit/UIKit.h>
FOUNDATION_EXPORT void DGMediaInstall(void (^record)(NSString *,NSUInteger));
FOUNDATION_EXPORT NSDictionary *DGMediaSnapshot(void);
FOUNDATION_EXPORT void DGMediaAttachWindow(UIWindow *window);
FOUNDATION_EXPORT void DGMediaOpenComments(UIWindow *window);
FOUNDATION_EXPORT NSArray<NSString *> *DGMediaReadVisibleComments(UIView *root);
#ifdef DG_GEMINI_FIXTURE
FOUNDATION_EXPORT void DGMediaFixtureConfiguration(NSURLSessionConfiguration *configuration,NSURL *cacheURL);
FOUNDATION_EXPORT void DGMediaFixtureTick(UIViewController *owner);
FOUNDATION_EXPORT BOOL DGMediaFixtureShortcut(UIWindow *window,CGPoint point);
FOUNDATION_EXPORT void DGMediaFixtureVbee(NSDictionary *config);
#endif
