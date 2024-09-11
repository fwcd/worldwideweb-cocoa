/*		Page layout subclass
**		--------------------
**
** History
**	14 Mar 91	Based on the DrawPageLayout class in the Draw example application
**
*/

#pragma once

#import <AppKit/AppKit.h>

@interface WWWPageLayout : NSPageLayout

@property CGFloat leftMargin;
@property CGFloat rightMargin;
@property CGFloat topMargin;
@property CGFloat bottomMargin;

/* Methods overridden from superclass */

- (void)readPrintInfo;
- (void)writePrintInfo;

@end
