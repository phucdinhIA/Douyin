#import <Foundation/Foundation.h>
FOUNDATION_EXPORT NSURLRequest *DGVbeeRequest(NSDictionary *config,NSString *text);
FOUNDATION_EXPORT NSURL *DGVbeeAudioURL(NSData *data,NSInteger status,NSDictionary *config,NSString **failure);
@interface DGVbee : NSObject <NSURLSessionTaskDelegate>
@property(nonatomic,copy) void (^event)(NSString *);
@property(nonatomic,copy) void (^completion)(NSURL *,NSString *);
@property(nonatomic) NSTimeInterval timelineDuration;
- (instancetype)initWithConfig:(NSDictionary *)config configuration:(NSURLSessionConfiguration *)configuration;
- (void)start:(NSArray<NSDictionary *> *)cues;
- (void)cancel;
@end
FOUNDATION_EXPORT NSArray<NSDictionary *> *DGVoiceChunks(NSArray<NSDictionary *> *cues);
// One bounded 3-cue job at a time; ready chunks are handed to the audio owner.
@interface DGRollingVoice : NSObject
@property(nonatomic,copy) void (^event)(NSString *);
@property(nonatomic,copy) void (^chunkReady)(NSDictionary *);
@property(nonatomic,readonly) NSArray<NSDictionary *> *chunks;
- (instancetype)initWithConfig:(NSDictionary *)config configuration:(NSURLSessionConfiguration *)configuration;
- (void)start:(NSArray<NSDictionary *> *)cues at:(NSTimeInterval)time;
- (void)prioritizeTime:(NSTimeInterval)time;
- (void)cancel;
@end
