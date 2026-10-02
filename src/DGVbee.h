#import <Foundation/Foundation.h>
FOUNDATION_EXPORT NSURLRequest *DGVbeeRequest(NSDictionary *config,NSString *text);
FOUNDATION_EXPORT NSURL *DGVbeeAudioURL(NSData *data,NSInteger status,NSDictionary *config,NSString **failure);
@interface DGVbee : NSObject <NSURLSessionTaskDelegate>
@property(nonatomic,copy) void (^event)(NSString *);
@property(nonatomic,copy) void (^completion)(NSURL *,NSString *);
- (instancetype)initWithConfig:(NSDictionary *)config configuration:(NSURLSessionConfiguration *)configuration;
- (void)start:(NSArray<NSDictionary *> *)cues;
- (void)cancel;
@end
