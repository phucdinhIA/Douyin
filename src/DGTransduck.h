#import <Foundation/Foundation.h>
FOUNDATION_EXPORT NSString *const DGClaudeModel;
FOUNDATION_EXPORT NSString *const DGNamMinhVoice;
FOUNDATION_EXPORT NSDictionary *DGBackendConfig(void);
FOUNDATION_EXPORT NSDictionary *DGClaudeBody(NSArray *cues,NSString *videoID,NSString *title);
FOUNDATION_EXPORT NSArray *DGClaudeAnswer(NSData *data,NSInteger status,NSArray *source,NSString **failure);
FOUNDATION_EXPORT NSDictionary *DGNamMinhBody(NSString *text);
FOUNDATION_EXPORT NSURL *DGNamMinhAudioURL(NSData *data,NSInteger status,NSString **failure);
FOUNDATION_EXPORT BOOL DGBackendAudioURL(NSURL *url);
@interface DGTransduckClient : NSObject <NSURLSessionTaskDelegate>
@property(nonatomic,copy) void (^event)(NSString *);
- (instancetype)initWithConfig:(NSDictionary *)config configuration:(NSURLSessionConfiguration *)configuration;
- (void)post:(NSString *)path body:(NSDictionary *)body completion:(void (^)(NSData *,NSInteger,NSString *))completion;
- (void)cancel;
@end
