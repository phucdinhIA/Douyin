#import "DGTranslation.h"
#import <CommonCrypto/CommonDigest.h>
#include <float.h>

static NSString *DGTranslationDigest(NSString *source) {
    if (![source isKindOfClass:NSString.class] || !source.length || source.length>24000) return nil;
    NSData *data=[[@"vi|gemini-3.5-flash-lite|translation-v1|" stringByAppendingString:source] dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];CC_SHA256(data.bytes,(CC_LONG)data.length,digest);
    NSMutableString *hex=[NSMutableString new];for (NSUInteger i=0;i<sizeof(digest);++i) [hex appendFormat:@"%02x",digest[i]];return hex;
}
@interface DGTranslationStore ()
@property(nonatomic,strong) NSURL *url;
@property(nonatomic,strong) NSMutableDictionary *entries;
- (void)removeOldest;
@end
@implementation DGTranslationStore
- (instancetype)initWithURL:(NSURL *)url {
    if ((self=[super init])) {
        _url=url;_entries=[NSMutableDictionary new];
        NSNumber *size=nil;[url getResourceValue:&size forKey:NSURLFileSizeKey error:NULL];
        NSData *data=url && size.unsignedIntegerValue<=2*1024*1024 ? [NSData dataWithContentsOfURL:url] : nil;
        id root=data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL] : nil;
        if ([root isKindOfClass:NSDictionary.class] && [root[@"version"] isEqual:@1] && [root[@"entries"] isKindOfClass:NSDictionary.class]) {
            NSDictionary *saved=root[@"entries"];
            for (NSString *key in saved) {
                id entry=saved[key];
                if (key.length==64 && [entry isKindOfClass:NSDictionary.class] && [entry[@"text"] isKindOfClass:NSString.class] && [entry[@"text"] length]>0 && [entry[@"text"] length]<=32000 && [entry[@"used"] isKindOfClass:NSNumber.class] && _entries.count<32) _entries[key]=entry;
            }
        }
    }return self;
}
- (NSString *)translationForSource:(NSString *)source {
    NSString *key=DGTranslationDigest(source);NSDictionary *entry=key ? self.entries[key] : nil;
    if (entry) self.entries[key]=@{@"text":entry[@"text"],@"used":@(NSDate.date.timeIntervalSince1970)};
    return entry[@"text"];
}
- (void)saveTranslation:(NSString *)translation source:(NSString *)source {
    NSString *key=DGTranslationDigest(source);
    if (!key || ![translation isKindOfClass:NSString.class] || !translation.length || translation.length>32000) return;
    self.entries[key]=@{@"text":translation,@"used":@(NSDate.date.timeIntervalSince1970)};
    while (self.entries.count>32) [self removeOldest];
    NSData *data=[NSJSONSerialization dataWithJSONObject:@{@"version":@1,@"entries":self.entries} options:0 error:NULL];
    while (data.length>2*1024*1024 && self.entries.count) {
        [self removeOldest];data=[NSJSONSerialization dataWithJSONObject:@{@"version":@1,@"entries":self.entries} options:0 error:NULL];
    }
    if (!self.url) return;
    [NSFileManager.defaultManager createDirectoryAtURL:[self.url URLByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
    [data writeToURL:self.url options:NSDataWritingAtomic error:NULL];
    [self.url setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:NULL];
}
- (void)removeOldest {
    NSString *oldest=nil;double minimum=DBL_MAX;
    for (NSString *item in self.entries) {double used=[self.entries[item][@"used"] doubleValue];if (!oldest || used<minimum) {oldest=item;minimum=used;}}
    if (oldest) [self.entries removeObjectForKey:oldest];
}
@end

@interface DGTranslationSession ()
@property(nonatomic,strong) DGTranslationStore *store;
@property(nonatomic,copy) void (^sender)(NSString *,void (^)(NSString *,NSString *));
@property(nonatomic,copy) void (^cancelRequest)(void);
@property(nonatomic,readwrite) BOOL active;
@property(nonatomic,readwrite) BOOL waiting;
@property(nonatomic) NSTimeInterval entered;
@property(nonatomic) NSTimeInterval changed;
@property(nonatomic) NSUInteger generation;
@property(nonatomic,copy) NSString *source;
@end
@implementation DGTranslationSession
- (instancetype)initWithStore:(DGTranslationStore *)store sender:(void (^)(NSString *,void (^)(NSString *,NSString *)))sender cancel:(void (^)(void))cancel {
    if ((self=[super init])) {_store=store;_sender=[sender copy];_cancelRequest=[cancel copy];}return self;
}
- (void)enterAt:(NSTimeInterval)time {
    if (self.active) return;
    self.active=YES;self.waiting=YES;self.entered=time;self.changed=time;self.source=nil;++self.generation;
    if (self.update) self.update(@"waiting",@"Đang chờ phần phân tích tải ổn định…");
}
- (void)observeSource:(NSString *)source at:(NSTimeInterval)time {
    if (!self.active || !self.waiting) return;
    source=[source stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (![self.source isEqualToString:source]) {self.source=[source copy];self.changed=time;}
    if (time-self.entered>=60) {self.waiting=NO;if (self.update) self.update(@"failed",@"Chưa lấy được phân tích ổn định. Bấm Dịch lại khi nội dung đã tải xong.");return;}
    if (!source.length || source.length>24000 || time-self.entered<4 || time-self.changed<3) return;
    self.waiting=NO;
    NSString *cached=[self.store translationForSource:source];
    if (cached) {if (self.update) self.update(@"cached",cached);return;}
    if (self.update) self.update(@"sending",@"Đang dịch sang tiếng Việt bằng Gemini…");
    NSUInteger request=self.generation;__weak DGTranslationSession *weakSelf=self;
    self.sender(source,^(NSString *answer,NSString *failure) {
        DGTranslationSession *owner=weakSelf;if (!owner.active || request!=owner.generation) return;
        if (answer.length) {[owner.store saveTranslation:answer source:source];if (owner.update) owner.update(@"ready",answer);}
        else if (owner.update) owner.update(@"failed",failure ?: @"Không dịch được. Bấm Dịch lại để thử thủ công.");
    });
}
- (void)leave {self.active=NO;self.waiting=NO;++self.generation;self.source=nil;if (self.cancelRequest) self.cancelRequest();}
- (void)retryAt:(NSTimeInterval)time {[self leave];[self enterAt:time];}
@end
