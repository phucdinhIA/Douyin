#import <Foundation/Foundation.h>
FOUNDATION_EXPORT BOOL DGSourceURLAllowed(NSURL *url);
@interface DGSourceDownload : NSObject <NSURLSessionDownloadDelegate>
@property(nonatomic,copy) void (^completion)(NSURL *,NSString *);
- (void)start:(NSURL *)url configuration:(NSURLSessionConfiguration *)configuration;
- (void)cancel;
@end
