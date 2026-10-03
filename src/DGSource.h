#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
FOUNDATION_EXPORT BOOL DGSourceURLAllowed(NSURL *url);
FOUNDATION_EXPORT NSString *DGSourceAssetFailure(AVAsset *asset);
@interface DGSourceDownload : NSObject <NSURLSessionDownloadDelegate>
@property(nonatomic,copy) void (^completion)(NSURL *,NSString *);
@property(nonatomic,readonly) double duration;
@property(nonatomic,readonly) double audioStart;
@property(nonatomic,readonly) double audioDuration;
@property(nonatomic) NSTimeInterval resourceTimeout;
@property(nonatomic) BOOL inspectionOnly;
- (void)start:(NSURL *)url configuration:(NSURLSessionConfiguration *)configuration;
- (void)cancel;
@end
