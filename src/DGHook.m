#import "DGHook.h"
#import "DGPolicy.h"
#import <objc/runtime.h>
#import <dispatch/dispatch.h>
#include <string.h>

static NSObject *searchLock;
static NSMutableDictionary<NSString *, NSDictionary *> *searchHooks;
static NSMutableSet<NSString *> *searchFailures;

static void DGPrepareSearchRegistry(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        searchLock = [NSObject new]; searchHooks = [NSMutableDictionary new];
        searchFailures = [NSMutableSet new];
    });
}

NSDictionary *DGSearchAdapterSnapshot(void) {
    DGPrepareSearchRegistry();
    @synchronized (searchLock) {
        return @{@"installed":@0, @"active":@0, @"adapter_classes":@(searchHooks.count),
                 @"methods_per_adapter":@2, @"mode":@"observe original guest policy"};
    }
}

static void DGRecordResponseStatus(NSString *event,id response,DGRecord record) {
    Class base=NSClassFromString(@"AWEBaseApiModel");
    if (!base || ![response isKindOfClass:base]) return;
    SEL selector=NSSelectorFromString(@"statusCode");
    Method method=class_getInstanceMethod(object_getClass(response),selector);
    if (!method || strcmp(method_getTypeEncoding(method),"@16@0:8")) return;
    // AWEBaseApiModel statusCode is an object getter in this exact build.
    id value=((id (*)(id,SEL))method_getImplementation(method))(response,selector);
    if ([value isKindOfClass:NSNumber.class])
        record([NSString stringWithFormat:@"%@ response status code %lld",event,[value longLongValue]],1);
}

static NSString *DGErrorCategory(NSError *error) {
    NSString *domain = error.domain;
    if ([domain isEqualToString:NSURLErrorDomain]) return @"URL";
    if ([domain isEqualToString:NSPOSIXErrorDomain]) return @"POSIX";
    if ([domain isEqualToString:NSCocoaErrorDomain]) return @"Cocoa";
    if ([domain isEqualToString:@"kCFErrorDomainCFNetwork"]) return @"CFNetwork";
    // Fixed strings verified in build 406019. Unknown domains never leave the app.
    NSDictionary *known = @{@"BDWebImageErrorDomain":@"BDImage",
        @"BDWebImageHeifDecoderErrorDomain":@"BDHeif", @"BDWebImageVvicDecoderErrorDomain":@"BDVvic",
        @"kTTNetworkErrorDomain":@"TTNetwork", @"kAWEDCFeedErrorDomain":@"DCFeed",
        @"AWEDataLayerNetworkErrorDomain":@"DataNetwork", @"AWEDataLayerBaseErrorDomain":@"DataLayer",
        @"kAWEDCFeedAISearchSecurityErrorDomain":@"DCSearchSecurity", @"AWEDCFeedAISearchErrorDomain":@"DCSearch"};
    return known[domain] ?: @"App";
}

static void DGRecordError(NSString *event, NSError *error, DGRecord record) {
    NSMutableArray<NSError *> *visited = [NSMutableArray arrayWithObject:error];
    NSError *current = error;
    for (NSUInteger depth=0; depth<4; ++depth) {
        NSString *part = depth ? [NSString stringWithFormat:@" underlying %lu",(unsigned long)depth] : @"";
        record([NSString stringWithFormat:@"%@%@ error %@ %ld",event,part,DGErrorCategory(current),(long)current.code],1);
        // Inspect only the standard underlying-error slot; never serialize userInfo.
        id next = current.userInfo[NSUnderlyingErrorKey];
        if (![next isKindOfClass:NSError.class]) break;
        if ([visited indexOfObjectIdenticalTo:next] != NSNotFound) {
            record([event stringByAppendingString:@" underlying error cycle"],1); break;
        }
        if (depth==3) { record([event stringByAppendingString:@" underlying error depth capped"],1); break; }
        [visited addObject:next]; current = next;
    }
}

static void DGRecordFeedCompletion(NSString *event, id result, id error, DGRecord record) {
    record([event stringByAppendingString:@" callbacks"], 1);
    DGRecordResponseStatus(event,result,record);
    if (!error) {
        record([event stringByAppendingString:@" success"], 1);
        if ([result isKindOfClass:NSArray.class]) record([event stringByAppendingString:@" direct-array items"], [result count]);
        return;
    }
    if (![error isKindOfClass:NSError.class]) {
        record([event stringByAppendingString:@" non-NSError failure"], 1); return;
    }
    DGRecordError(event,error,record);
}

static void DGRecordFeedList(NSString *event, id items, NSUInteger removed, DGRecord record) {
    record([event stringByAppendingString:@" accesses"], 1);
    if (![items isKindOfClass:NSArray.class]) { record([event stringByAppendingString:@" non-array input"], 1); return; }
    NSUInteger count = [items count];
    record([event stringByAppendingString:@" input item samples"], count);
    if (!count) record([event stringByAppendingString:@" empty input"], 1);
    if (count && removed == count) record([event stringByAppendingString:@" all items filtered"], 1);
}

static BOOL DGOperationMatchesMethod(NSString *kind, Method method) {
    NSString *returnType;
    NSArray<NSString *> *arguments;
    NSString *boolean = [NSString stringWithUTF8String:@encode(BOOL)];
    if ([kind isEqualToString:@"false0"] || [kind isEqualToString:@"true0"] ||
        [kind isEqualToString:@"backgroundSwitch"] || [kind isEqualToString:@"observeBool0"]) {
        returnType = boolean; arguments = @[@"@", @":"];
    } else if ([kind isEqualToString:@"backgroundState"]) {
        returnType = @"q"; arguments = @[@"@", @":"];
    } else if ([kind isEqualToString:@"falseObject1"]) {
        returnType = boolean; arguments = @[@"@", @":", @"@"];
    } else if ([kind isEqualToString:@"falseObject2"]) {
        returnType = boolean; arguments = @[@"@", @":", @"@", @"@"];
    } else if ([kind isEqualToString:@"falseBool1"]) {
        returnType = boolean; arguments = @[@"@", @":", boolean];
    } else if ([kind isEqualToString:@"falseBool2"]) {
        returnType = boolean; arguments = @[@"@", @":", boolean, boolean];
    } else if ([kind isEqualToString:@"noop0"] || [kind isEqualToString:@"observeVoid0"]) {
        returnType = @"v"; arguments = @[@"@", @":"];
    } else if ([kind isEqualToString:@"filterGetter"]) {
        returnType = @"@"; arguments = @[@"@", @":"];
    } else if ([kind isEqualToString:@"filterSetter"]) {
        returnType = @"v"; arguments = @[@"@", @":", @"@"];
    } else if ([kind isEqualToString:@"observeFeedCompletion2"]) {
        returnType = @"v"; arguments = @[@"@", @":", @"@", @"@"];
    } else if ([kind isEqualToString:@"observeFeedCompletion2Bool"]) {
        returnType = @"v"; arguments = @[@"@", @":", @"@", @"@", boolean];
    } else if ([kind isEqualToString:@"observeSearchAdapter"]) {
        returnType = @"#"; arguments = @[@"@", @":"];
    } else if ([kind isEqualToString:@"translateGetter"] || [kind isEqualToString:@"translateRichGetter"] ||
               [kind isEqualToString:@"translateSurveyGetter"] || [kind isEqualToString:@"observeListGetter"]) {
        returnType = @"@"; arguments = @[@"@", @":"];
    } else if ([kind isEqualToString:@"translateConfig1"] || [kind isEqualToString:@"observeError1"]) {
        returnType = @"v"; arguments = @[@"@", @":", @"@"];
    } else if ([kind isEqualToString:@"observeFeedRequest"]) {
        returnType = @"v"; arguments = @[@"@", @":", @"Q", @"@", @"@"];
    } else if ([kind isEqualToString:@"observeImageFinish"]) {
        returnType = @"v"; arguments = @[@"@", @":", @"@", @"@", @"@", @"@", @"q"];
    } else if ([kind isEqualToString:@"observeSearchStatus"]) {
        returnType = boolean; arguments = @[@"@", @":", @"@", @"@"];
    } else return NO;
    char type[64] = {0};
    method_getReturnType(method, type, sizeof(type));
    if (strcmp(type, returnType.UTF8String) || method_getNumberOfArguments(method) != arguments.count) return NO;
    for (NSUInteger i = 0; i < arguments.count; ++i) {
        memset(type, 0, sizeof(type)); method_getArgumentType(method, (unsigned)i, type, sizeof(type));
        if (strcmp(type, arguments[i].UTF8String)) return NO;
    }
    return YES;
}

static void DGObserveSearchAdapter(Class adapter, DGRecord record) {
    if (!adapter) { record(@"Search gateway returned nil",1); return; }
    if (!class_isMetaClass(object_getClass(adapter))) { record(@"Search gateway returned non-class",1); return; }
    DGPrepareSearchRegistry();
    @synchronized (searchLock) {
        NSString *name = NSStringFromClass(adapter);
        NSArray *selectors = @[@"enableGuestSearch", @"hasRemainingGuestSearchCount"];
        if (searchHooks[name] || [searchFailures containsObject:name]) return;
        for (NSString *selector in selectors) {
            Method method = class_getClassMethod(adapter, NSSelectorFromString(selector));
            if (!method || strcmp(method_getTypeEncoding(method), "B16@0:8") || !DGOperationMatchesMethod(@"true0", method)) {
                if (![searchFailures containsObject:name]) {
                    [searchFailures addObject:name]; record(@"Search adapter unavailable or incompatible", 1);
                }
                return;
            }
        }
        searchHooks[name] = @{@"compatible":@YES};
        record(@"Search compatible adapter observed",1);
    }
}

static BOOL DGInstallHookInternal(NSDictionary *spec, DGEnabled enabled, DGRecord record,
                                 NSDictionary<NSString *,NSString *> *words) {
    if (![spec isKindOfClass:NSDictionary.class] || !enabled || !record) return NO;
    NSString *name = spec[@"class"], *selectorName = spec[@"selector"];
    NSString *kind = spec[@"operation"], *types = spec[@"types"];
    for (id value in @[name ?: NSNull.null, selectorName ?: NSNull.null, kind ?: NSNull.null, types ?: NSNull.null])
        if (![value isKindOfClass:NSString.class] || ![value length]) return NO;
    id methodKind = spec[@"class_method"];
    if (methodKind && ![methodKind isKindOfClass:NSNumber.class]) return NO;
    Class cls = NSClassFromString(name);
    if (!cls) return NO;
    if ([spec[@"class_method"] boolValue]) cls = object_getClass(cls);
    SEL sel = NSSelectorFromString(selectorName);
    Method method = class_getInstanceMethod(cls, sel);
    if (!method || strcmp(method_getTypeEncoding(method), types.UTF8String) != 0 || !DGOperationMatchesMethod(kind, method)) {
        record([NSString stringWithFormat:@"Signature mismatch: %@ %@", name, selectorName], 1);
        return NO;
    }
    IMP original = method_getImplementation(method);
    id block = nil;
    NSString *event = [NSString stringWithFormat:@"%@ %@", name, selectorName];
    if ([kind isEqualToString:@"backgroundSwitch"] || [kind isEqualToString:@"observeBool0"]) {
        block = ^BOOL(id self) {
            BOOL value = ((BOOL (*)(id,SEL))original)(self,sel);
            if (!enabled()) return value;
            record([event stringByAppendingString:(value ? @" original YES" : @" original NO")],1);
            if ([kind isEqualToString:@"backgroundSwitch"]) { record([event stringByAppendingString:@" preference ON"],1); return YES; }
            return value;
        };
    } else if ([kind isEqualToString:@"backgroundState"]) {
        block = ^NSInteger(id self) {
            NSInteger value = ((NSInteger (*)(id,SEL))original)(self,sel);
            if (!enabled()) return value;
            record([event stringByAppendingString:@" preference ON"],1);
            // State 1 = audio on / all scenes in the native preference store.
            // Content eligibility, interruption and player decisions stay native.
            return 1;
        };
    } else if ([kind isEqualToString:@"observeVoid0"]) {
        block = ^(id self) {
            ((void (*)(id,SEL))original)(self,sel);
            if (enabled()) record([event stringByAppendingString:@" calls"],1);
        };
    } else if ([kind isEqualToString:@"false0"] || [kind isEqualToString:@"true0"]) {
        BOOL value = [kind isEqualToString:@"true0"];
        block = ^BOOL(id self) {
            if (!enabled()) return ((BOOL (*)(id, SEL))original)(self, sel);
            record(event, 1); return value;
        };
    } else if ([kind isEqualToString:@"falseObject1"]) {
        block = ^BOOL(id self, id arg) {
            if (!enabled()) return ((BOOL (*)(id, SEL, id))original)(self, sel, arg);
            record(event, 1); return NO;
        };
    } else if ([kind isEqualToString:@"falseObject2"]) {
        block = ^BOOL(id self, id a, id b) {
            if (!enabled()) return ((BOOL (*)(id, SEL, id, id))original)(self, sel, a, b);
            record(event, 1); return NO;
        };
    } else if ([kind isEqualToString:@"falseBool1"]) {
        block = ^BOOL(id self, BOOL arg) {
            if (!enabled()) return ((BOOL (*)(id, SEL, BOOL))original)(self, sel, arg);
            record(event, 1); return NO;
        };
    } else if ([kind isEqualToString:@"falseBool2"]) {
        block = ^BOOL(id self, BOOL a, BOOL b) {
            if (!enabled()) return ((BOOL (*)(id, SEL, BOOL, BOOL))original)(self, sel, a, b);
            record(event, 1); return NO;
        };
    } else if ([kind isEqualToString:@"noop0"]) {
        block = ^(id self) {
            if (!enabled()) ((void (*)(id, SEL))original)(self, sel);
            else record(event, 1);
        };
    } else if ([kind isEqualToString:@"filterGetter"]) {
        block = ^id(id self) {
            id items = ((id (*)(id, SEL))original)(self, sel);
            NSUInteger removed = 0;
            id filtered = enabled() ? DGFilterAds(items, &removed) : items;
            DGRecordFeedList(event, items, removed, record);
            if (removed) record(@"Feed ad items removed", removed);
            return filtered;
        };
    } else if ([kind isEqualToString:@"filterSetter"]) {
        block = ^(id self, id items) {
            NSUInteger removed = 0;
            id filtered = enabled() ? DGFilterAds(items, &removed) : items;
            DGRecordFeedList(event, items, removed, record);
            if (removed) record(@"Feed ad items removed", removed);
            ((void (*)(id, SEL, id))original)(self, sel, filtered);
        };
    } else if ([kind isEqualToString:@"observeFeedCompletion2"]) {
        block = ^(id self, id result, id error) {
            ((void (*)(id, SEL, id, id))original)(self, sel, result, error);
            if (enabled()) DGRecordFeedCompletion(event, result, error, record);
        };
    } else if ([kind isEqualToString:@"observeFeedCompletion2Bool"]) {
        block = ^(id self, id result, id error, BOOL flag) {
            ((void (*)(id, SEL, id, id, BOOL))original)(self, sel, result, error, flag);
            if (enabled()) DGRecordFeedCompletion(event, result, error, record);
        };
    } else if ([kind isEqualToString:@"observeSearchAdapter"]) {
        block = ^Class(id self) {
            Class adapter = ((Class (*)(id, SEL))original)(self, sel);
            if (enabled()) { record(@"Search gateway invocations",1); DGObserveSearchAdapter(adapter,record); }
            return adapter;
        };
    } else if ([kind isEqualToString:@"translateGetter"] || [kind isEqualToString:@"translateRichGetter"] ||
               [kind isEqualToString:@"translateSurveyGetter"]) {
        if (!words) return NO;
        block = ^id(id self) {
            id value = ((id (*)(id,SEL))original)(self,sel), translated = value;
            if (value && enabled()) {
                record([event stringByAppendingString:@" reads"],1);
                if ([kind isEqualToString:@"translateSurveyGetter"]) translated = DGTranslateSurvey(value);
                else if ([kind isEqualToString:@"translateRichGetter"] && [value isKindOfClass:NSAttributedString.class])
                    translated = DGTranslateCollectionAttributed(value);
                else if ([kind isEqualToString:@"translateGetter"] && [value isKindOfClass:NSString.class]) {
                    BOOL linked = NO;
                    if ([name isEqualToString:@"AWEUIKitViewControllerEmptyPageConfig"] && [selectorName isEqualToString:@"informativeText"]) {
                        SEL rangeSelector=NSSelectorFromString(@"linkRange");
                        Method rangeMethod=class_getInstanceMethod(object_getClass(self),rangeSelector);
                        if (rangeMethod && !strcmp(method_getTypeEncoding(rangeMethod),"{_NSRange=QQ}16@0:8")) {
                            NSRange range=((NSRange (*)(id,SEL))method_getImplementation(rangeMethod))(self,rangeSelector);
                            linked = range.length > 0;
                        }
                    }
                    // A separate linkRange is measured in source characters.
                    // Leave linked text intact rather than corrupt its action span.
                    if (!linked) translated = DGTranslateControl(value,words);
                }
                if (![translated isEqual:value]) record([event stringByAppendingString:@" translated"],1);
            }
            return translated;
        };
    } else if ([kind isEqualToString:@"translateConfig1"]) {
        if (!words) return NO;
        block = ^(id self,id config) {
            id translated = enabled() ? DGTranslateEvaluationConfig(config,words) : config;
            if (translated != config) record([event stringByAppendingString:@" translated"],1);
            ((void (*)(id,SEL,id))original)(self,sel,translated);
        };
    } else if ([kind isEqualToString:@"observeFeedRequest"]) {
        block = ^(id self,NSUInteger requestType,id response,id error) {
            ((void (*)(id,SEL,NSUInteger,id,id))original)(self,sel,requestType,response,error);
            if (enabled()) DGRecordFeedCompletion(event,response,error,record);
        };
    } else if ([kind isEqualToString:@"observeError1"]) {
        block = ^(id self,id error) {
            ((void (*)(id,SEL,id))original)(self,sel,error);
            if (enabled()) {
                if (error) DGRecordFeedCompletion(event,nil,error,record);
                else record([event stringByAppendingString:@" failure without error"],1);
            }
        };
    } else if ([kind isEqualToString:@"observeImageFinish"]) {
        block = ^(id self,id image,id data,id path,id url,NSInteger source) {
            ((void (*)(id,SEL,id,id,id,id,NSInteger))original)(self,sel,image,data,path,url,source);
            if (enabled()) { record(@"Image SDK finish callbacks",1); record(image ? @"Image SDK finish with image" : @"Image SDK finish without image",1); }
        };
    } else if ([kind isEqualToString:@"observeListGetter"]) {
        block = ^id(id self) {
            id result = ((id (*)(id,SEL))original)(self,sel);
            if (enabled()) { DGRecordFeedList(event,result,0,record); DGRecordResponseStatus(event,self,record); }
            return result;
        };
    } else if ([kind isEqualToString:@"observeSearchStatus"]) {
        block = ^BOOL(id self, id code, id message) {
            BOOL result = ((BOOL (*)(id, SEL, id, id))original)(self, sel, code, message);
            if (enabled()) {
                record(@"Search status checks", 1);
                if (result) record(@"Search status limit reported", 1);
                if ([code isKindOfClass:NSNumber.class])
                    record([NSString stringWithFormat:@"Search status code %lld", [code longLongValue]], 1);
            }
            return result; // Keep server/app status and all state changes intact.
        };
    } else return NO;
    IMP replacement = imp_implementationWithBlock(block);
    // Add a local override when the selector is inherited. Do not mutate its superclass.
    if (!class_addMethod(cls, sel, replacement, method_getTypeEncoding(method))) {
        class_replaceMethod(cls, sel, replacement, method_getTypeEncoding(method));
    }
    record([@"Installed: " stringByAppendingString:event], 1);
    return YES;
}

BOOL DGInstallHook(NSDictionary *spec, DGEnabled enabled, DGRecord record) {
    return DGInstallHookInternal(spec,enabled,record,nil);
}

BOOL DGInstallLocalizedHook(NSDictionary *spec, DGEnabled enabled, DGRecord record,
                            NSDictionary<NSString *,NSString *> *translations) {
    return DGInstallHookInternal(spec,enabled,record,translations);
}
