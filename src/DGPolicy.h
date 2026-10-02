#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
NSString *DGTranslate(NSString *text, NSDictionary<NSString *, NSString *> *translations);
// Call only for a verified presentation field/control, never a comment body.
NSString *DGTranslateControl(NSString *text, NSDictionary<NSString *, NSString *> *translations);
NSAttributedString *DGTranslateControlAttributed(NSAttributedString *text,
                                                 NSDictionary<NSString *, NSString *> *translations);
NSAttributedString *DGTranslateCollectionAttributed(NSAttributedString *text);
id DGTranslateEvaluationConfig(id config, NSDictionary<NSString *, NSString *> *translations);
id DGTranslateSurvey(id payload);
NSAttributedString *DGTranslateAttributed(NSAttributedString *text,
                                          NSDictionary<NSString *, NSString *> *translations);
id _Nullable DGFilterAds(id _Nullable items, NSUInteger * _Nullable removed);
BOOL DGIsAdModel(id model);
NS_ASSUME_NONNULL_END
