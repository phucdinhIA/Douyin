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
        NSUInteger active = 0;
        NSMutableSet *classes = [NSMutableSet new];
        for (NSDictionary *entry in searchHooks.allValues) {
            NSDictionary *spec = entry[@"spec"];
            Class cls = NSClassFromString(spec[@"class"]);
            [classes addObject:spec[@"class"]];
            Method method = class_getClassMethod(cls, NSSelectorFromString(spec[@"selector"]));
            if (method && method_getImplementation(method) == (IMP)[entry[@"imp"] pointerValue]) ++active;
        }
        return @{@"installed":@(searchHooks.count), @"active":@(active),
                 @"adapter_classes":@(classes.count), @"methods_per_adapter":@2};
    }
}

static void DGRecordFeedCompletion(NSString *event, id result, id error, DGRecord record) {
    record([event stringByAppendingString:@" callbacks"], 1);
    if (!error) {
        record([event stringByAppendingString:@" success"], 1);
        if ([result isKindOfClass:NSArray.class]) record([event stringByAppendingString:@" direct-array items"], [result count]);
        return;
    }
    if (![error isKindOfClass:NSError.class]) {
        record([event stringByAppendingString:@" non-NSError failure"], 1); return;
    }
    NSError *value = error;
    NSString *category = @"App";
    if ([value.domain isEqualToString:NSURLErrorDomain]) category = @"URL";
    else if ([value.domain isEqualToString:NSPOSIXErrorDomain]) category = @"POSIX";
    else if ([value.domain isEqualToString:NSCocoaErrorDomain]) category = @"Cocoa";
    else if ([value.domain isEqualToString:@"kCFErrorDomainCFNetwork"]) category = @"CFNetwork";
    // Numeric codes and a fixed category only: no description, URL, userInfo, or tokens.
    record([NSString stringWithFormat:@"%@ error %@ %ld", event, category, (long)value.code], 1);
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
    if ([kind isEqualToString:@"false0"] || [kind isEqualToString:@"true0"]) {
        returnType = boolean; arguments = @[@"@", @":"];
    } else if ([kind isEqualToString:@"falseObject1"]) {
        returnType = boolean; arguments = @[@"@", @":", @"@"];
    } else if ([kind isEqualToString:@"falseObject2"]) {
        returnType = boolean; arguments = @[@"@", @":", @"@", @"@"];
    } else if ([kind isEqualToString:@"falseBool1"]) {
        returnType = boolean; arguments = @[@"@", @":", boolean];
    } else if ([kind isEqualToString:@"falseBool2"]) {
        returnType = boolean; arguments = @[@"@", @":", boolean, boolean];
    } else if ([kind isEqualToString:@"noop0"]) {
        returnType = @"v"; arguments = @[@"@", @":"];
    } else if ([kind isEqualToString:@"filterGetter"]) {
        returnType = @"@"; arguments = @[@"@", @":"];
    } else if ([kind isEqualToString:@"filterSetter"]) {
        returnType = @"v"; arguments = @[@"@", @":", @"@"];
    } else if ([kind isEqualToString:@"observeFeedCompletion2"]) {
        returnType = @"v"; arguments = @[@"@", @":", @"@", @"@"];
    } else if ([kind isEqualToString:@"observeFeedCompletion2Bool"]) {
        returnType = @"v"; arguments = @[@"@", @":", @"@", @"@", boolean];
    } else if ([kind isEqualToString:@"guestSearchAdapter"]) {
        returnType = @"#"; arguments = @[@"@", @":"];
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

static void DGConfigureSearchAdapter(Class adapter, DGEnabled enabled, DGRecord record) {
    // Resolve the actual service through the app's own class getter. No invented
    // class or method is added if the guest-search API is missing or incompatible.
    if (!adapter || !class_isMetaClass(object_getClass(adapter))) return;
    DGPrepareSearchRegistry();
    @synchronized (searchLock) {
        NSString *name = NSStringFromClass(adapter);
        NSArray *selectors = @[@"enableGuestSearch", @"hasRemainingGuestSearchCount"];
        for (NSString *selector in selectors) {
            // Allow the app's normal lazy method resolution, but never install
            // a replacement for a selector implemented only by forwarding.
            [adapter respondsToSelector:NSSelectorFromString(selector)];
            Method method = class_getClassMethod(adapter, NSSelectorFromString(selector));
            if (!method || strcmp(method_getTypeEncoding(method), "B16@0:8") || !DGOperationMatchesMethod(@"true0", method)) {
                if (![searchFailures containsObject:name]) {
                    [searchFailures addObject:name]; record(@"Search adapter unavailable or incompatible", 1);
                }
                return; // Preflight both methods before changing either.
            }
        }
        for (NSString *selector in selectors) {
            NSString *key = [name stringByAppendingFormat:@"|%@", selector];
            if (searchHooks[key]) continue; // Never stack over a later replacement.
            NSDictionary *spec = @{@"class":name, @"selector":selector, @"class_method":@YES,
                                    @"types":@"B16@0:8", @"operation":@"true0"};
            if (DGInstallHook(spec, enabled, record)) {
                IMP imp = method_getImplementation(class_getClassMethod(adapter, NSSelectorFromString(selector)));
                searchHooks[key] = @{@"spec":spec, @"imp":[NSValue valueWithPointer:(const void *)imp]};
            }
        }
    }
}

BOOL DGInstallHook(NSDictionary *spec, DGEnabled enabled, DGRecord record) {
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
    if ([kind isEqualToString:@"false0"] || [kind isEqualToString:@"true0"]) {
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
    } else if ([kind isEqualToString:@"guestSearchAdapter"]) {
        block = ^Class(id self) {
            Class adapter = ((Class (*)(id, SEL))original)(self, sel);
            if (enabled()) DGConfigureSearchAdapter(adapter, enabled, record);
            return adapter;
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
