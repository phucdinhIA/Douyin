#import <Foundation/Foundation.h>
FOUNDATION_EXPORT NSString *const DGClaudeModel;
FOUNDATION_EXPORT NSDictionary *DGBackendConfig(void);
FOUNDATION_EXPORT NSDictionary *DGClaudeBody(NSArray *cues,NSString *videoID,NSString *title);
FOUNDATION_EXPORT NSDictionary *DGClaudeBodyWithContext(NSArray *cues,NSArray *context,NSString *videoID,NSString *title);
FOUNDATION_EXPORT NSArray *DGClaudeAnswer(NSData *data,NSInteger status,NSArray *source,NSString **failure);
FOUNDATION_EXPORT NSDictionary *DGClaudeResponseDiagnostics(NSData *data,NSInteger status,NSUInteger expected);
FOUNDATION_EXPORT NSArray *DGClaudeAnalysisSegments(NSString *source);
FOUNDATION_EXPORT NSString *DGClaudeAnalysisAnswer(NSData *data,NSInteger status,NSArray *segments,NSString **failure);
@interface DGTransduckClient : NSObject <NSURLSessionTaskDelegate>
@property(nonatomic,copy) void (^event)(NSString *);
- (instancetype)initWithConfig:(NSDictionary *)config configuration:(NSURLSessionConfiguration *)configuration;
- (void)post:(NSString *)path body:(NSDictionary *)body completion:(void (^)(NSData *,NSInteger,NSString *))completion;
- (void)cancel;
@end
