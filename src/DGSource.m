#import "DGSource.h"
#import <AVFoundation/AVFoundation.h>
BOOL DGSourceURLAllowed(NSURL *url) {
    NSString *h=url.host.lowercaseString;
    return [url.scheme isEqual:@"https"] && !url.user && !url.password &&
        ([h isEqual:@"www.douyin.com"] || [h hasSuffix:@".douyinvod.com"] || [h hasSuffix:@".douyinstatic.com"] || [h hasSuffix:@".bytecdn.cn"]);
}
@interface DGSourceDownload ()
@property(nonatomic,strong) NSURLSession *session;
@property(nonatomic,strong) AVAssetExportSession *exporter;
@property(nonatomic,strong) NSURL *file;
@property(nonatomic) BOOL cancelled;
@end
@implementation DGSourceDownload
- (void)finish:(NSURL *)url failure:(NSString *)failure {
    dispatch_async(dispatch_get_main_queue(),^{if (!self.cancelled && self.completion) self.completion(url,failure);});
}
- (void)start:(NSURL *)url configuration:(NSURLSessionConfiguration *)configuration {
    if (!DGSourceURLAllowed(url)) {[self finish:nil failure:@"Nguồn video không hợp lệ."];return;}
    NSURLSessionConfiguration *cfg=configuration ? [configuration copy] : NSURLSessionConfiguration.ephemeralSessionConfiguration;
    cfg.HTTPCookieStorage=nil;cfg.URLCredentialStorage=nil;cfg.URLCache=nil;cfg.HTTPShouldSetCookies=NO;cfg.timeoutIntervalForResource=180;
    self.session=[NSURLSession sessionWithConfiguration:cfg delegate:self delegateQueue:nil];
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:url];request.timeoutInterval=60;
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
    NSInteger status=[(NSHTTPURLResponse *)task.response statusCode];
    if (status!=200 || !DGSourceURLAllowed(task.response.URL)) {[self finish:nil failure:@"CDN không cho tải video. Hãy thử lại thủ công."];return;}
    NSURL *file=[NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSUUID.UUID.UUIDString stringByAppendingString:@".mp4"]]];
    if (![NSFileManager.defaultManager moveItemAtURL:location toURL:file error:NULL]) {[self finish:nil failure:@"Không lưu được video tạm."];return;}
    self.file=file;AVURLAsset *asset=[AVURLAsset URLAssetWithURL:file options:nil];
    AVAssetExportSession *exporter=[[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetAppleM4A];self.exporter=exporter;
    if (!exporter) {[self finish:file failure:nil];[session finishTasksAndInvalidate];return;}
    NSURL *audio=[NSURL fileURLWithPath:[file.path stringByAppendingString:@".m4a"]];exporter.outputURL=audio;exporter.outputFileType=AVFileTypeAppleM4A;
    __weak DGSourceDownload *weakSelf=self;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        DGSourceDownload *owner=weakSelf;
        if (!owner || owner.cancelled) {[NSFileManager.defaultManager removeItemAtURL:audio error:NULL];[NSFileManager.defaultManager removeItemAtURL:file error:NULL];return;}
        if (exporter.status==AVAssetExportSessionStatusCompleted) {[NSFileManager.defaultManager removeItemAtURL:file error:NULL];owner.file=audio;[owner finish:audio failure:nil];}
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
