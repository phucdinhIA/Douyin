#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "DGPolicy.h"
#import "DGHook.h"

@interface TestModel : NSObject
@property BOOL isAds;
@end
@implementation TestModel
@end
@interface WrongModel : NSObject
- (NSString *)isAds;
@end
@implementation WrongModel
- (NSString *)isAds { return @"Do not call me as BOOL"; }
@end
@interface TestParent : NSObject
- (BOOL)canShow;
@end
@implementation TestParent
- (BOOL)canShow { return YES; }
@end
@interface TestChild : TestParent
@end
@implementation TestChild
@end

static void check(BOOL condition, NSString *message) {
    if (!condition) { NSLog(@"FAIL: %@", message); exit(1); }
}

int main(void) {
    @autoreleasepool {
        TestModel *video = [TestModel new], *ad = [TestModel new]; ad.isAds = YES;
        WrongModel *wrong = [WrongModel new]; id unknown = [NSObject new];
        NSUInteger count = 99;
        check(DGFilterAds(nil, &count) == nil && count == 0, @"nil stays nil");
        check([DGFilterAds(@"not an array", &count) isEqual:@"not an array"] && count == 0, @"non-array stays intact");
        NSArray *input = @[video, ad, wrong, unknown, video, ad];
        NSArray *result = DGFilterAds(input, &count);
        check(count == 2 && [result isEqual:@[video, wrong, unknown, video]], @"filter preserves order and unknown model types");
        check(input.count == 6 && ![result isKindOfClass:NSMutableArray.class], @"immutable input not mutated");
        NSArray *clean = @[video, unknown];
        check(DGFilterAds(clean, NULL) == clean, @"clean list preserves identity");
        NSMutableArray *mutable = [input mutableCopy];
        id filtered = DGFilterAds(mutable, NULL);
        check([filtered isKindOfClass:NSMutableArray.class] && mutable.count == 6, @"mutable contract without mutating source");
        check([DGFilterAds(@[ad,ad], NULL) count] == 0, @"all-ad page produces valid empty array");
        NSDictionary *words = @{@"首页":@"Home", @"更多功能":@"More options"};
        check([DGTranslate(@"首页", words) isEqual:@"Home"], @"exact label translation");
        check([DGTranslate(@"这是首页的视频", words) isEqual:@"这是首页的视频"], @"no substring rewriting of content");
        check([DGTranslate(@"", words) isEqual:@""], @"empty text");
        NSAttributedString *styled = [[NSAttributedString alloc] initWithString:@"更多功能" attributes:@{@"intent":@"button"}];
        NSAttributedString *translated = DGTranslateAttributed(styled, words);
        check([translated.string isEqual:@"More options"] && [[translated attribute:@"intent" atIndex:0 effectiveRange:NULL] isEqual:@"button"], @"attributed title style preserved");
        NSMutableAttributedString *mixed = [styled mutableCopy];
        [mixed addAttribute:@"intent" value:@"link" range:NSMakeRange(0,1)];
        check(DGTranslateAttributed(mixed, words) == mixed, @"mixed styles left intact");
        __block BOOL enabled = YES;
        __block NSUInteger events = 0;
        Method original = class_getInstanceMethod(TestChild.class, @selector(canShow));
        NSString *type = [NSString stringWithUTF8String:method_getTypeEncoding(original)];
        NSDictionary *spec = @{@"class":@"TestChild",@"selector":@"canShow",@"types":type,@"operation":@"false0",@"class_method":@NO};
        check(DGInstallHook(spec, ^BOOL {return enabled;}, ^(NSString *event, NSUInteger n){ (void)event; events += n;}), @"hook installation");
        check(![[TestChild new] canShow] && [[TestParent new] canShow], @"inherited override isolated from parent");
        enabled = NO;
        check([[TestChild new] canShow], @"disabled hook calls original");
        NSDictionary *bad = @{@"class":@"TestParent",@"selector":@"canShow",@"types":@"@16@0:8",@"operation":@"false0"};
        check(!DGInstallHook(bad, ^BOOL {return YES;}, ^(NSString *event, NSUInteger n){(void)event; (void)n;}), @"signature mismatch rejected");
        check([[TestParent new] canShow] && events >= 2, @"failed hook preserves parent");
        NSLog(@"PASS: policy and runtime-hook regressions");
    }
    return 0;
}
