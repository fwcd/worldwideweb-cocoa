//			HyperText Class
//

#pragma once

#import "Anchor.h"
#import "HTStyle.h"
#import "NXShims.h"
#import <AppKit/AppKit.h>

/*	Bit fields describing the capabilities of a node:
*/
#define HT_READ 1
#define HT_WRITE 2
#define HT_LINK_TO_NODE 4
#define HT_LINK_TO_PART 8
#define HT_LINK_FROM_NODE 16
#define HT_LINK_FROM_PART 32
#define HT_DO_ANYTHING 63

extern void write_rtf_header(NXStream *rtfStream);

@interface HyperText : NSTextView <NSWindowDelegate> {
    id server;            //	Responsible for maintaining this node
                          //	NSMutableArray *	Anchors;	//	A list of the anchors
    Anchor *nodeAnchor;   //	An anchor representing the node
                          //	NSMutableArray *  unAnchors;	// 	List of unanchored links to other nodes
    int nextAnchorNumber; //	The serial number of the next anchor
    int protection;       //	Server capability authorised
    BOOL isIndex;         //	Can accept a keyword search
                          //	NSMutableArray *	alsoStore;	//	Store these nodes at the same time
                          //	HyperText * storeWith;	//	Store along with the given node please.
    int slotNumber;       //	Window display position
    int format;           //	See WWW.h for values
}

- initWithAnchor:(Anchor *)anAnchor Server:(id)server;

- readSGML:(NXStream *)sgmlStream diagnostic:(int)diagnostic;
- writeSGML:(NXStream *)sgmlStream relativeTo:(const char *)aName;

- readText:(NXStream *)stream;
- server;
- (BOOL)isIndex;
- setupWindow;
- adjustWindow; // Adust scroll bars, sizeability, size, etc.

- (int)format;
- setFormat:(int)format;

//	Style handling:

- applyToSimilar:(HTStyle *)style;                                // Apply this style to the selection
- (HyperText *)applyStyle:(HTStyle *)style;                       // Apply this style to the selection
- (HyperText *)selectUnstyled:(HTStyleSheet *)sheet;              // Select the first unstyled run.
- (void)updateStyle:(HTStyle *)style;                             // Update all text with changed style.
- (HTStyle *)selectionStyle:(HTStyleSheet *)sheet;                // style if any of  selection
- (void)replaceSel:(const char *)aString style:(HTStyle *)aStyle; // Paste in styled text

//	"Fast" Methods for external parsers:

- appendBegin;                                                     // Start an append sequence
- appendStyle:(HTStyle *)style;                                    // Set the style for future text
- appendText:(const char *)text;                                   // Add a string
- appendBeginAnchor:(const char *)name to:(const char *)reference; // Begin an anchor
- appendEndAnchor;                                                 // End it
- appendEnd;                                                       // Flush out all additions so far

//	Anchor handling:

//- anchors;				// Set of anchors
- (Anchor *)nodeAnchor;        // Single anchor representing this node
- (Anchor *)selectedLink;      // Return selected anchor if any
- followLink;                  // (If selected)
- unlinkSelection;             // Remove anchor info from selection
- (Anchor *)referenceSelected; // Generate anchor for this node
- (Anchor *)referenceAll;
- (Anchor *)linkSelTo:(Anchor *)anchor;    // Link selected text to this anchor.
- disconnectAnchor:(Anchor *)anchor;       // Remove reference from this node.
- (Anchor *)selectAnchor:(Anchor *)anchor; // Bring to front and highlight it.

- (void)setTitle:(const char *)title;
- dump:sender; // diagnostic output

//	Override methods of superclasses:

- readText:(NXStream *)stream;         // Also set format variable.
- readRichText:(NXStream *)stream;     // Also set format variable.
- (void)mouseDown:(NSEvent *)theEvent; // Double click become hyperjump
- (void)keyDown:(NSEvent *)theEvent;   //
- (void)paste:(id)sender;              //

//	Window delegate methods:

- (void)windowDidBecomeMain:(NSNotification *)notification;
- (void)windowWillClose:(NSNotification *)notification;

@end
