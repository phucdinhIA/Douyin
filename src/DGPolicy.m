#import "DGPolicy.h"
#import <objc/runtime.h>
#include <stdlib.h>
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

id DGFilterAds(id items, NSUInteger *removed) {
    if (removed) *removed = 0;
    if (![items isKindOfClass:NSArray.class]) return items;
    NSArray *input = items;
    NSMutableArray *output = nil;
    SEL selector = NSSelectorFromString(@"isAds");
    for (NSUInteger index = 0; index < input.count; ++index) {
        id model = input[index];
        Method method = class_getInstanceMethod(object_getClass(model), selector);
        BOOL ad = NO;
        if (method && method_getNumberOfArguments(method) == 2) {
            char *type = method_copyReturnType(method);
            if (type && strcmp(type, @encode(BOOL)) == 0) {
                BOOL (*readFlag)(id, SEL) = (void *)method_getImplementation(method);
                ad = readFlag(model, selector);
            }
            free(type);
        }
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
