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
@property (strong) id completionResult;
@property (strong) id completionError;
@property BOOL completionFlag;
- (BOOL)defaultFalse;
- (BOOL)oneObject:(id)value;
- (BOOL)twoObjects:(id)a second:(id)b;
- (BOOL)oneBool:(BOOL)value;
- (BOOL)twoBools:(BOOL)a second:(BOOL)b;
- (void)trigger;
+ (BOOL)classGate;
- (void)completed:(id)result error:(id)error;
- (void)completed:(id)result error:(id)error flag:(BOOL)flag;
@end
@implementation TestOperations
- (BOOL)defaultFalse { return NO; }
- (BOOL)oneObject:(id)value { return [value isEqual:@"expected"]; }
- (BOOL)twoObjects:(id)a second:(id)b { return [a isEqual:@"first"] && [b isEqual:@"second"]; }
- (BOOL)oneBool:(BOOL)value { return value; }
- (BOOL)twoBools:(BOOL)a second:(BOOL)b { return a && !b; }
- (void)trigger { self.calls += 1; }
+ (BOOL)classGate { return YES; }
- (void)completed:(id)result error:(id)error { self.completionResult=result; self.completionError=error; self.calls++; }
- (void)completed:(id)result error:(id)error flag:(BOOL)flag { [self completed:result error:error]; self.completionFlag=flag; }
@end

static void check(BOOL condition, NSString *message) {
    if (!condition) { NSLog(@"FAIL: %@", message); exit(1); }
}

@interface TestSearchAdapter : NSObject
+ (BOOL)enableGuestSearch;
+ (BOOL)hasRemainingGuestSearchCount;
@end
@implementation TestSearchAdapter
+ (BOOL)enableGuestSearch { return NO; }
+ (BOOL)hasRemainingGuestSearchCount { return NO; }
@end
@interface TestSearchChildAdapter : TestSearchAdapter
@end
@implementation TestSearchChildAdapter
@end
@interface TestWrongSearchAdapter : NSObject
+ (BOOL)enableGuestSearch;
+ (NSInteger)hasRemainingGuestSearchCount;
@end
@implementation TestWrongSearchAdapter
+ (BOOL)enableGuestSearch { return NO; }
+ (NSInteger)hasRemainingGuestSearchCount { return 42; }
@end
@interface TestSearchResolver : NSObject
@property (class) Class adapter;
+ (Class)resolvedAdapter;
- (BOOL)statusCode:(id)code message:(id)message;
@property (strong) id receivedCode;
@property (strong) id receivedMessage;
@end
static Class fixtureSearchAdapter;
@implementation TestSearchResolver
+ (Class)adapter { return fixtureSearchAdapter; }
+ (void)setAdapter:(Class)value { fixtureSearchAdapter = value; }
+ (Class)resolvedAdapter { return fixtureSearchAdapter; }
- (BOOL)statusCode:(id)code message:(id)message {
    self.receivedCode = code; self.receivedMessage = message; return [code isEqual:@2483];
}
@end

@interface TestPresentation : NSObject
@property (strong) id raw;
- (id)displayText;
- (id)displayRich;
- (id)survey;
- (id)list;
- (void)configure:(id)config;
@end
@implementation TestPresentation
- (id)displayText { return self.raw; }
- (id)displayRich { return self.raw; }
- (id)survey { return self.raw; }
- (id)list { return self.raw; }
- (void)configure:(id)config { self.raw=config; }
@end

@interface AWEBaseApiModel : NSObject
@property (strong) id statusCode;
@end
@implementation AWEBaseApiModel
@end

@interface TestImageFeed : NSObject
@property NSUInteger calls;
@property NSUInteger requestType;
@property NSInteger source;
@property (strong) NSArray *arguments;
- (void)feed:(NSUInteger)kind response:(id)response error:(id)error;
- (void)failed:(id)error;
- (void)finish:(id)image data:(id)data path:(id)path url:(id)url source:(NSInteger)source;
@end
@implementation TestImageFeed
- (void)feed:(NSUInteger)kind response:(id)response error:(id)error { self.calls++; self.requestType=kind; self.arguments=@[response ?: NSNull.null,error ?: NSNull.null]; }
- (void)failed:(id)error { self.calls++; self.arguments=@[error ?: NSNull.null]; }
- (void)finish:(id)image data:(id)data path:(id)path url:(id)url source:(NSInteger)source {
    self.calls++; self.source=source; self.arguments=@[image ?: NSNull.null,data ?: NSNull.null,path ?: NSNull.null,url ?: NSNull.null];
}
@end

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
        check([DGTranslate(@"  首页\t", words) isEqual:@"  Home\t"], @"control padding preserved around an exact title");
        check([DGTranslate(@"这是 首页", words) isEqual:@"这是 首页"], @"padding lookup does not translate sentence substrings");
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
        NSMutableDictionary *diagnostics=[NSMutableDictionary new];
        __block BOOL observe=YES;
        for (NSArray *op in @[@[@"completed:error:",@"observeFeedCompletion2"],
                               @[@"completed:error:flag:",@"observeFeedCompletion2Bool"]]) {
            Method method=class_getInstanceMethod(TestOperations.class,NSSelectorFromString(op[0]));
            NSDictionary *operationSpec=@{@"class":@"TestOperations",@"selector":op[0],@"types":[NSString stringWithUTF8String:method_getTypeEncoding(method)],@"operation":op[1]};
            check(DGInstallHook(operationSpec,^BOOL{return observe;},^(NSString *event,NSUInteger n){diagnostics[event]=@([diagnostics[event] unsignedIntegerValue]+n);}),@"observe hook installs with exact ABI");
        }
        NSError *networkError=[NSError errorWithDomain:NSURLErrorDomain code:-1009 userInfo:@{NSLocalizedDescriptionKey:@"PRIVATE description",NSURLErrorFailingURLStringErrorKey:@"https://private.example/?token=PRIVATE"}];
        object.calls=0;
        [object completed:input error:networkError flag:YES];
        check(object.calls==1 && object.completionResult==input && object.completionError==networkError && object.completionFlag,
              @"observing an error forwards every callback argument without modifying the failure");
        check([diagnostics[@"TestOperations completed:error:flag: error URL -1009"] unsignedIntegerValue]==1,@"fixed error category and numeric code recorded");
        check([[diagnostics.description lowercaseString] rangeOfString:@"private"].location==NSNotFound,@"diagnostics omit error descriptions and URL/userInfo");
        [object completed:nil error:@"unusual error object"];
        check([diagnostics[@"TestOperations completed:error: non-NSError failure"] unsignedIntegerValue]==1,@"unknown error object does not get treated as NSError");
        observe=NO;NSUInteger logged=diagnostics.count;
        [object completed:input error:nil flag:NO];
        check(object.completionResult==input && object.completionError==nil && !object.completionFlag && diagnostics.count==logged,
              @"observation switch preserves original success handling");
        __block BOOL search = NO;
        NSMutableDictionary *searchEvents = [NSMutableDictionary new];
        DGRecord recordSearch = ^(NSString *event, NSUInteger n) { searchEvents[event] = @([searchEvents[event] unsignedIntegerValue] + n); };
        TestSearchResolver.adapter = TestSearchChildAdapter.class;
        Method resolver = class_getClassMethod(TestSearchResolver.class, @selector(resolvedAdapter));
        check(DGInstallHook(@{@"class":@"TestSearchResolver",@"selector":@"resolvedAdapter",@"class_method":@YES,
              @"types":[NSString stringWithUTF8String:method_getTypeEncoding(resolver)],@"operation":@"observeSearchAdapter"},
              ^BOOL{return search;},recordSearch),@"search resolver installs with Class return ABI");
        check([TestSearchResolver resolvedAdapter] == TestSearchChildAdapter.class && ![TestSearchChildAdapter enableGuestSearch],
              @"disabled search resolver preserves class and original flags");
        search = YES;
        check([TestSearchResolver resolvedAdapter] == TestSearchChildAdapter.class && ![TestSearchChildAdapter enableGuestSearch] &&
              ![TestSearchChildAdapter hasRemainingGuestSearchCount] && ![TestSearchAdapter enableGuestSearch],
              @"guest policy and quota remain original on child and superclass");
        [TestSearchResolver resolvedAdapter];
        check([DGSearchAdapterSnapshot()[@"installed"] unsignedIntegerValue] == 0 && [DGSearchAdapterSnapshot()[@"active"] unsignedIntegerValue] == 0 &&
              [DGSearchAdapterSnapshot()[@"adapter_classes"] unsignedIntegerValue] == 1,
              @"search adapter is observed once without modifying its methods");
        search = NO;
        check(![TestSearchChildAdapter enableGuestSearch] && ![TestSearchChildAdapter hasRemainingGuestSearchCount],
              @"switching search off forwards both original guest gates");
        search = YES; TestSearchResolver.adapter = TestWrongSearchAdapter.class;
        [TestSearchResolver resolvedAdapter];
        check(![TestWrongSearchAdapter enableGuestSearch] && [TestWrongSearchAdapter hasRemainingGuestSearchCount] == 42,
              @"both adapter methods preflight before any partial incompatible modification");
        TestSearchResolver.adapter = Nil;
        check([TestSearchResolver resolvedAdapter] == Nil,@"nil adapter remains nil");
        check([searchEvents[@"Search gateway returned nil"] unsignedIntegerValue]==1 &&
              [searchEvents[@"Search compatible adapter observed"] unsignedIntegerValue]==1,
              @"gateway nil and compatible results are separately counted");
        Method status = class_getInstanceMethod(TestSearchResolver.class,@selector(statusCode:message:));
        check(DGInstallHook(@{@"class":@"TestSearchResolver",@"selector":@"statusCode:message:",@"operation":@"observeSearchStatus",
                            @"types":[NSString stringWithUTF8String:method_getTypeEncoding(status)]},^BOOL{return YES;},recordSearch),
              @"search status observer installs");
        TestSearchResolver *statusObject = [TestSearchResolver new];
        id privateMessage = @"PRIVATE cookie and keyword";
        check([statusObject statusCode:@2483 message:privateMessage] && statusObject.receivedMessage == privateMessage &&
              [statusObject.receivedCode isEqual:@2483],@"server login status and original message remain intact");
        check([searchEvents[@"Search status code 2483"] unsignedIntegerValue] == 1 &&
              [searchEvents.description rangeOfString:@"PRIVATE"].location == NSNotFound,
              @"search diagnostics log numeric status without message or query");
        NSDictionary *controlWords=@{@"回复":@"Reply",@"网络错误":@"Network error",@"满意":@"Satisfied",@"一般":@"Neutral"};
        check([DGTranslateControl(@"评论 1081",controlWords) isEqual:@"Comments 1081"] &&
              [DGTranslateControl(@"展开1条回复",controlWords) isEqual:@"View 1 reply"] &&
              [DGTranslateControl(@"展开 12 条回复",controlWords) isEqual:@"View 12 replies"],@"anchored comment controls preserve counts and pluralization");
        check([DGTranslateControl(@"他说展开1条回复就能看到",controlWords) isEqual:@"他说展开1条回复就能看到"] &&
              [DGTranslateControl(@"展开1条回复\n",controlWords) isEqual:@"展开1条回复\n"],@"control templates do not match embedded sentences or a trailing newline");
        NSMutableAttributedString *collection=[[NSMutableAttributedString alloc] initWithString:@"观看完整合集：测试合集" attributes:@{@"role":@"prefix"}];
        [collection addAttributes:@{@"role":@"title",@"link":@"PRIVATE-collection-id"} range:NSMakeRange(7,4)];
        NSAttributedString *localizedCollection=DGTranslateControlAttributed(collection,controlWords);
        check([localizedCollection.string isEqual:@"Collection: 测试合集"] &&
              [[localizedCollection attribute:@"link" atIndex:12 effectiveRange:NULL] isEqual:@"PRIVATE-collection-id"] &&
              [[localizedCollection attribute:@"role" atIndex:12 effectiveRange:NULL] isEqual:@"title"],@"collection prefix translation preserves mixed title content and link attributes");
        NSDictionary *configuration=@{@"ratingPointDes":@"一般,满意",@"textPlaceholder":@"回复",@"bizParams":@{@"text":@"满意"},@"postedText":@"满意",@"minCount":@1};
        NSDictionary *localizedConfig=DGTranslateEvaluationConfig(configuration,controlWords);
        check([localizedConfig[@"ratingPointDes"] isEqual:@"Neutral,Satisfied"] &&
              [localizedConfig[@"textPlaceholder"] isEqual:@"Reply"] &&
              localizedConfig[@"bizParams"]==configuration[@"bizParams"] && [localizedConfig[@"postedText"] isEqual:@"满意"] &&
              [configuration[@"textPlaceholder"] isEqual:@"回复"],@"verified evaluation config keys translate without mutation or translating posted text");
        NSDictionary *survey=@{@"question":@"你对该视频下的评论氛围是否满意?",@"options":@[@{@"id":@1,@"label":@"一般",@"value":@"一般"},@{@"id":@2,@"label":@"满意"}],@"uri":@"PRIVATE-uri",@"bizParams":@{@"text":@"满意"}};
        NSDictionary *englishSurvey=DGTranslateSurvey(survey);
        check([englishSurvey[@"options"][0][@"label"] isEqual:@"Neutral"] &&
              [englishSurvey[@"options"][1][@"id"] isEqual:@2] && englishSurvey[@"uri"]==survey[@"uri"] &&
              [englishSurvey[@"options"][0][@"value"] isEqual:@"一般"] && englishSurvey[@"bizParams"]==survey[@"bizParams"],@"survey exact chrome translates while IDs, option values, unknown branches and schema values stay intact");
        NSString *surveyJSON=@"{\"label\":\"一般\",\"id\":42}";
        id parsed=[NSJSONSerialization JSONObjectWithData:[DGTranslateSurvey(surveyJSON) dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
        check([parsed[@"label"] isEqual:@"Neutral"] && [parsed[@"id"] isEqual:@42],@"survey JSON preserves string container and numeric IDs");
        NSString *invalidJSON=@"PRIVATE malformed JSON";
        check(DGTranslateSurvey(invalidJSON)==invalidJSON,@"malformed survey JSON preserves original object");
        id deep=@"满意"; for (NSUInteger i=0;i<14;i++) deep=@[deep];
        check(DGTranslateSurvey(deep)==deep,@"overdeep survey returns original without partial translation");
        NSMutableArray *large=[NSMutableArray new];for (NSUInteger i=0;i<2050;i++) [large addObject:@"满意"];
        check(DGTranslateSurvey(large)==large,@"survey traversal has bounded work and rejects oversized payload atomically");
        NSMutableDictionary *newEvents=[NSMutableDictionary new];
        DGRecord recordNew=^(NSString *event,NSUInteger n){newEvents[event]=@([newEvents[event] unsignedIntegerValue]+n);};
        __block BOOL localize=YES;
        for (NSArray *op in @[@[@"displayText",@"translateGetter"],@[@"displayRich",@"translateRichGetter"],
                              @[@"survey",@"translateSurveyGetter"],@[@"configure:",@"translateConfig1"]]) {
            Method method=class_getInstanceMethod(TestPresentation.class,NSSelectorFromString(op[0]));
            NSDictionary *s=@{@"class":@"TestPresentation",@"selector":op[0],@"operation":op[1],@"types":[NSString stringWithUTF8String:method_getTypeEncoding(method)]};
            check(DGInstallLocalizedHook(s,^BOOL{return localize;},recordNew,controlWords),@"presentation hook exact ABI installs");
        }
        TestPresentation *presentation=[TestPresentation new];presentation.raw=@"网络错误";
        check([presentation.displayText isEqual:@"Network error"] && [presentation.raw isEqual:@"网络错误"],@"premeasurement getter translates without changing stored value");
        localize=NO;check(presentation.displayText==presentation.raw,@"English OFF forwards original getter object");
        [presentation configure:configuration];check(presentation.raw==configuration,@"English OFF forwards original config object");
        localize=YES;[presentation configure:configuration];check([presentation.raw isEqual:localizedConfig],@"config hook maps before the renderer consumes it");
        presentation.raw=collection;check([presentation.displayRich isEqualToAttributedString:localizedCollection],@"rich presentation hook preserves title links");
        presentation.raw=survey;check([presentation.survey isEqual:englishSurvey],@"survey getter hook uses bounded exact chrome mapping");
        presentation.raw=@42;check(presentation.displayText==presentation.raw,@"unknown getter value type stays original");
        for (NSArray *op in @[@[@"feed:response:error:",@"observeFeedRequest"],@[@"failed:",@"observeError1"],
                              @[@"finish:data:path:url:source:",@"observeImageFinish"]]) {
            Method method=class_getInstanceMethod(TestImageFeed.class,NSSelectorFromString(op[0]));
            check(DGInstallHook(@{@"class":@"TestImageFeed",@"selector":op[0],@"operation":op[1],@"types":[NSString stringWithUTF8String:method_getTypeEncoding(method)]},^BOOL{return localize;},recordNew),@"image/feed observers install with verified argument types");
        }
        TestImageFeed *imageFeed=[TestImageFeed new];
        [imageFeed feed:NSUIntegerMax response:input error:networkError];
        check(imageFeed.calls==1 && imageFeed.requestType==NSUIntegerMax && imageFeed.arguments[0]==input && imageFeed.arguments[1]==networkError,@"DC feed observer preserves request type, response, error and exactly one callback");
        AWEBaseApiModel *serverResponse=[AWEBaseApiModel new];serverResponse.statusCode=@2483;
        [imageFeed feed:2 response:serverResponse error:nil];
        check(imageFeed.arguments[0]==serverResponse && [serverResponse.statusCode isEqual:@2483] &&
              [newEvents[@"TestImageFeed feed:response:error: response status code 2483"] unsignedIntegerValue]==1,
              @"typed response status is observed independently from a nil NSError and is not rewritten");
        imageFeed.calls=1;
        [imageFeed failed:networkError];check(imageFeed.calls==2 && imageFeed.arguments[0]==networkError,@"image failure observer leaves native retry/error handling intact");
        [imageFeed finish:video data:input path:@"PRIVATE-path" url:@"PRIVATE-url" source:-1];
        check(imageFeed.calls==3 && imageFeed.source==-1 && imageFeed.arguments[0]==video && [imageFeed.arguments[3] isEqual:@"PRIVATE-url"],@"image finish observer forwards all arguments and negative source unchanged");
        check([newEvents[@"Image SDK finish with image"] unsignedIntegerValue]==1 &&
              [newEvents.description rangeOfString:@"PRIVATE"].location==NSNotFound,@"new image/feed diagnostics omit URLs, paths, image data and error descriptions");
        localize=NO;NSDictionary *before=[newEvents copy];[imageFeed failed:networkError];
        check(imageFeed.calls==4 && [newEvents isEqual:before],@"observer OFF still forwards callback once without collecting events");
        Method listMethod=class_getInstanceMethod(TestPresentation.class,@selector(list));
        check(DGInstallHook(@{@"class":@"TestPresentation",@"selector":@"list",@"operation":@"observeListGetter",@"types":[NSString stringWithUTF8String:method_getTypeEncoding(listMethod)]},^BOOL{return YES;},recordNew),@"comment list observation installs");
        presentation.raw=input;check(presentation.list==input,@"comment list identity, content and pagination are untouched");
        NSLog(@"PASS: policy and runtime-hook regressions");
    }
    return 0;
}
