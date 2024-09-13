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

- (Anchor *_Nullable)anchor {
    // TODO: Can we be sure to always find an associated anchor (if existent) at the first index? Does attributeRuns already guaranteed that or should we document it as an invariant if not?
    return [self attribute:AnchorAttributeName atIndex:0 effectiveRange:nil];
}

- (NSParagraphStyle *_Nullable)paragraphStyle {
    // TODO: Can we be sure to always find an associated paragraph style at the first index?
    return [self attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:nil];
}

- (NSColor *_Nullable)color {
    return [self attribute:NSForegroundColorAttributeName atIndex:0 effectiveRange:nil];
}

- (NSFont *_Nullable)font {
    return [self attribute:NSFontAttributeName atIndex:0 effectiveRange:nil];
}

@end

@implementation NSMutableAttributedString (Attributes)

- (void)setAnchor:(Anchor *_Nullable)anchor inRange:(NSRange)range {
    [self removeAttribute:AnchorAttributeName range:range];
    if (anchor != nil) {
        [self addAttribute:AnchorAttributeName value:anchor range:range];
    }
}

- (void)setAnchor:(Anchor *_Nullable)anchor {
    [self setAnchor:anchor inRange:NSMakeRange(0, self.length)];
}

- (void)setParagraphStyle:(NSParagraphStyle *_Nullable)paraStyle inRange:(NSRange)range {
    // TODO: Can we be sure to always find an associated paragraph style at the first index?
    [self removeAttribute:NSParagraphStyleAttributeName range:range];
    if (paraStyle != nil) {
        [self addAttribute:NSParagraphStyleAttributeName value:paraStyle range:range];
    }
}

- (void)setParagraphStyle:(NSParagraphStyle *_Nullable)paraStyle {
    [self setParagraphStyle:paraStyle inRange:NSMakeRange(0, self.length)];
}

- (void)setColor:(NSColor *_Nullable)color inRange:(NSRange)range {
    [self removeAttribute:NSForegroundColorAttributeName range:range];
    if (color != nil) {
        [self addAttribute:NSForegroundColorAttributeName value:color range:range];
    }
}

- (void)setColor:(NSColor *)color {
    [self setColor:color inRange:NSMakeRange(0, self.length)];
}

- (void)setFont:(NSFont *_Nullable)font inRange:(NSRange)range {
    [self removeAttribute:NSFontAttributeName range:range];
    if (font != nil) {
        [self addAttribute:NSFontAttributeName value:font range:range];
    }
}

- (void)setFont:(NSFont *_Nullable)font {
    [self setFont:font inRange:NSMakeRange(0, self.length)];
}

@end
