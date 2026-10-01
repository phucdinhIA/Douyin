#import "DGHook.h"
#import "DGPolicy.h"
#import <objc/runtime.h>
#include <string.h>

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
    } else return NO;
    IMP replacement = imp_implementationWithBlock(block);
    // Add a local override when the selector is inherited. Do not mutate its superclass.
    if (!class_addMethod(cls, sel, replacement, method_getTypeEncoding(method))) {
        class_replaceMethod(cls, sel, replacement, method_getTypeEncoding(method));
    }
    record([@"Installed: " stringByAppendingString:event], 1);
    return YES;
}
