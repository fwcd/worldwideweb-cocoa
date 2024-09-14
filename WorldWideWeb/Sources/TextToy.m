//	Text Management Module					TextToy.m
//	----------------------

//	This file allows one to create links between Hypertexts. It selects the
//	current HyperText and then passes the buck to the HyperText class.

#import "TextToy.h"
#import "Anchor.h"
#import "HyperText.h"
#import <AppKit/AppKit.h>

#import "HTUtils.h"

@implementation TextToy

#define THIS_TEXT (HyperText *)[[[NSApp mainWindow] contentView] documentView]

Anchor *Mark; /* A marked Anchor */

- setSearchWindow:anObject {
    SearchWindow = anObject;
    return self;
}

/*	Action Methods
**	==============
*/

/*	Set up the start and end of a link
*/
- (IBAction)linkToMark:sender {
    [THIS_TEXT linkSelTo:Mark];
}

- (IBAction)linkToNew:sender {
}

- (IBAction)unlink:sender {
    [THIS_TEXT unlinkSelection];
}

- (IBAction)markSelected:sender {
    [THIS_TEXT referenceSelected];
}
- (IBAction)markAll:sender {
    [THIS_TEXT referenceAll];
}

- (IBAction)followLink:sender {
    [THIS_TEXT followLink]; // never mind whether there is a link
}

- (IBAction)dump:sender {
    [THIS_TEXT dump:sender];
}

//		Window Delegate Functions
//		-------------------------

- windowDidBecomeKey:window {
    return self;
}

//	When a document is selected, turn the index search on or off as
//	appropriate

- windowDidBecomeMain:window {
    HyperText *HT = [[window contentView] documentView];
    if (!HT)
        return self;

    if ([HT isIndex]) {
        [SearchWindow makeKeyAndOrderFront:self];
    } else {
        [SearchWindow orderOut:self];
    }

    return self;
}

//			Access Management functions
//			===========================

- (void)registerAccess:(HyperAccess *)access {
    if (!accesses)
        accesses = [NSMutableArray new];
    [accesses addObject:access];
}

@end
