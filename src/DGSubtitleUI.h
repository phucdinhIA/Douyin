#import <UIKit/UIKit.h>
// Pagination is confined to the original cue interval; it never retimes ASR.
FOUNDATION_EXPORT NSArray<NSString *> *DGSubtitlePages(NSString *text,CGFloat width,UIFont *font,NSUInteger lines);
FOUNDATION_EXPORT NSString *DGSubtitlePageAt(NSArray<NSString *> *pages,double time,double start,double end);
@interface DGSubtitleLabel : UILabel
@end
