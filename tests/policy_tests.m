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
@interface AWEAwemeModel : TestModel
@property BOOL checkIsAd;
@property BOOL isHardAdModel;
@property BOOL isHardAd;
@end
@implementation AWEAwemeModel
@end
@interface UnrelatedModel : NSObject
- (BOOL)checkIsAd;
@end
@implementation UnrelatedModel
- (BOOL)checkIsAd { return YES; }
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
@interface TestOperations : NSObject
@property (strong) id items;
@property NSUInteger calls;
- (BOOL)defaultFalse;
- (BOOL)oneObject:(id)value;
- (BOOL)twoObjects:(id)a second:(id)b;
- (BOOL)oneBool:(BOOL)value;
- (BOOL)twoBools:(BOOL)a second:(BOOL)b;
- (void)trigger;
+ (BOOL)classGate;
@end
@implementation TestOperations
- (BOOL)defaultFalse { return NO; }
- (BOOL)oneObject:(id)value { return [value isEqual:@"expected"]; }
- (BOOL)twoObjects:(id)a second:(id)b { return [a isEqual:@"first"] && [b isEqual:@"second"]; }
- (BOOL)oneBool:(BOOL)value { return value; }
- (BOOL)twoBools:(BOOL)a second:(BOOL)b { return a && !b; }
- (void)trigger { self.calls += 1; }
+ (BOOL)classGate { return YES; }
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
        AWEAwemeModel *soft = [AWEAwemeModel new], *hard = [AWEAwemeModel new], *hardModel = [AWEAwemeModel new];
        soft.checkIsAd = YES; hard.isHardAd = YES; hardModel.isHardAdModel = YES;
        UnrelatedModel *unrelated = [UnrelatedModel new];
        check([DGFilterAds(@[video,soft,hard,hardModel,unrelated], &count) isEqual:@[video,unrelated]] && count == 3,
              @"additional verified ad flags without removing unrelated models");
        check(!DGIsAdModel([AWEAwemeModel new]), @"ordinary Aweme model stays visible");
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
        Method wrongReturn = class_getInstanceMethod(WrongModel.class,@selector(isAds));
        NSDictionary *wrongOperation = @{@"class":@"WrongModel",@"selector":@"isAds",@"types":[NSString stringWithUTF8String:method_getTypeEncoding(wrongReturn)],@"operation":@"false0"};
        check(!DGInstallHook(wrongOperation,^BOOL {return YES;},^(NSString *event,NSUInteger n){(void)event;(void)n;}),@"matching metadata does not allow an ABI-incompatible operation");
        check(!DGInstallHook(@{@"class":NSNull.null},^BOOL {return YES;},^(NSString *event,NSUInteger n){(void)event;(void)n;}),@"malformed hook spec rejected without a crash");
        NSArray *ops = @[
            @[@"defaultFalse",@"true0"], @[@"oneObject:",@"falseObject1"],
            @[@"twoObjects:second:",@"falseObject2"], @[@"oneBool:",@"falseBool1"],
            @[@"twoBools:second:",@"falseBool2"], @[@"trigger",@"noop0"],
            @[@"items",@"filterGetter"], @[@"setItems:",@"filterSetter"],
            @[@"classGate",@"false0"]
        ];
        __block BOOL features = YES;
        for (NSArray *op in ops) {
            BOOL isClass = [op[0] isEqual:@"classGate"];
            Class cls = isClass ? object_getClass(TestOperations.class) : TestOperations.class;
            Method method = class_getInstanceMethod(cls,NSSelectorFromString(op[0]));
            NSDictionary *operationSpec = @{@"class":@"TestOperations",@"selector":op[0],@"types":[NSString stringWithUTF8String:method_getTypeEncoding(method)],@"operation":op[1],@"class_method":@(isClass)};
            check(DGInstallHook(operationSpec,^BOOL {return features;},^(NSString *event,NSUInteger n){(void)event;(void)n;}),op[0]);
        }
        TestOperations *object = [TestOperations new];
        check(object.defaultFalse && ![TestOperations classGate],@"instance and metaclass hooks");
        check(![object oneObject:@"expected"] && ![object twoObjects:@"first" second:@"second"],@"object argument hooks enabled");
        check(![object oneBool:YES] && ![object twoBools:YES second:NO],@"BOOL argument hooks enabled");
        [object trigger]; check(object.calls == 0,@"disabled local trigger not invoked");
        object.items = input;
        check([object.items isEqual:result] && input.count == 6,@"response setter removes ads without mutating source");
        Ivar itemsIvar = class_getInstanceVariable(TestOperations.class,"_items");
        object_setIvar(object,itemsIvar,input);
        check([object.items isEqual:result],@"getter covers a list set without using its setter");
        features = NO;
        check(!object.defaultFalse && [TestOperations classGate],@"metaclass original restored by switch");
        check([object oneObject:@"expected"] && [object twoObjects:@"first" second:@"second"],@"original object arguments forwarded");
        check([object oneBool:YES] && [object twoBools:YES second:NO],@"original BOOL arguments forwarded");
        [object trigger]; check(object.calls == 1,@"original local trigger forwarded");
        object.items = input; check(object.items == input,@"response getters and setters bypass filtering when switched off");
        NSLog(@"PASS: policy and runtime-hook regressions");
    }
    return 0;
}
