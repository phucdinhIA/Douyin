#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const DGGeminiQualityModel;
FOUNDATION_EXPORT NSString *const DGGeminiFastModel;
FOUNDATION_EXPORT NSString *DGGeminiBoundText(NSString *text, NSUInteger limit);
FOUNDATION_EXPORT NSURLRequest *DGGeminiRequest(NSString *key, NSString *model, NSString *question,
                                              NSString *summary, NSArray<NSDictionary *> *history);
FOUNDATION_EXPORT NSString *DGGeminiAnswer(NSData *data, NSInteger status, NSString **failure);
FOUNDATION_EXPORT NSURLRequest *DGGeminiTranslationRequest(NSString *key, NSString *source);
FOUNDATION_EXPORT NSString *DGGeminiTranslationAnswer(NSData *data, NSInteger status, NSString **failure);

// One request per Send. No automatic replay, account cookies, persistent history or raw error logging.
@interface DGGeminiClient : NSObject <NSURLSessionTaskDelegate>
- (instancetype)initWithKey:(NSString *)key model:(NSString *)model;
// Dependency injection for tests; destination, headers and cookie isolation remain fixed.
- (instancetype)initWithKey:(NSString *)key model:(NSString *)model configuration:(NSURLSessionConfiguration *)configuration;
- (void)sendQuestion:(NSString *)question summary:(NSString *)summary history:(NSArray *)history
          completion:(void (^)(NSString *answer, NSString *failure))completion;
- (void)cancel;
- (void)translateSource:(NSString *)source completion:(void (^)(NSString *answer, NSString *failure))completion;
@end
