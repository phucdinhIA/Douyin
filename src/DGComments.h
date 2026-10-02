#import <UIKit/UIKit.h>
#import "DGMedia.h"
FOUNDATION_EXPORT NSString *DGCommentVisibleText(UIView *view);
FOUNDATION_EXPORT void DGCommentsStart(UIViewController *owner,DGMediaClient *client,void (^record)(NSString *,NSUInteger));
FOUNDATION_EXPORT void DGCommentsStop(UIViewController *owner);
FOUNDATION_EXPORT void DGCommentsInstall(void);
