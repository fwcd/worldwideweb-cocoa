//
//  NSAttributedString+Attributes.m
//  WorldWideWeb
//
//  Created on 13.09.24
//

#import "Anchor.h"
#import "NSAttributedString+Attributes.h"

NSString *const AnchorAttributeName = @"WorldWideWeb.Anchor";

@implementation NSAttributedString (Attributes)

- (Anchor * _Nullable)anchor {
    // TODO: Can we be sure to always find an associated anchor (if existent) at the first index? Does attributeRuns already guaranteed that or should we document it as an invariant if not?
    return [self attribute:AnchorAttributeName atIndex:0 effectiveRange:nil];
}

- (NSParagraphStyle * _Nullable)paragraphStyle {
    // TODO: Can we be sure to always find an associated paragraph style at the first index?
    return [self attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:nil];
}

- (NSColor * _Nullable)color {
    return [self attribute:NSForegroundColorAttributeName atIndex:0 effectiveRange:nil];
}

- (NSFont * _Nullable)font {
    return [self attribute:NSFontAttributeName atIndex:0 effectiveRange:nil];
}

@end

@implementation NSMutableAttributedString (Attributes)

- (void)setAnchor:(Anchor * _Nullable)anchor {
    [self removeAttribute:AnchorAttributeName range:NSMakeRange(0, self.length)];
    if (anchor != nil) {
        [self addAttribute:AnchorAttributeName value:anchor range:NSMakeRange(0, self.length)];
    }
}

- (void)setParagraphStyle:(NSParagraphStyle * _Nullable)paraStyle {
    // TODO: Can we be sure to always find an associated paragraph style at the first index?
    [self removeAttribute:NSParagraphStyleAttributeName range:NSMakeRange(0, self.length)];
    if (paraStyle != nil) {
        [self addAttribute:NSParagraphStyleAttributeName value:paraStyle range:NSMakeRange(0, self.length)];
    }
}

- (void)setColor:(NSColor * _Nullable)color {
    [self removeAttribute:NSForegroundColorAttributeName range:NSMakeRange(0, self.length)];
    if (color != nil) {
        [self addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, self.length)];
    }
}

- (void)setFont:(NSFont * _Nullable)font {
    [self removeAttribute:NSFontAttributeName range:NSMakeRange(0, self.length)];
    if (font != nil) {
        [self addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, self.length)];
    }
}

@end
