/*		Page layout subclass
**		--------------------
**
** History
**	14 Mar 91	Based on the DrawPageLayout class in the Draw example application
**
*/

#import <AppKit/AppKit.h>

@interface WWWPageLayout : NSPageLayout
{
    id leftMargin;
    id rightMargin;
    id topMargin;
    id bottomMargin;
}

/* Methods overridden from superclass */

- pickedUnits:sender;
- readPrintInfo;
- writePrintInfo;

@end


