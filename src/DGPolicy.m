#import "DGPolicy.h"
#import <objc/runtime.h>
#import <dispatch/dispatch.h>
#include <string.h>

NSURL *DGPublicProfileSearchURL(NSString *name) {
    if (![name isKindOfClass:NSString.class]) return nil;
    NSString *query=[name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (!query.length || query.length>120 || [query rangeOfCharacterFromSet:NSCharacterSet.controlCharacterSet].location!=NSNotFound) return nil;
    NSURLComponents *url=[NSURLComponents new];url.scheme=@"https";url.host=@"www.bing.com";url.path=@"/search";
    url.queryItems=@[[NSURLQueryItem queryItemWithName:@"q" value:[@"site:douyin.com/user/ " stringByAppendingString:query]]];
    return url.URL;
}

NSURL *DGPublicProfileURL(NSString *input) {
    if (![input isKindOfClass:NSString.class] || input.length>2048) return nil;
    NSString *value=[input stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSURLComponents *url=[NSURLComponents componentsWithString:value];
    if (![url.scheme.lowercaseString isEqualToString:@"https"] ||
        ![@[@"douyin.com",@"www.douyin.com"] containsObject:url.host.lowercaseString] ||
        url.user || url.password || url.port || url.fragment) return nil;
    NSString *path=url.percentEncodedPath;
    NSRegularExpression *pattern=[NSRegularExpression regularExpressionWithPattern:@"^/user/[A-Za-z0-9_-]{1,256}/?$" options:0 error:NULL];
    if ([pattern numberOfMatchesInString:path options:0 range:NSMakeRange(0,path.length)]!=1) return nil;
    url.host=@"www.douyin.com";url.scheme=@"https";url.query=nil;
    return url.URL;
}

static NSRange DGCollectionPrefix(NSString *text) {
    for (NSString *prefix in @[@"观看完整合集：", @"观看完整合集:", @"合集 · "]) {
        if ([text hasPrefix:prefix] && text.length > prefix.length)
            return NSMakeRange(0, prefix.length);
    }
    return NSMakeRange(NSNotFound, 0);
}

NSString *DGTranslateControl(NSString *text, NSDictionary<NSString *, NSString *> *translations) {
    NSString *exact = DGTranslate(text, translations);
    if (![exact isEqualToString:text]) return exact;
    NSRange prefix = DGCollectionPrefix(text);
    if (prefix.location != NSNotFound)
        return [@"Collection: " stringByAppendingString:[text substringFromIndex:prefix.length]];
    // Anchored UI templates preserve the displayed count (including 万/亿 units).
    static NSArray<NSRegularExpression *> *patterns;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSMutableArray *list = [NSMutableArray new];
        for (NSString *pattern in @[@"^评论[ \\t]*([0-9][0-9,.]*[万亿]?)$",
                                    @"^展开[ \\t]*([0-9][0-9,.]*[万亿]?)[ \\t]*条回复$"])
            [list addObject:[NSRegularExpression regularExpressionWithPattern:pattern options:0 error:NULL]];
        patterns = [list copy];
    });
    for (NSUInteger i = 0; i < patterns.count; ++i) {
        NSTextCheckingResult *match = [patterns[i] firstMatchInString:text options:0 range:NSMakeRange(0,text.length)];
        if (!match || match.range.length != text.length) continue;
        NSString *count = [text substringWithRange:[match rangeAtIndex:1]];
        if (i == 0) return [@"Comments " stringByAppendingString:count];
        return [NSString stringWithFormat:@"View %@ %@",count,[count isEqualToString:@"1"] ? @"reply" : @"replies"];
    }
    return text;
}

NSAttributedString *DGTranslateCollectionAttributed(NSAttributedString *text) {
    NSRange prefix = DGCollectionPrefix(text.string);
    if (prefix.location != NSNotFound) {
        // Replace only the UI prefix. Keep collection title, tappable spans and
        // all their attributes; no reconstruction of mixed user content.
        NSMutableAttributedString *result = [text mutableCopy];
        NSDictionary *style = [text attributesAtIndex:0 effectiveRange:NULL];
        [result replaceCharactersInRange:prefix withAttributedString:
            [[NSAttributedString alloc] initWithString:@"Collection: " attributes:style]];
        return result;
    }
    return text;
}

NSAttributedString *DGTranslateControlAttributed(NSAttributedString *text,
                                                 NSDictionary<NSString *, NSString *> *translations) {
    NSAttributedString *collection = DGTranslateCollectionAttributed(text);
    if (collection != text) return collection;
    NSString *value = DGTranslateControl(text.string, translations);
    return DGTranslateAttributed(text, @{text.string:value});
}

id DGTranslateEvaluationConfig(id config, NSDictionary<NSString *, NSString *> *translations) {
    if (![config isKindOfClass:NSDictionary.class]) return config;
    NSMutableDictionary *result = nil;
    // Keys proven in AWECommentEvaluationConfig configWithDict: disassembly.
    // bizParams, IDs, callbacks, arbitrary data and posted text are untouched.
    for (NSString *key in @[@"navigationTitle",@"titlePlaceholder",@"titleMinCountToast",@"titleMaxCountToast",
        @"ratingTitle",@"ratingPointDes",@"expandTitle",@"previewPostTitle",@"previewPostSubTitle",
        @"textSendButtonText",@"textPlaceholder",@"textEmptyToast"]) {
        id original = config[key];
        if (![original isKindOfClass:NSString.class]) continue;
        NSString *value;
        if ([key isEqualToString:@"ratingPointDes"] || [key isEqualToString:@"expandTitle"]) {
            NSMutableArray *parts = [NSMutableArray new];
            for (NSString *part in [original componentsSeparatedByString:@","])
                [parts addObject:DGTranslate(part,translations)];
            value = [parts componentsJoinedByString:@","];
        } else value = DGTranslate(original,translations);
        if (![value isEqualToString:original]) {
            if (!result) result = [config mutableCopy];
            result[key] = value;
        }
    }
    return result ? ([config isKindOfClass:NSMutableDictionary.class] ? result : [result copy]) : config;
}

static id DGSurveyNode(id node, NSUInteger depth, NSUInteger *budget, BOOL *valid) {
    if (depth > 12 || *budget == 0) { *valid = NO; return node; }
    --*budget;
    if ([node isKindOfClass:NSString.class]) {
        // Only known survey chrome, inside surveyDetail. Not a general translator.
        NSDictionary *words = @{@"非常不满意":@"Very unhappy",@"不满意":@"Unhappy",
            @"一般":@"Neutral",@"满意":@"Happy",@"非常满意":@"Very happy",
            @"你对该视频下的评论氛围是否满意?":@"How do you feel about these comments?",
            @"你对该视频下的评论氛围是否满意？":@"How do you feel about these comments?"};
        return words[node] ?: node;
    }
    if ([node isKindOfClass:NSArray.class]) {
        NSMutableArray *result = [NSMutableArray new]; BOOL changed = NO;
        for (id value in node) { id mapped = DGSurveyNode(value,depth+1,budget,valid); [result addObject:mapped]; changed |= mapped != value; if (!*valid) return node; }
        return changed ? ([node isKindOfClass:NSMutableArray.class] ? result : [result copy]) : node;
    }
    if ([node isKindOfClass:NSDictionary.class]) {
        NSMutableDictionary *result = nil;
        // Unknown schema branches and machine-readable values are not display
        // text. In particular option IDs/values, URLs and business parameters
        // must remain byte-for-byte original even if they resemble a rating.
        for (NSString *key in @[@"title",@"question",@"question_text",@"label",@"text",@"description",@"desc",
                                @"options",@"option_list",@"items",@"choices"]) {
            if (!node[key]) continue;
            id value = node[key], mapped = DGSurveyNode(value,depth+1,budget,valid);
            if (!*valid) return node;
            if (mapped != value) { if (!result) result = [node mutableCopy]; result[key] = mapped; }
        }
        return result ? ([node isKindOfClass:NSMutableDictionary.class] ? result : [result copy]) : node;
    }
    return node;
}

id DGTranslateSurvey(id payload) {
    BOOL jsonText = [payload isKindOfClass:NSString.class];
    id tree = payload;
    if (jsonText) {
        if ([payload length] > 65536) return payload;
        NSData *data = [payload dataUsingEncoding:NSUTF8StringEncoding];
        tree = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
        if (!tree) return payload;
    }
    NSUInteger budget = 2048; BOOL valid = YES;
    id result = DGSurveyNode(tree,0,&budget,&valid);
    if (!valid || result == tree) return payload;
    if (!jsonText) return result;
    NSData *data = [NSJSONSerialization dataWithJSONObject:result options:0 error:NULL];
    if (!data) return payload;
    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return [payload isKindOfClass:NSMutableString.class] ? [text mutableCopy] : text;
}

NSString *DGTranslate(NSString *text, NSDictionary<NSString *, NSString *> *translations) {
    // Only exact labels: never send text to a service or translate arbitrary captions.
    NSString *value = translations[text];
    if (value || !text.length) return value ?: text;
    // Several controls include padding spaces in their title. Preserve that
    // padding without matching substrings inside sentences or search queries.
    NSCharacterSet *padding = NSCharacterSet.whitespaceCharacterSet;
    NSUInteger start = 0, end = text.length;
    while (start < end && [padding characterIsMember:[text characterAtIndex:start]]) ++start;
    while (end > start && [padding characterIsMember:[text characterAtIndex:end-1]]) --end;
    if (!start && end == text.length) return text;
    value = translations[[text substringWithRange:NSMakeRange(start, end-start)]];
    if (!value) return text;
    return [NSString stringWithFormat:@"%@%@%@", [text substringToIndex:start], value, [text substringFromIndex:end]];
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
