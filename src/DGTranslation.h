#import <Foundation/Foundation.h>

// Local cache stores only a source digest and completed Vietnamese text, never the API key.
@interface DGTranslationStore : NSObject
- (instancetype)initWithURL:(NSURL *)url;
- (NSString *)translationForSource:(NSString *)source;
- (void)saveTranslation:(NSString *)translation source:(NSString *)source;
@end

// Main-thread state machine. The caller supplies monotonic time and ONLY observations
// from an explicitly entered comment-AI tab. One automatic request per entry, no retries.
@interface DGTranslationSession : NSObject
@property(nonatomic,readonly) BOOL active;
@property(nonatomic,readonly) BOOL waiting;
@property(nonatomic,copy) void (^update)(NSString *state,NSString *text);
- (instancetype)initWithStore:(DGTranslationStore *)store
                       sender:(void (^)(NSString *,void (^)(NSString *,NSString *)))sender
                       cancel:(void (^)(void))cancel;
- (void)enterAt:(NSTimeInterval)time;
- (void)observeSource:(NSString *)source at:(NSTimeInterval)time;
- (void)observeSource:(NSString *)source complete:(BOOL)complete at:(NSTimeInterval)time;
- (void)leave;
- (void)retryAt:(NSTimeInterval)time;
@end
