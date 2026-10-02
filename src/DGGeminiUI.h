#import <UIKit/UIKit.h>
FOUNDATION_EXPORT void DGGeminiInstall(void (^record)(NSString *,NSUInteger));
FOUNDATION_EXPORT NSDictionary *DGGeminiSnapshot(void);
FOUNDATION_EXPORT void DGGeminiPresentFrom(UIViewController *presenter);
FOUNDATION_EXPORT NSString *DGGeminiReadSummary(UIView *root);

@interface DGGeminiChatController : UIViewController
- (instancetype)initWithSummary:(NSString *)summary question:(NSString *)question;
@end
