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

- pickedUnits:sender
/*
 * Called when the user selects different units (e.g. cm or inches).
 * Must update the margin fields.
 */
{
    float old, new;

    [self convertOldFactor:&old newFactor:&new];
    [leftMargin setFloatValue:new *[leftMargin floatValue] / old];
    [rightMargin setFloatValue:new *[rightMargin floatValue] / old];
    [topMargin setFloatValue:new *[topMargin floatValue] / old];
    [bottomMargin setFloatValue:new *[bottomMargin floatValue] / old];
    
    return self;
}

- readPrintInfo
/*
 * Sets the margin fields from the Application-wide PrintInfo.
 */
{
    id pi;
    float conversion, dummy;
    CGFloat left, right, top, bottom;

    [super readPrintInfo];
    pi = [NSPrintInfo sharedPrintInfo];
    [self convertOldFactor:&conversion newFactor:&dummy];
    left = [pi leftMargin];
    right = [pi rightMargin];
    top = [pi topMargin];
    bottom = [pi bottomMargin];
    [leftMargin setFloatValue:left * conversion];
    [rightMargin setFloatValue:right * conversion];
    [topMargin setFloatValue:top * conversion];
    [bottomMargin setFloatValue:bottom * conversion];

    return self;
}

- writePrintInfo
/*
 * Sets the margin values in the Application-wide PrintInfo from
 * the margin fields in the panel.
 */
{
    id pi;
    float conversion, dummy;

    [super writePrintInfo];
    pi = [NSPrintInfo sharedPrintInfo];
    [self convertOldFactor:&conversion newFactor:&dummy];
    if (conversion) {
        [pi setLeftMargin:[leftMargin floatValue] / conversion];
        [pi setRightMargin:[rightMargin floatValue] / conversion];
        [pi setTopMargin:[topMargin floatValue] / conversion];
        [pi setBottomMargin:[bottomMargin floatValue] / conversion];
    }
    [[NSUserDefaults standardUserDefaults] setValue:[pi paperName] forKey:@"PaperType"]; /* Save it */
    return self;
}

/* NIB outlet setting methods */

- setTopBotForm:anObject {
    [anObject setTarget:ok];
    [anObject setAction:@selector(performClick:)];
    [anObject setNextText:width];
    return self;
}

- setSideForm:anObject {
    [scale setNextText:anObject];
    [anObject setTarget:ok];
    [anObject setAction:@selector(performClick:)];
    return self;
}

- setLeftMargin:anObject {
    leftMargin = anObject;
    return self;
}

- setRightMargin:anObject {
    rightMargin = anObject;
    return self;
}

- setTopMargin:anObject {
    topMargin = anObject;
    return self;
}

- setBottomMargin:anObject {
    bottomMargin = anObject;
    return self;
}

@end
