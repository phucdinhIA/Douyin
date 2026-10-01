#import "DGPolicy.h"
#import <objc/runtime.h>
#include <string.h>

NSString *DGTranslate(NSString *text, NSDictionary<NSString *, NSString *> *translations) {
    // Only exact labels: never send text to a service or translate arbitrary captions.
    return translations[text] ?: text;
}

NSAttributedString *DGTranslateAttributed(NSAttributedString *text,
                                         NSDictionary<NSString *, NSString *> *translations) {
    NSString *translated = DGTranslate(text.string, translations);
    if ([translated isEqualToString:text.string] || text.length == 0) return text;
    NSRange effective;
    NSDictionary *attributes = [text attributesAtIndex:0 effectiveRange:&effective];
    // Mixed styles can carry tappable mentions. Preserve those strings intact.
    if (effective.length != text.length) return text;
    return [[NSAttributedString alloc] initWithString:translated attributes:attributes];
}

static BOOL DGReadAdFlag(id model, NSString *name) {
    SEL selector = NSSelectorFromString(name);
    Method method = class_getInstanceMethod(object_getClass(model), selector);
    if (!method || method_getNumberOfArguments(method) != 2) return NO;
    char type[16] = {0};
    method_getReturnType(method, type, sizeof(type));
    if (strcmp(type, @encode(BOOL)) != 0) return NO;
    BOOL (*readFlag)(id, SEL) = (void *)method_getImplementation(method);
    return readFlag(model, selector);
}

BOOL DGIsAdModel(id model) {
    if (DGReadAdFlag(model, @"isAds")) return YES;
    Class aweme = NSClassFromString(@"AWEAwemeModel");
    // Additional flags were verified on this class in 40.6.0. Do not assume
    // similarly named methods on unrelated search/container models mean an ad.
    if (!aweme || ![model isKindOfClass:aweme]) return NO;
    return DGReadAdFlag(model, @"checkIsAd") || DGReadAdFlag(model, @"isHardAdModel") ||
           DGReadAdFlag(model, @"isHardAd");
}

id DGFilterAds(id items, NSUInteger *removed) {
    if (removed) *removed = 0;
    if (![items isKindOfClass:NSArray.class]) return items;
    NSArray *input = items;
    NSMutableArray *output = nil;
    for (NSUInteger index = 0; index < input.count; ++index) {
        id model = input[index];
        BOOL ad = DGIsAdModel(model);
        if (ad) {
            if (!output) {
                output = [NSMutableArray arrayWithCapacity:input.count];
                [output addObjectsFromArray:[input subarrayWithRange:NSMakeRange(0, index)]];
            }
            if (removed) ++*removed;
        } else if (output) {
            [output addObject:model];
        }
    }
    if (!output) return items;
    return [items isKindOfClass:NSMutableArray.class] ? output : [output copy];
}
