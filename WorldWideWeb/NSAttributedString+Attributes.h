//
//  NSAttributedString+Attributes.h
//  WorldWideWeb
//
//  Created on 13.09.24
//

#pragma once

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/// A key that we use to store anchors in attributed string runs to replace `NXRun.info`, which the NeXTStep API reserved for app-specific usage.
NSString *const AnchorAttributeName;

@interface NSAttributedString (Attributes)

- (Anchor *_Nullable)anchor;
- (NSParagraphStyle *_Nullable)paragraphStyle;
- (NSColor *_Nullable)color;
- (NSFont *_Nullable)font;

@end

@interface NSMutableAttributedString (Attributes)

- (void)setAnchor:(Anchor *_Nullable)anchor;
- (void)setAnchor:(Anchor *_Nullable)anchor inRange:(NSRange)range;

- (void)setParagraphStyle:(NSParagraphStyle *_Nullable)paraStyle;
- (void)setParagraphStyle:(NSParagraphStyle *_Nullable)paraStyle inRange:(NSRange)range;

- (void)setColor:(NSColor *_Nullable)color;
- (void)setColor:(NSColor *_Nullable)color inRange:(NSRange)range;

- (void)setFont:(NSFont *_Nullable)font inRange:(NSRange)range;
- (void)setFont:(NSFont *_Nullable)font;

@end

NS_ASSUME_NONNULL_END
