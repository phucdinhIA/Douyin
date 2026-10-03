#import <Foundation/Foundation.h>
#import "DGTranslation.h"

FOUNDATION_EXPORT NSURL *DGCaptionVideoURL(NSString *videoID);
FOUNDATION_EXPORT NSURLRequest *DGGTXRequest(NSString *source);
FOUNDATION_EXPORT NSString *DGGTXAnswer(NSData *data, NSInteger status, NSString **failure);
FOUNDATION_EXPORT NSURLRequest *DGGTXBatchRequest(NSArray<NSString *> *sources);
FOUNDATION_EXPORT NSArray<NSString *> *DGGTXBatchAnswer(NSData *data, NSInteger status, NSArray<NSString *> *sources, NSString **failure);
FOUNDATION_EXPORT NSDictionary *DGGTXSnapshot(void);
FOUNDATION_EXPORT BOOL DGDeepgramNeedsUpload(NSData *data,NSInteger status);
FOUNDATION_EXPORT NSArray<NSDictionary *> *DGCaptionSegments(NSData *data, NSString **failure);
FOUNDATION_EXPORT BOOL DGCaptionValidCues(NSArray *cues);
FOUNDATION_EXPORT NSArray *DGCaptionCoalesceShortCues(NSArray *cues);
FOUNDATION_EXPORT NSString *DGCaptionTextAt(NSArray<NSDictionary *> *cues, NSTimeInterval time);
FOUNDATION_EXPORT NSDictionary *DGCaptionCueAt(NSArray<NSDictionary *> *cues, NSTimeInterval time);
FOUNDATION_EXPORT NSURLRequest *DGCaptionTranslationRequest(NSString *key, NSArray<NSDictionary *> *cues);
FOUNDATION_EXPORT NSURLRequest *DGCaptionTranslationRequestWithTitle(NSString *key, NSArray<NSDictionary *> *cues, NSString *title);
FOUNDATION_EXPORT NSArray<NSDictionary *> *DGCaptionTranslationAnswer(NSData *data, NSInteger status, NSArray<NSDictionary *> *source, NSString **failure);

// Bounded LRU for longer subtitle tracks; source digest keys, no service credentials.
@interface DGCaptionStore : DGTranslationStore
@end

// Main-thread callbacks. One bounded, source-verified empty-ASR recovery, no retry loop.
@interface DGMediaClient : NSObject <NSURLSessionTaskDelegate>
@property(nonatomic,copy) void (^update)(NSString *stage, NSArray<NSDictionary *> *cues, NSString *failure);
@property(nonatomic,copy) void (^event)(NSString *name);
// Numeric timings and stage only; no URLs, video IDs, transcript or credentials.
@property(nonatomic,readonly,copy) NSDictionary *timingDiagnostics;
- (instancetype)initWithConfig:(NSDictionary *)config geminiKey:(NSString *)key store:(DGTranslationStore *)store configuration:(NSURLSessionConfiguration *)configuration;
- (void)startVideo:(NSString *)videoID;
- (void)startVideo:(NSString *)videoID at:(NSTimeInterval)time;
- (void)startVideo:(NSString *)videoID at:(NSTimeInterval)time sourceURL:(NSURL *)url title:(NSString *)title;
- (void)prioritizeTime:(NSTimeInterval)time;
- (BOOL)pendingSpeechAt:(NSTimeInterval)time;
- (void)translateComment:(NSString *)source completion:(void (^)(NSString *,NSString *))completion;
- (void)translateComments:(NSArray<NSString *> *)sources completion:(void (^)(NSDictionary<NSString *,NSString *> *,NSString *))completion;
- (void)cancel;
@end
