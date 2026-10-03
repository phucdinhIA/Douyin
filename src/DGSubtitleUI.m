#import "DGSubtitleUI.h"
#include <math.h>
NSArray *DGSubtitlePages(NSString *text,CGFloat width,UIFont *font,NSUInteger lines) {
    if (!text.length || text.length>2000 || !isfinite(width) || width<40 || !font || !lines || lines>3) return @[];
    NSMutableParagraphStyle *style=[NSMutableParagraphStyle new];style.lineBreakMode=NSLineBreakByWordWrapping;
    NSTextStorage *storage=[[NSTextStorage alloc] initWithString:text attributes:@{NSFontAttributeName:font,NSParagraphStyleAttributeName:style}];
    NSLayoutManager *layout=[NSLayoutManager new];NSTextContainer *container=[[NSTextContainer alloc] initWithSize:CGSizeMake(width,CGFLOAT_MAX)];container.lineFragmentPadding=0;
    [layout addTextContainer:container];[storage addLayoutManager:layout];[layout ensureLayoutForTextContainer:container];
    NSMutableArray *pages=[NSMutableArray new];__block NSUInteger count=0,first=0;
    [layout enumerateLineFragmentsForGlyphRange:[layout glyphRangeForTextContainer:container] usingBlock:^(__unused CGRect rect,__unused CGRect used,__unused NSTextContainer *box,NSRange glyphs,__unused BOOL *stop) {
        count++;NSRange range=[layout characterRangeForGlyphRange:glyphs actualGlyphRange:NULL];
        if (count==lines) {NSUInteger last=NSMaxRange(range);[pages addObject:[text substringWithRange:NSMakeRange(first,last-first)]];first=last;count=0;}
    }];
    if (first<text.length) [pages addObject:[text substringFromIndex:first]];
    return pages;
}
NSString *DGSubtitlePageAt(NSArray<NSString *> *pages,double time,double start,double end) {
    if (!pages.count || !isfinite(time) || !isfinite(start) || !isfinite(end) || end<=start || time<start || time>=end) return nil;
    NSUInteger total=0;for (NSString *page in pages) total+=page.length;if (!total) return nil;
    double position=(time-start)/(end-start)*total;NSUInteger seen=0;
    for (NSString *page in pages) {seen+=page.length;if (position<seen) return [page stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];}
    return [pages.lastObject stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
}
@implementation DGSubtitleLabel
- (void)drawTextInRect:(CGRect)rect {[super drawTextInRect:UIEdgeInsetsInsetRect(rect,UIEdgeInsetsMake(7,12,7,12))];}
@end
