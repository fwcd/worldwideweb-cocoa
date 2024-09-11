/*		Page layout subclass
**		--------------------
**
** History
**	14 Mar 91	Based on the DrawPageLayout class in the NeXTStep "Draw"
**			example application
**
*/
#import "WWWPageLayout.h"
#import <AppKit/AppKit.h>

@implementation WWWPageLayout
/*
 * PageLayout is overridden so that the user can set the margins of
 * the page.  This is important in a Draw program where the user
 * typically wants to maximize the drawable area on the page.
 *
 * The accessory view is used to add the additional fields, and
 * pickedUnits: is overridden so that the margin is displayed in the
 * currently selected units.  Note that the accessoryView is set
 * in InterfaceBuilder using the outlet mechanism!
 *
 * This can be used as an example of how to override Application Kit panels.
 */

- (void)readPrintInfo
/*
 * Sets the margin fields from the Application-wide PrintInfo.
 */
{
    CGFloat left, right, top, bottom;

    [super readPrintInfo];
    NSPrintInfo *pi = [NSPrintInfo sharedPrintInfo];
    double conversion = [pi scalingFactor];
    left = [pi leftMargin];
    right = [pi rightMargin];
    top = [pi topMargin];
    bottom = [pi bottomMargin];
    self.leftMargin = left * conversion;
    self.rightMargin = right * conversion;
    self.topMargin = top * conversion;
    self.bottomMargin = bottom * conversion;
}

- (void)writePrintInfo
/*
 * Sets the margin values in the Application-wide PrintInfo from
 * the margin fields in the panel.
 */
{
    [super writePrintInfo];
    NSPrintInfo *pi = [NSPrintInfo sharedPrintInfo];
    double conversion = [pi scalingFactor];
    if (conversion) {
        [pi setLeftMargin:self.leftMargin / conversion];
        [pi setRightMargin:self.rightMargin / conversion];
        [pi setTopMargin:self.topMargin / conversion];
        [pi setBottomMargin:self.bottomMargin / conversion];
    }
    [[NSUserDefaults standardUserDefaults] setValue:[pi paperName] forKey:@"PaperType"]; /* Save it */
}

@end
