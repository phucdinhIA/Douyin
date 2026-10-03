#import "DGSource.h"
#import <AVFoundation/AVFoundation.h>
#include <math.h>
BOOL DGSourceURLAllowed(NSURL *url) {
    NSString *h=url.host.lowercaseString;
    return [url.scheme isEqual:@"https"] && !url.user && !url.password &&
        ([h isEqual:@"www.douyin.com"] || [h hasSuffix:@".douyinvod.com"] || [h hasSuffix:@".douyinstatic.com"] || [h hasSuffix:@".bytecdn.cn"]);
}
NSString *DGSourceAssetFailure(AVAsset *asset) {
    double duration=asset ? CMTimeGetSeconds(asset.duration) : NAN;
    if (!isfinite(duration) || duration<=0) return @"Tệp video tải về không có thời lượng hợp lệ.";
    if (duration>3600) return @"Video vượt giới hạn 60 phút.";
    BOOL hasAudio=NO;for (AVAssetTrack *track in [asset tracksWithMediaType:AVMediaTypeAudio]) if (CMTimeGetSeconds(track.timeRange.duration)>0) hasAudio=YES;
    if (!hasAudio) return @"Nguồn video tải về không có track âm thanh; không gửi tệp câm để nhận dạng.";
    return nil;
}
@interface DGSourceDownload ()
@property(nonatomic,strong) NSURLSession *session;
@property(nonatomic,strong) AVAssetExportSession *exporter;
@property(nonatomic,strong) NSURL *file;
@property(atomic) BOOL cancelled;
@property(nonatomic,readwrite) double duration;
@property(nonatomic,readwrite) double audioStart;
@property(nonatomic,readwrite) double audioDuration;
@end
@implementation DGSourceDownload
- (void)finish:(NSURL *)url failure:(NSString *)failure {
    dispatch_async(dispatch_get_main_queue(),^{if (!self.cancelled && self.completion) self.completion(url,failure);});
}
- (void)start:(NSURL *)url configuration:(NSURLSessionConfiguration *)configuration {
    if (!DGSourceURLAllowed(url)) {[self finish:nil failure:@"Nguồn video không hợp lệ."];return;}
    NSURLSessionConfiguration *cfg=configuration ? [configuration copy] : NSURLSessionConfiguration.ephemeralSessionConfiguration;
    cfg.HTTPCookieStorage=nil;cfg.URLCredentialStorage=nil;cfg.URLCache=nil;cfg.HTTPShouldSetCookies=NO;cfg.timeoutIntervalForResource=self.resourceTimeout>0 ? MIN(180,self.resourceTimeout) : 180;
    self.session=[NSURLSession sessionWithConfiguration:cfg delegate:self delegateQueue:nil];
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:url];request.timeoutInterval=MIN(60,cfg.timeoutIntervalForResource);
    request.HTTPShouldHandleCookies=NO;
    [request setValue:@"Mozilla/5.0" forHTTPHeaderField:@"User-Agent"];
    [[self.session downloadTaskWithRequest:request] resume];
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *))completionHandler {
    (void)session;(void)task;(void)response;completionHandler(DGSourceURLAllowed(request.URL) ? request : nil);
}
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)task didWriteData:(int64_t)bytes totalBytesWritten:(int64_t)total totalBytesExpectedToWrite:(int64_t)expected {
    (void)session;(void)bytes;if (total>256LL*1024*1024 || expected>256LL*1024*1024) [task cancel];
}
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)task didFinishDownloadingToURL:(NSURL *)location {
    if (self.cancelled) return;
    NSInteger status=[(NSHTTPURLResponse *)task.response statusCode];
    if (status!=200 || !DGSourceURLAllowed(task.response.URL)) {[self finish:nil failure:@"CDN không cho tải video. Hãy thử lại thủ công."];return;}
    NSURL *file=[NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSUUID.UUID.UUIDString stringByAppendingString:@".mp4"]]];
    if (![NSFileManager.defaultManager moveItemAtURL:location toURL:file error:NULL]) {[self finish:nil failure:@"Không lưu được video tạm."];return;}
    self.file=file;AVURLAsset *asset=[AVURLAsset URLAssetWithURL:file options:nil];
    self.duration=CMTimeGetSeconds(asset.duration);
    NSString *failure=DGSourceAssetFailure(asset);
    if (failure) {[self finish:nil failure:failure];[session finishTasksAndInvalidate];return;}
    // Container/video duration can include seconds with no audio. Deepgram's
    // duration measures decoded audio, so keep both quantities separately.
    double first=INFINITY,last=0;
    for (AVAssetTrack *track in [asset tracksWithMediaType:AVMediaTypeAudio]) {
        double a=CMTimeGetSeconds(track.timeRange.start),b=CMTimeGetSeconds(CMTimeRangeGetEnd(track.timeRange));
        if (isfinite(a) && isfinite(b) && b>a) {first=MIN(first,a);last=MAX(last,b);}
    }
    self.audioStart=first;self.audioDuration=last-first;
    if (!isfinite(self.audioStart) || !isfinite(self.audioDuration) || self.audioDuration<=0) {[self finish:nil failure:@"Track âm thanh không có khoảng thời gian hợp lệ."];[session finishTasksAndInvalidate];return;}
    if (self.inspectionOnly) {[self finish:file failure:nil];[session finishTasksAndInvalidate];return;}
    AVAssetExportSession *exporter=[[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetAppleM4A];self.exporter=exporter;
    if (!exporter) {[self finish:file failure:nil];[session finishTasksAndInvalidate];return;}
    NSURL *audio=[NSURL fileURLWithPath:[file.path stringByAppendingString:@".m4a"]];exporter.outputURL=audio;exporter.outputFileType=AVFileTypeAppleM4A;
    __weak DGSourceDownload *weakSelf=self;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        DGSourceDownload *owner=weakSelf;
        if (!owner || owner.cancelled) {[NSFileManager.defaultManager removeItemAtURL:audio error:NULL];[NSFileManager.defaultManager removeItemAtURL:file error:NULL];return;}
        AVURLAsset *extracted=exporter.status==AVAssetExportSessionStatusCompleted ? [AVURLAsset URLAssetWithURL:audio options:nil] : nil;
        double originalSeconds=CMTimeGetSeconds(asset.duration),audioSeconds=CMTimeGetSeconds(extracted.duration);
        AVAssetTrack *sourceTrack=[asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
        // A track beginning late can lose leading silence during audio-only export.
        BOOL aligned=extracted && isfinite(originalSeconds) && isfinite(audioSeconds) && fabs(originalSeconds-audioSeconds)<=0.1 && CMTimeGetSeconds(sourceTrack.timeRange.start)<=0.1;
        if (aligned) {[NSFileManager.defaultManager removeItemAtURL:file error:NULL];owner.file=audio;[owner finish:audio failure:nil];}
        else {[NSFileManager.defaultManager removeItemAtURL:audio error:NULL];[owner finish:file failure:nil];} // Verified MP4 binary upload is also accepted by Nova-3.
    }];
    [session finishTasksAndInvalidate];
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    (void)session;(void)task;if (error) [self finish:nil failure:@"Tải video bị gián đoạn hoặc vượt giới hạn 256 MB."];
}
- (void)cancel {self.cancelled=YES;[self.session invalidateAndCancel];[self.exporter cancelExport];if (self.file) [NSFileManager.defaultManager removeItemAtURL:self.file error:NULL];}
- (void)dealloc {[self cancel];}
@end
