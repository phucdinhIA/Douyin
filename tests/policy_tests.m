#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "DGPolicy.h"
#import "DGHook.h"

@interface TTHttpResponse : NSObject
@property NSInteger statusCode;
@property (strong) NSString *MIMEType;
@end
@implementation TTHttpResponse
@end

@interface AWEDCFeedDefaultDataController : NSObject
- (void)initFetchWithCompletion:(void (^)(id,NSError *))completion;
- (void)refreshWithCompletion:(void (^)(id,NSError *))completion;
- (void)loadMoreWithCompletion:(void (^)(id,NSError *))completion;
@end
@implementation AWEDCFeedDefaultDataController
- (void)initFetchWithCompletion:(void (^)(id,NSError *))completion {if (completion) completion(nil,nil);}
- (void)refreshWithCompletion:(void (^)(id,NSError *))completion {[self initFetchWithCompletion:completion];}
- (void)loadMoreWithCompletion:(void (^)(id,NSError *))completion {[self initFetchWithCompletion:completion];}
@end

@interface AWEDCFeedDefaultDataControllerWrapper : NSObject
@property NSUInteger calls;
@property (strong) id parameters;
@property (strong) id arguments;
@property (strong) id result;
@property (strong) NSError *error;
@property (strong) id dataController;
- (void)fetchDataWithRequestParams:(id)params args:(id)args completion:(void (^)(id,NSError *))completion;
- (void)refreshDataWithRequestParams:(id)params args:(id)args completion:(void (^)(id,NSError *))completion;
- (void)loadMoreDataWithRequestParams:(id)params args:(id)args completion:(void (^)(id,NSError *))completion;
@end
@implementation AWEDCFeedDefaultDataControllerWrapper
- (void)fetchDataWithRequestParams:(id)params args:(id)args completion:(void (^)(id,NSError *))completion {
    self.calls++;self.parameters=params;self.arguments=args;if (completion) completion(self.result,self.error);
}
- (void)refreshDataWithRequestParams:(id)params args:(id)args completion:(void (^)(id,NSError *))completion { [self fetchDataWithRequestParams:params args:args completion:completion]; }
- (void)loadMoreDataWithRequestParams:(id)params args:(id)args completion:(void (^)(id,NSError *))completion { [self fetchDataWithRequestParams:params args:args completion:completion]; }
@end
@interface TestFeedManager : NSObject
@property NSUInteger decisions;
@property NSUInteger chunkCalls;
@property BOOL nativeChunk;
@property (strong) id dataController;
- (BOOL)shouldRequestWithChunk;
@end
@implementation TestFeedManager
- (BOOL)shouldRequestWithChunk {self.decisions++;return self.nativeChunk;}
@end

// Contract fixtures for the body/loader decisions found in build 406019.
// These are not a runtime test of the proprietary network managers.
@interface AWEFeedDoubleColumnListDataController : AWEDCFeedDefaultDataControllerWrapper
@property BOOL nativeChunk;
@property BOOL selectedChunk;
@property NSUInteger decisions;
@property (strong) NSDictionary *body;
- (BOOL)enableChunkRequest;
- (void)addBodyParamsForChunkModel:(NSMutableDictionary *)body;
@end
@implementation AWEFeedDoubleColumnListDataController
- (BOOL)enableChunkRequest {self.decisions++;return self.nativeChunk;}
- (void)addBodyParamsForChunkModel:(NSMutableDictionary *)body {
    if (self.enableChunkRequest) body[@"is_tidy"]=@"true";
}
- (void)fetchDataWithRequestParams:(id)params args:(id)args completion:(void (^)(id,NSError *))completion {
    NSMutableDictionary *body=[params mutableCopy];
    [self addBodyParamsForChunkModel:body];self.body=body;
    self.selectedChunk=self.enableChunkRequest;
    [super fetchDataWithRequestParams:params args:args completion:completion];
}
@end
@interface AWESearchCachalotDCFeedDataController : AWEFeedDoubleColumnListDataController
@end
@implementation AWESearchCachalotDCFeedDataController
// Independent implementation so each installed hook forwards its own original.
- (BOOL)enableChunkRequest {self.decisions++;return self.nativeChunk;}
@end

@interface TestJSON : NSObject
@property NSUInteger calls;
@property (strong) NSError *error;
@property (strong) id output;
- (id)response:(id)response json:(id)json error:(id)transport resultError:(NSError *__autoreleasing *)error;
@end
@implementation TestJSON
- (id)response:(id)response json:(id)json error:(id)transport resultError:(NSError *__autoreleasing *)error {
    (void)response;(void)json;(void)transport;self.calls++;
    if (error) *error=self.error;
    return self.output;
}
@end

@interface TestBackground : NSObject
@property NSUInteger calls;
@property NSInteger state;
@property BOOL allowed;
- (BOOL)localSwitch;
- (NSInteger)localState;
- (BOOL)decision;
- (void)enter;
@end
@implementation TestBackground
- (BOOL)localSwitch { self.calls++; return self.allowed; }
- (NSInteger)localState { self.calls++; return self.state; }
- (BOOL)decision { self.calls++; return self.allowed; }
- (void)enter { self.calls++; }
@end
@interface TestCyclicError : NSError
@property (strong) NSError *next;
@end
@implementation TestCyclicError
- (NSDictionary *)userInfo { return self.next ? @{NSUnderlyingErrorKey:self.next} : @{}; }
@end

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
        NSAttributedString *bareCollectionTitle=[[NSAttributedString alloc] initWithString:@"满意"];
        check(DGTranslateCollectionAttributed(bareCollectionTitle)==bareCollectionTitle,@"a bare collection title matching a survey word is preserved by the header getter");
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
        NSMutableDictionary *mutableSurvey=[@{@"options":[NSMutableArray arrayWithObject:[@{@"label":@"满意"} mutableCopy]]} mutableCopy];
        id mutableEnglish=DGTranslateSurvey(mutableSurvey);
        check([mutableEnglish isKindOfClass:NSMutableDictionary.class] && [mutableEnglish[@"options"] isKindOfClass:NSMutableArray.class] &&
              [mutableEnglish[@"options"][0] isKindOfClass:NSMutableDictionary.class] && [mutableSurvey[@"options"][0][@"label"] isEqual:@"满意"],@"mutable survey container contracts are preserved without mutating the source");
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
        __block BOOL background=YES;
        for (NSArray *op in @[@[@"localSwitch",@"backgroundSwitch"],@[@"localState",@"backgroundState"],
                              @[@"decision",@"observeBool0"],@[@"enter",@"observeVoid0"]]) {
            Method method=class_getInstanceMethod(TestBackground.class,NSSelectorFromString(op[0]));
            check(DGInstallHook(@{@"class":@"TestBackground",@"selector":op[0],@"operation":op[1],@"types":[NSString stringWithUTF8String:method_getTypeEncoding(method)]},^BOOL{return background;},recordNew),@"native audio preference/observer ABI installs");
        }
        TestBackground *bg=[TestBackground new];bg.state=2;bg.allowed=NO;
        check(bg.localSwitch && bg.calls==1 && !bg.allowed,@"audio ON overlays preference but calls original once without mutating it");
        check(bg.localState==1 && bg.calls==2 && bg.state==2,@"audio state overlay is NSInteger and does not overwrite stored state");
        check(!bg.decision && bg.calls==3,@"native eligibility denial remains false with background preference ON");
        [bg enter];check(bg.calls==4,@"background lifecycle observer forwards once");
        background=NO;before=[newEvents copy];
        check(!bg.localSwitch && bg.localState==2 && !bg.decision,@"audio OFF restores original preference and player decision");
        [bg enter];check(bg.calls==8 && [newEvents isEqual:before],@"audio OFF keeps native lifecycle without collecting events");
        bg.state=NSIntegerMin;check(bg.localState==NSIntegerMin,@"OFF preserves full signed native state");
        localize=YES;
        NSError *under=[NSError errorWithDomain:NSURLErrorDomain code:-1001 userInfo:@{NSLocalizedDescriptionKey:@"PRIVATE-description"}];
        NSError *outer=[NSError errorWithDomain:@"BDWebImageErrorDomain" code:900014 userInfo:@{NSUnderlyingErrorKey:under,@"PRIVATE-key":@"PRIVATE-value"}];
        [imageFeed failed:outer];
        check(imageFeed.arguments[0]==outer && [newEvents[@"TestImageFeed failed: error BDImage 900014"] unsignedIntegerValue]==1 &&
              [newEvents[@"TestImageFeed failed: underlying 1 error URL -1001"] unsignedIntegerValue]==1,@"image domain and underlying URL are distinguished without changing native error/retry");
        NSError *unknownDomainError=[NSError errorWithDomain:@"PRIVATE-domain" code:-1001 userInfo:nil];[imageFeed failed:unknownDomainError];
        check([newEvents[@"TestImageFeed failed: error App -1001"] unsignedIntegerValue]==1 &&
              [newEvents.description rangeOfString:@"PRIVATE"].location==NSNotFound,@"unknown-domain code is not mislabeled as URL and private fields never enter diagnostics");
        TestCyclicError *cycle=[[TestCyclicError alloc] initWithDomain:@"kAWEDCFeedErrorDomain" code:-4 userInfo:nil];cycle.next=cycle;
        [imageFeed failed:cycle];cycle.next=nil;
        check([newEvents[@"TestImageFeed failed: underlying error cycle"] unsignedIntegerValue]==1,@"NSError cycle ends without recursion");
        NSError *chain=under;for (NSUInteger i=0;i<6;i++) chain=[NSError errorWithDomain:@"BDWebImageErrorDomain" code:1 userInfo:@{NSUnderlyingErrorKey:chain}];
        [imageFeed failed:chain];check([newEvents[@"TestImageFeed failed: underlying error depth capped"] unsignedIntegerValue]==1,@"underlying-error walk is bounded");
        NSURL *searchURL=DGPublicProfileSearchURL(@"  刘德华 & name=other  ");
        NSURLComponents *searchComponents=[NSURLComponents componentsWithURL:searchURL resolvingAgainstBaseURL:NO];
        check([searchComponents.host isEqualToString:@"www.bing.com"] && searchComponents.queryItems.count==1 &&
            [searchComponents.queryItems[0].value isEqualToString:@"site:douyin.com/user/ 刘德华 & name=other"],@"public search keeps Unicode and reserved characters in one encoded query");
        check(!DGPublicProfileSearchURL(@" \n") && !DGPublicProfileSearchURL(@"name\nother") &&
            !DGPublicProfileSearchURL([@"x" stringByPaddingToLength:121 withString:@"x" startingAtIndex:0]),@"public search rejects empty, control and oversized input");
        check([DGPublicProfileURL(@"https://douyin.com/user/MS4wAb_-12?tracking=private").absoluteString isEqualToString:@"https://www.douyin.com/user/MS4wAb_-12"],@"official profile link is canonicalized without tracking query");
        for (NSString *link in @[@"http://douyin.com/user/id",@"https://douyin.com.evil.test/user/id",@"https://douyin.com@evil.test/user/id",@"https://u:p@douyin.com/user/id",@"https://douyin.com:443/user/id",@"https://douyin.com/user/%2fid",@"https://douyin.com/user/../id",@"https://douyin.com/video/123",@"javascript:alert(1)",@"https://douyin.com/user/id#fragment"])
            check(!DGPublicProfileURL(link),@"profile links reject untrusted hosts, credentials, schemes and paths");
        Method jsonMethod=class_getInstanceMethod(TestJSON.class,@selector(response:json:error:resultError:));
        __block BOOL observeJSON=YES;
        check(DGInstallHook(@{@"class":@"TestJSON",@"selector":@"response:json:error:resultError:",@"operation":@"observeJSONResponse4",@"types":[NSString stringWithUTF8String:method_getTypeEncoding(jsonMethod)]},^BOOL{return observeJSON;},recordNew),@"JSON pointer ABI observer installs");
        TestJSON *serializer=[TestJSON new];serializer.output=@"output";
        serializer.error=[NSError errorWithDomain:@"com.aweme.network.error" code:-11001 userInfo:@{NSLocalizedDescriptionKey:@"PRIVATE-html-payload"}];
        NSHTTPURLResponse *http=[[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"https://private.invalid/?cookie=PRIVATE"] statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:@{@"Content-Type":@"text/html"}];
        NSError *resultError=nil;
        id jsonResult=[serializer response:http json:@"PRIVATE-html" error:nil resultError:&resultError];
        check(jsonResult==serializer.output && resultError==serializer.error && serializer.calls==1,@"JSON observer preserves output and NSError pointer and forwards once");
        check([newEvents[@"JSON response error AwemeNetwork -11001"] unsignedIntegerValue]==1 &&
            [newEvents[@"JSON response HTTP 200"] unsignedIntegerValue]==1 && [newEvents[@"JSON response content type html"] unsignedIntegerValue]==1 &&
            [newEvents.description rangeOfString:@"PRIVATE"].location==NSNotFound,@"JSON classification reveals shape and HTTP status without body, URL, headers or secrets");
        before=[newEvents copy];[serializer response:nil json:nil error:nil resultError:NULL];
        check(serializer.calls==2 && [newEvents isEqual:before],@"nullable result-error pointer is forwarded safely");
        observeJSON=NO;[serializer response:http json:@{} error:nil resultError:&resultError];
        check(serializer.calls==3 && resultError==serializer.error && [newEvents isEqual:before],@"JSON observation OFF preserves native failure without collecting events");
        observeJSON=YES;
        TTHttpResponse *tt=[TTHttpResponse new];tt.statusCode=200;tt.MIMEType=@"application/json; charset=utf-8";
        NSData *valid=[@"{\"status_code\":2483,\"private\":\"PRIVATE\"}" dataUsingEncoding:NSUTF8StringEncoding];
        jsonResult=[serializer response:tt json:valid error:nil resultError:&resultError];
        check(jsonResult==serializer.output && resultError==serializer.error && serializer.calls==4 &&
            [newEvents[@"JSON strict decode dictionary"] unsignedIntegerValue]==1 &&
            [newEvents[@"JSON response content type json"] unsignedIntegerValue]==1,
            @"TT response ABI reads MIME/status and bounded JSON probe never converts failure into success");
        [serializer response:tt json:[@"[1,2]" dataUsingEncoding:NSUTF8StringEncoding] error:nil resultError:&resultError];
        [serializer response:tt json:[@"{\"partial\":" dataUsingEncoding:NSUTF8StringEncoding] error:nil resultError:&resultError];
        unsigned char gzip[]={0x1f,0x8b};
        [serializer response:tt json:[NSData dataWithBytes:gzip length:2] error:under resultError:&resultError];
        check([newEvents[@"JSON strict decode array"] unsignedIntegerValue]==1 &&
            [newEvents[@"JSON strict decode invalid"] unsignedIntegerValue]==2 &&
            [newEvents[@"JSON data prefix gzip"] unsignedIntegerValue]==1 &&
            [newEvents[@"JSON transport error URL -1001"] unsignedIntegerValue]==1,
            @"array, incomplete JSON and gzip remain original errors with fixed classifications");
        before=[newEvents copy];
        [serializer response:tt json:[NSMutableData dataWithLength:2097153] error:nil resultError:&resultError];
        check([newEvents[@"JSON data size over 2MiB"] unsignedIntegerValue]==1 &&
            [newEvents[@"JSON strict decode invalid"] isEqual:before[@"JSON strict decode invalid"]],
            @"oversized response is not reparsed");
        [serializer response:tt json:NSData.data error:nil resultError:&resultError];
        tt.statusCode=403;tt.MIMEType=@"PRIVATE-mime";
        [serializer response:tt json:[@"<html>PRIVATE</html>" dataUsingEncoding:NSUTF8StringEncoding] error:nil resultError:&resultError];
        check([newEvents[@"JSON response HTTP 403"] unsignedIntegerValue]==1 &&
            [newEvents[@"JSON response content type other"] unsignedIntegerValue]>=1 &&
            [newEvents[@"JSON data prefix markup"] unsignedIntegerValue]==1 &&
            [newEvents.description rangeOfString:@"PRIVATE"].location==NSNotFound,
            @"empty, HTML, server HTTP failure and unknown MIME never expose response content");

        __block BOOL compatibility=YES;
        Method transportMethod=class_getInstanceMethod(TestFeedManager.class,@selector(shouldRequestWithChunk));
        check(DGInstallHook(@{@"class":@"TestFeedManager",@"selector":@"shouldRequestWithChunk",@"operation":@"preferStandardFeed",@"types":[NSString stringWithUTF8String:method_getTypeEncoding(transportMethod)]},^BOOL{return compatibility;},recordNew),@"native standard transport decision installs with checked BOOL ABI");
        TestFeedManager *manager=[TestFeedManager new];manager.nativeChunk=YES;
        check(manager.shouldRequestWithChunk && manager.decisions==1,@"missing standard controller retains original transport");
        manager.dataController=[NSObject new];
        check(manager.shouldRequestWithChunk && manager.decisions==2,@"unverified standard controller retains original transport");
        AWEDCFeedDefaultDataControllerWrapper *standard=[AWEDCFeedDefaultDataControllerWrapper new];manager.dataController=standard;
        check(manager.shouldRequestWithChunk && manager.decisions==3,@"wrapper without underlying standard controller retains native transport");
        standard.dataController=[AWEDCFeedDefaultDataController new];
        check(!manager.shouldRequestWithChunk && manager.decisions==4,@"compatible native controller selects standard path and evaluates original once");
        manager.nativeChunk=NO;check(!manager.shouldRequestWithChunk && manager.decisions==5,@"original standard mode remains standard");
        compatibility=NO;manager.nativeChunk=YES;check(manager.shouldRequestWithChunk && manager.decisions==6,@"OFF restores original chunk decision");
        compatibility=YES;
        NSDictionary *params=@{@"cursor":@45,@"PRIVATE-auth":@"PRIVATE"};id args=@{@"reason":@2};
        standard.result=@{@"has_more":@NO,@"cursor":@67,@"items":@[@"video"]};
        __block NSUInteger completions=0;
        for (NSString *methodName in @[@"fetchDataWithRequestParams:args:completion:",@"refreshDataWithRequestParams:args:completion:",@"loadMoreDataWithRequestParams:args:completion:"]) {
            check(!manager.shouldRequestWithChunk,@"initial, refresh and load more can select native standard branch");
            SEL methodSelector=NSSelectorFromString(methodName);
            void (^completion)(id,NSError *)=^(id result,NSError *error){completions++;check(result==standard.result && error==standard.error,@"standard completion preserves model and failure identity");};
            ((void (*)(id,SEL,id,id,id))[standard methodForSelector:methodSelector])(standard,methodSelector,params,args,completion);
            check(standard.parameters==params && standard.arguments==args,@"cursor, credentials and request args stay untouched");
            standard.error=[NSError errorWithDomain:@"com.bytedance.AwemeError" code:2483 userInfo:nil];
        }
        check(completions==3 && standard.calls==3 && [standard.result[@"has_more"] isEqual:@NO] &&
            [standard.result[@"cursor"] isEqual:@67] && [newEvents.description rangeOfString:@"PRIVATE"].location==NSNotFound,
            @"transport selection does not duplicate requests, fabricate pagination or clear server restriction");

        for (Class cls in @[AWEFeedDoubleColumnListDataController.class,AWESearchCachalotDCFeedDataController.class]) {
            Method decision=class_getInstanceMethod(cls,@selector(enableChunkRequest));
            check(DGInstallHook(@{@"class":NSStringFromClass(cls),@"selector":@"enableChunkRequest",@"operation":@"standardFeedFormat",
                @"types":[NSString stringWithUTF8String:method_getTypeEncoding(decision)]},^BOOL{return compatibility;},recordNew),
                @"direct controller format decision installs with checked BOOL ABI");
            AWEFeedDoubleColumnListDataController *direct=[cls new];direct.nativeChunk=YES;
            manager.dataController=direct;manager.nativeChunk=YES;
            check(!manager.shouldRequestWithChunk,@"manager recognizes verified direct controller normal path");
            check(!direct.enableChunkRequest && direct.decisions==1,@"normal format decision calls original once");
            direct.result=standard.result;direct.error=standard.error;
            for (NSString *methodName in @[@"fetchDataWithRequestParams:args:completion:",@"refreshDataWithRequestParams:args:completion:",@"loadMoreDataWithRequestParams:args:completion:"]) {
                SEL requestSelector=NSSelectorFromString(methodName);
                void (^completion)(id,NSError *)=^(id result,NSError *error){
                    check(result==direct.result && error==direct.error,@"native response and restriction error are forwarded unchanged");
                };
                ((void (*)(id,SEL,id,id,id))[direct methodForSelector:requestSelector])(direct,requestSelector,params,args,completion);
                check(!direct.body[@"is_tidy"] && [direct.body isEqual:params] && !direct.selectedChunk,
                    @"initial, refresh and pagination agree on normal format without changing cursor or auth params");
            }
            check(direct.calls==3 && direct.decisions==7 && direct.parameters==params && direct.arguments==args,
                @"three requests forwarded once with original args and two native decision calls each");
            compatibility=NO;
            [direct fetchDataWithRequestParams:params args:args completion:nil];
            check([direct.body[@"is_tidy"] isEqual:@"true"] && direct.selectedChunk && manager.shouldRequestWithChunk,
                @"OFF restores native tidy negotiation and chunk loader together");
            compatibility=YES;direct.nativeChunk=NO;
            check(!direct.enableChunkRequest,@"native standard decision stays standard");
            direct.nativeChunk=YES;
            Method bodyMethod=class_getInstanceMethod(cls,@selector(addBodyParamsForChunkModel:));
            IMP bodyIMP=method_getImplementation(bodyMethod);
            // class_replaceMethod preserves an existing method's type encoding.
            // Add an incompatible override on a new subclass to model real drift.
            NSString *driftName=[@"TestDrift_" stringByAppendingString:NSStringFromClass(cls)];
            Class drift=objc_allocateClassPair(cls,driftName.UTF8String,0);
            check(drift && class_addMethod(drift,@selector(addBodyParamsForChunkModel:),bodyIMP,"v24@0:8q16"),
                @"fixture registers a genuinely incompatible body method ABI");
            objc_registerClassPair(drift);
            AWEFeedDoubleColumnListDataController *incompatible=[drift new];incompatible.nativeChunk=YES;
            manager.dataController=incompatible;
            check(incompatible.enableChunkRequest && manager.shouldRequestWithChunk,
                @"body ABI drift retains original controller format and manager transport");
        }
        serializer.error=[NSError errorWithDomain:@"CSP-Domain" code:-4 userInfo:@{@"PRIVATE-buffer":@"PRIVATE"}];
        [serializer response:tt json:nil error:nil resultError:&resultError];
        check(resultError==serializer.error && [newEvents[@"JSON response error CSP -4"] unsignedIntegerValue]==1 &&
            [newEvents.description rangeOfString:@"PRIVATE"].location==NSNotFound,
            @"CSP EOF error keeps native failure and never exports buffer details");
        check(!DGInstallHook(@{@"class":@"TestBackground",@"selector":@"localState",@"operation":@"standardFeedFormat",@"types":@"q16@0:8"},^BOOL{return YES;},recordNew),
            @"format operation rejects non-BOOL ABI");
        NSLog(@"PASS: policy and runtime-hook regressions");
    }
    return 0;
}
