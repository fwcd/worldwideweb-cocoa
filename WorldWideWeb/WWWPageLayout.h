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

@property(nonatomic) IBOutlet NSFormCell *leftMargin;
@property(nonatomic) IBOutlet NSFormCell *rightMargin;
@property(nonatomic) IBOutlet NSFormCell *topMargin;
@property(nonatomic) IBOutlet NSFormCell *bottomMargin;

@property(nonatomic) IBOutlet NSBox *accessoryView;
@property(nonatomic) IBOutlet NSForm *sideForm;
@property(nonatomic) IBOutlet NSForm *topBotForm;

/* Methods overridden from superclass */

- (void)readPrintInfo;
- (void)writePrintInfo;

@end
