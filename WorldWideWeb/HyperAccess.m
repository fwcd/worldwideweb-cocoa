//								HyperAccess.m

//	A HyperAccess object provides access to hyperinformation, using
//	particular protocols and data format transformations.
//	This actual class will not work itself: it just contains common code.

// History:
//	26 Sep 90	Written TBL

#import "HyperAccess.h"
#import "Anchor.h"
#import "HTUtils.h"
#import "HyperManager.h"
#import <AppKit/AppKit.h>
#include <stdio.h>

@implementation HyperAccess

- (void)setManager:anObject {
    _manager = anObject;
    [(HyperManager *)_manager registerAccess:self];
}

//	Return the name of this access method

- (const char *)name {
    return "Generic";
}

//		Actions:

//	These are all dummies, because only subclasses of this class actually work.

- (IBAction)search:sender {
}

- (IBAction)searchRTF:sender {
}

- (IBAction)searchSGML:sender {
}

//	Direct open buttons:

- (IBAction)open:sender {
}

- (IBAction)openRTF:sender {
}

- (IBAction)openSGML:sender {
}
- accessName:(const char *)name Diagnostic:(int)level {
    return nil; /* can't do that. */
}

//	This will load an anchor which has a name

- loadAnchor:(Anchor *)anAnchor {
    return [self loadAnchor:anAnchor Diagnostic:0]; // If not otherwise implemented
}

- loadAnchor:(Anchor *)a Diagnostic:(int)diagnostic {
    return nil;
}

- saveNode:(HyperText *)aText {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setInformativeText:
               [NSString
                   stringWithFormat:@"You cannot overwrite this original document. You can use `save a copy in...'"]];
    [alert runModal];
    NSLog(@"HyperAccess: You cannot save a hypertext document in this domain.\n");
    return nil;
}

//	Text Delegate methods
//	---------------------
//	These default methods for an access allow editing, and change the cross
//	in the window close button to a broken one if the text changes.

#ifdef TEXTISEMPTY
//	Called whenever the text is changed
- text:thatText isEmpty:flag {
    if (TRACE)
        NSLog(@"Text %i changed, length=%i\n", thatText, [thatText textLength]);
    return self;
}
#endif

- (void)textDidChange:(NSNotification *)notification {
    if (TRACE)
        NSLog(@"HM: text Did Change.\n");
    [[notification.object window] setDocumentEdited:YES]; /* Broken cross in close button */
}

- (void)textDidBeginEditing:(NSNotification *)notification {
    if (TRACE)
        NSLog(@"HM: text Will Change -- OK\n");
}

//	These delegate methods are special to HyperText:

- (void)hyperTextDidBecomeMain:(HyperText *)sender {
    [self.manager hyperTextDidBecomeMain:sender]; /* Pass the buck */
}
@end
