//	HyperText Implementation				    HyperText.m
//	------------------------
//
// HyperText is like Text, but includes links to and from other hypertexts.
//
// Authors:
//	TBL		Tim Berners-Lee CERN/CN
//
// See also:
//	The Anchor class, and the HyperAccess class.
//
// History:
//	25 Sep 90	Written (TBL) with the  help of the Interface builder.
//	14 Mar 91	Page width is taken from application's page layout.

// Notes.
//
//	For all anchors to have addresses, the node must be made with
//	newAnchor:Server: . Do not use any other creation methods inherited.

// Notes on the Cocoa port.
//
//  The Cocoa API differs quite a bit from the NeXTStep API in terms of how text rendering and related classes are implemented. A key insight is that a lot of classes have closely analogous modern equivalents though. For example, the `Text` class is similar to `NSTextView` and text runs, as implemented with `NXRun`, resemble attributed strings in the modern API (or its subclass `NSTextStorage`). This is also why the implementation of these methods diverges a bit further from the exact original code than other parts of the codebase. Still, a key goal is to stick to the original semantics where possible.
//
//  For more resources, check out these docs of the NeXTStep and the Cocoa API:
//
//  - https://www.nextop.de/NeXTstep_3.3_Developer_Documentation/GeneralRef/02_ApplicationKit/TypesAndConstants/AppKitTypes.htmld/index.html#:~:text=typedef%20struct%20_NXRun
//  - https://developer.apple.com/documentation/appkit/nstextstorage
//  - https://developer.apple.com/documentation/foundation/nsmutableattributedstring

#import "HyperText.h"
#import "HTParse.h"
#import "HTStyle.h"
#import "HTUtils.h"
#import "HyperAccess.h"
#import "HyperTextDelegate.h"
#import "NSAttributedString+Attributes.h"
#import "NXShims.h"
#import "WWW.h"
#import <AppKit/AppKit.h>
#import <malloc/malloc.h>

@implementation HyperText

#define ANCHOR_ID_PREFIX 'z' /* Auto anchors run z1, z2, ... 921122 */

extern HTStyleSheet *styleSheet; /* see StyleToy */

static int window_sequence = 0; /* For stacking windows neatly */
#define SLOTS 30                /* Number of position slots */
static HyperText *slot[SLOTS];  /* Ids of HT objects taking them */

#define NICE_HEIGHT 600.0 /* Allows a few windows to be stacked */
#define MAX_HEIGHT 720.0  /* Worth going bigger to get it all in	*/
#define MIN_HEIGHT 80.0   /* Mustn't lose the window! */
#define MIN_WIDTH 200.0

static HyperText *HT; /* Global pointer to self to allow C mixing */

+ (void)initialize {
    int i;
    for (i = 0; i < SLOTS; i++)
        slot[i] = 0;
}

//	Get Application page layout's Page Width
//	----------------------------------------
//
//	Returned in pixels
//
static float page_width() {
    PrintInfo *pi = [NSPrintInfo sharedPrintInfo]; // Page layout details
    CGFloat topMargin, bottomMargin, leftMargin, rightMargin;
    const NSRect *paper = [pi paperRect]; //	In points

    [pi getMarginLeft:&leftMargin right:&rightMargin top:&topMargin bottom:&bottomMargin]; /* In points */
    return (paper->size.width - leftMargin - rightMargin);
}

//			Class methods
//			-------------
//

//	Build a HyperText GIVEN its nodeAnchor.
//	--------------------------------------

- initWithAnchor:(Anchor *)anAnchor Server:(id)aServer {
    NSRect aFrame = {{0.0, 0.0}, {page_width(), NICE_HEIGHT}};

    self = [self initWithFrame:aFrame];
    if (TRACE)
        NSLog(@"New node, server is %@\n", aServer);

    nextAnchorNumber = 0;
    protection = 0;    // Can do anything
    format = WWW_HTML; // By default
    // TODO: Should we set a custom font?
    // [self setMonoFont:NO];                                 // By default

    server = (HyperAccess *)aServer;
    [self setDelegate:aServer]; /* For changes */
    nodeAnchor = anAnchor;
    [nodeAnchor setNode:self];
    return self;
}

//			Instance Methods
//			----------------

//	Free the hypertext.

- (void)dealloc {
    slot[slotNumber] = 0;     //	Allow slot to be reused
    [nodeAnchor setNode:nil]; // 	Invalidate the node
}

//	Read and set format

- (int)format {
    return format;
}
- setFormat:(int)f {
    format = f;
    return self;
}

//	Useful diagnostic routine:  Dump to standard output
//	---------------------------------------------------
//
//	This first lists the runs up to and including the current run,
//	then it lists the attributes of the current run.
//
- dump:sender {
    // TODO: Fix the implementation by migrating to NSTextStorage (which actually is an NSAttributedString) and the `info` property to anchor attributed.

    //    int pos;     /* Start of run being scanned */
    //    int sob = 0; /* Start of text block being scanned */
    //    NSArray<NSTextStorage *> *r = self.textStorage.attributeRuns;
    //    NXTextBlock *block = firstTextBlock;
    //
    //    NSLog(@"Hypertext %i, selected(%i,%i)", self, sp0.cp, spN.cp);
    //    if (self.delegate)
    //        NSLog(@", has delegate");
    //    NSLog(@".\n");
    //
    //    NSRect frame = self.frame;
    //    NSLog(@"    Frame is at (%f, %f, size is (%f, %f)\n", frame.origin.x, frame.origin.y, frame.size.width,
    //           frame.size.height);
    //
    //    NSLog(@"    Text blocks and runs up to character %i:\n", sp0.cp);
    //    for (pos = 0; pos <= sp0.cp; pos = pos + ((r++)->chars)) {
    //        while (sob <= pos) {
    //            NSLog(@"%5i: Block of %i/%i characters at 0x%x starts `%10.10s'\n", sob, block->chars,
    //                   malloc_size(block->text), block->text, block->text);
    //            sob = sob + block->chars;
    //            block = block->next;
    //        }
    //        NSLog(@"%5i: %3i of fnt=%i p=%i gy=%3.2f RGB=%i i=%i fl=%x\n", pos, r->chars, (int)r->font, r->paraStyle,
    //               r->textGray, r->textRGBColor, (int)(r->info), *(int *)&(r->rFlags));
    //    }
    //    r--; /* Point to run for start of selection */
    //
    //    NSLog(@"\n    Current run:\n\tFont name:\t%s\n", [r->font fontName]);
    //    {
    //        NSParagraphStyle *p = (NSParagraphStyle *)r->paraStyle;
    //        if (!p) {
    //            NSLog(@"\tNo paragraph style!\n");
    //        } else {
    //            int tab;
    //            NSLog(@"\tParagraph style %i\n", p);
    //            NSLog(@"\tIndents: first=%f, left=%f\n", p.firstLineHeadIndent, p.headIndent);
    //            NSLog(@"\tAlignment type=%i, %i tabs:\n", p.alignment, p.tabStops.count);
    //            for (tab = 0; tab < p.tabStops.count; tab++) {
    //                NSLog(@"\t    Tab kind=%i at %f\n", p.tabStops[tab].tabStopType, p.tabStops[tab].location);
    //            }
    //        }
    //    }
    //    NSLog(@"\n");
    return self;
}

//	Adjust Scrollers and Window size for current text size
//	------------------------------------------------------
//
//The scrollers are turned off if they possibly can be, to simplify the screen.
// If the text is editable, they have to be left on, although formatted text is
// allowed to wrap round, and so horizontal scroll bars are not necessary.
// The window size is adjusted as a function of the text size and scrollers.
//
//	@@ Bug: The resize bar should be removed if there are no scrollers.
//	This is difficult to do -- might have to make a new window.
//
- adjustWindow {
#define MAX_WIDTH paperWidth

    NSRect scroll_frame;
    NSRect old_scroll_frame;
    NSSize size;
    BOOL scroll_X, scroll_Y; // Do we need scrollers?

    NSScrollView *scrollview = [self.window contentView]; // Pick up id of ScrollView
    float paperWidth = page_width();                      // Get page layout width

    [self.window disableFlushWindow]; // Prevent flashes

    [self setVerticallyResizable:YES]; // Can change size automatically
    bool isMonoFont = NO;              // TODO: Figure this out
    [self setHorizontallyResizable:isMonoFont];
    // TODO: Do we need this?
    // [self calcLine];  // Wrap text to current text size
    [self sizeToFit]; // Reduce size if possible.

    CGFloat maxX = self.maxSize.width;
    CGFloat maxY = self.maxSize.height;

    if (maxY > MAX_HEIGHT) {
        scroll_Y = YES;
        size.height = NICE_HEIGHT;
    } else {
        scroll_Y = [self isEditable];
        size.height = maxY < MIN_HEIGHT ? MIN_HEIGHT : maxY;
    }

    if (isMonoFont) {
        scroll_X = [self isEditable] || (maxX > MAX_WIDTH);
        // FIXME: Disable wrapping
        // [self setNoWrap];
    } else {
        scroll_X = NO;
        // FIXME: Enable wrapping
        // [self setCharWrap:NO]; // Word wrap please
    }
    if (maxX > MAX_WIDTH) {
        size.width = MAX_WIDTH;
    } else {
        size.width = maxX < MIN_WIDTH ? MIN_WIDTH : maxX;
    }

    // maxX is the length of the longest line.
    //	It only represnts the width of the page
    //	 needed if the line is quad left. If the longest line was
    //	centered or flush right, it may be truncated unless we resize
    //	it to fit.

    if (!scroll_X) {
        [self setFrameSize:NSMakeSize(size.width, maxY)];
        // TODO: Do we need this?
        // [self calcLine];
        [self sizeToFit]; // Algorithm found by trial and error.
    }

    //	Set up the scroll view and window to match:

    scroll_frame.size = [NSScrollView frameSizeForContentSize:size
                                        hasHorizontalScroller:scroll_X
                                          hasVerticalScroller:scroll_Y
                                                   borderType:NSLineBorder];

    [scrollview setHasVerticalScroller:scroll_Y];
    [scrollview setHasHorizontalScroller:scroll_X];

    //	Has the frame size changed?

    old_scroll_frame = scrollview.frame;
    if ((old_scroll_frame.size.width != scroll_frame.size.width) ||
        (old_scroll_frame.size.height != scroll_frame.size.height)) {

        // Now we want to leave the top left corner of the window unmoved:

#ifdef OLD_METHOD
        NSRect oldframe;
        oldframe = self.window.frame;
        [self.window sizeWindow:scroll_frame.size.width:scroll_frame.size.height];
        [self.window moveTopLeftTo:oldframe.origin.x:oldframe.origin.y + oldframe.size.height];
#else
        NSRect newFrame;
        scroll_frame.origin.x = 150 + (slotNumber % 10) * 30 + ((slotNumber / 10) % 3) * 40;
        scroll_frame.origin.y =
            185 + NICE_HEIGHT - scroll_frame.size.height - (slotNumber % 10) * 20 - ((slotNumber / 10) % 3) * 3;
        newFrame = [NSWindow frameRectForContentRect:scroll_frame
                                           styleMask:NSWindowStyleMaskTitled]; // Doesn't allow space for resize bar
        newFrame.origin.y = newFrame.origin.y - 9.0;
        newFrame.size.height = newFrame.size.height + 9.0; // For resize bar
        [self.window setFrame:newFrame display:true];
#endif
    }

#ifdef VERSION_1_STRANGENESS
    //	In version 2, the format of the last run is overwritten with the format
    //	of the preceding run!
    {
        NSRect frm; /* Try this to get over "text strangeness" */
        frm = self.frame;
        [self renewRuns:NULL text:NULL frame:&frm tag:0];
    }
#endif
    [self.window enableFlushWindow];
    // TODO: Do we need this?
    // [self calcLine];       /* Prevent messy screen */
    [self.window display]; /* Ought to clean it up */
    return self;

} /* adjustWindow */

//	Set up a window in the current application for this hypertext
//	-------------------------------------------------------------

- setupWindow {
    NSRect scroll_frame;                // Calculated later
    NSSize min_size = {300.0, 200.0};   // Minimum size of text
    NSSize max_size = {1.0e30, 1.0e30}; // Maximum size of text

    NSScrollView *scrollview;
    NSSize nice_size = {0.0, NICE_HEIGHT}; // Guess height

    nice_size.width = page_width();
    scroll_frame.size = [NSScrollView frameSizeForContentSize:nice_size
                                        hasHorizontalScroller:NO
                                          hasVerticalScroller:YES
                                                   borderType:NSLineBorder];

    {
        int i; /* Slot address */
        for (i = 0; (i < SLOTS) && slot[i]; i++)
            ; /* Find spare slot */
        if (i = SLOTS)
            i = (window_sequence = (window_sequence + 1) % SLOTS);
        slot[i] = self;
        slotNumber = i;
        scroll_frame.origin.x = 150 + (slotNumber % 10) * 30 + ((slotNumber / 10) % 3) * 40;
        scroll_frame.origin.y = 185 - (slotNumber % 10) * 20 - ((slotNumber / 10) % 3) * 3;
    }

    //	Build a window around the text in order to display it.

#define NX_ALLBUTTONS 7 // Fudge -- the followin methos is obsolete in 3.0:
    NSWindow *window = [[NSWindow alloc] initWithContentRect:scroll_frame
                                                   styleMask:NSWindowStyleMaskTitled
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO]; // display now
    [window setDelegate:self];                                    // Get closure warning
    [window makeKeyAndOrderFront:self];                           // Make it visible
    [window setBackgroundColor:[NSColor whiteColor]];             // White seems to be necessary.

    scrollview = [[NSScrollView alloc] initWithFrame:scroll_frame];
    [scrollview setHasVerticalScroller:YES];
    [scrollview setHasHorizontalScroller:NO]; // Guess.
    [window setContentView:scrollview];

    [scrollview setDocumentView:self];
    [self setVerticallyResizable:YES]; // Changes size automatically
    [self setHorizontallyResizable:NO];
    [self setMinSize:min_size];                    // Stop it shrinking to nought
    [self setMaxSize:max_size];                    // Stop it being chopped when editing
    [self setPostsFrameChangedNotifications:true]; // Tell scrollview See QA 555
    [window display];                              // Maybe we will see it now
    return self;
}

//		Return Instance Variables
//		-------------------------
- server {
    return server;
}
- (Anchor *)nodeAnchor {
    return nodeAnchor;
}
- (BOOL)isIndex {
    return isIndex;
}

/*	Return reference to a part of, or all of, this node
**	---------------------------------------------------
*/

//	Generate an anchor for a given part of this node, giving it an
//	arbitrary (numeric) name.

- (Anchor *)anchor {
    Anchor *a;
    char s[20];

    sprintf(s, "%c%i", ANCHOR_ID_PREFIX, nextAnchorNumber++);
    a = [[Anchor alloc] initWithParent:nodeAnchor tag:s];
    [self.delegate textDidChange:[NSNotification notificationWithName:NSControlTextDidChangeNotification object:self]];
    return a;
}

//  Find the runs containing the selection
//  --------------------------------------

- (NSRange)runRangeContainingSelection {
    NSRange selection = self.selectedRange;
    NSArray<NSTextStorage *> *attributeRuns = self.textStorage.attributeRuns;

    NSUInteger chars = 0;
    NSUInteger startRunIndex = 0;
    BOOL foundStart = NO;

    for (NSUInteger i = 0; i < attributeRuns.count; i++) {
        NSTextStorage *run = attributeRuns[i];
        if (!foundStart && chars + run.length > selection.location) {
            // Found run containing selection start
            startRunIndex = i;
            foundStart = YES;
        }
        if (chars + run.length >= selection.location + selection.length) {
            // Found run containing selection end
            NSRange runRange = NSMakeRange(startRunIndex, i - startRunIndex);
            return runRange;
        }
        chars += run.length;
    }

    return NSMakeRange(0, 0);
}

- (NSArray<NSTextStorage *> *)runsContainingSelection {
    NSArray<NSTextStorage *> *attributeRuns = self.textStorage.attributeRuns;
    NSRange runRange = [self runRangeContainingSelection];

    if (runRange.location > 0 || runRange.length > 0) {
        return [attributeRuns subarrayWithRange:runRange];
    } else {
        return nil;
    }
}

- (NSTextStorage *)runContainingSelectionStart {
    NSRange runRange = [self runRangeContainingSelection];
    NSArray<NSTextStorage *> *runs = self.textStorage.attributeRuns;
    return runs[runRange.location];
}

//  Find associated attributes for runs
//  -----------------------------------

//	Check whether an anchor has been selected
//	-----------------------------------------

- (Anchor *)anchorSelected {
    Anchor *a;

    for (NSTextStorage *run in [self runsContainingSelection]) {
        a = [run anchor];
        if (a)
            return a;
    }
    if (TRACE)
        NSLog(@"HyperText: No anchor selected.\n");
    return nil;
}

//	Public method:	Generate an anchor for the selected text
//	--------------------------------------------------------
//
//	If the document is not editable, then nil is returned
//	(unless the user asks for an existing anchor).
//
- (Anchor *)referenceSelected {
    Anchor *a;
    HTStyle *style = HTStyleNew();

    a = [self anchorSelected];
    if (a)
        return a; /* User asked for existing one */

    if ([self isEditable])
        [self.window setDocumentEdited:YES];
    else
        return nil;

    a = [self anchor];
    style->anchor = a;
    style->clearAnchor = NO;
    [self applyStyle:style];
    if (TRACE) {
        NSRange selection = self.selectedRange;
        NSLog(@"HyperText: New dest anchor %@ from %lu to %lu.\n", a, selection.location,
              selection.location + selection.length);
    }
    [self.delegate textDidChange:[NSNotification notificationWithName:NSControlTextDidChangeNotification object:self]];
    return a;
}

//	Generate a live anchor for the text, and link it to a given one
//	----------------------------------------------------------------

- (Anchor *)linkSelTo:(Anchor *)anAnchor {
    Anchor *a;
    HTStyle *style = HTStyleNew();

    if (!anAnchor)
        return nil; /* Anchor must exist */

    if ([self isEditable])
        [self.window setDocumentEdited:YES];
    else
        return nil;

    a = [self anchorSelected];
    if (!a) {
        a = [self anchor];
        if (TRACE) {
            NSRange selection = self.selectedRange;
            NSLog(@"HyperText: New source anchor %@ from %lu to %lu.\n", a, selection.location,
                  selection.location + selection.length);
        }
    } else {
        [a select];
        if (TRACE) {
            NSLog(@"HyperText: Existing source anchor %@ selected.\n", a);
        }
    }
    style->anchor = a;
    style->clearAnchor = NO;
    [a linkTo:anAnchor];     // Link it up
    [self applyStyle:style]; // Will highlight it because linked
    free(style);
    return a;
}

//	Purge anchor from selected text
//	-------------------------------
//
//	The anchor is left becuase in general we don't delete anchors.
//	In any case, we would have to check whether all text referencing it
//	was deleted.
//
- unlinkSelection {
    HTStyle *style = HTStyleNew();

    if ([self isEditable])
        [self.window setDocumentEdited:YES];
    else
        return nil;

    style->anchor = nil;
    style->clearAnchor = YES;
    [self applyStyle:style];
    free(style);
    return self;
}

- (Anchor *)referenceAll {
    return nodeAnchor; // Just return the same one each time
}

//	Select an anchor
//	----------------
//
//	If there are any runs linked to this anchor, we select them. Otherwise,
//	we just bring the window to the front.

- (Anchor *)selectAnchor:(Anchor *)anchor {
    NSArray<NSTextStorage *> *runs = self.textStorage.attributeRuns;

    NSUInteger chars = 0;
    NSUInteger startChars = 0;
    BOOL foundStart = NO;

    for (NSUInteger i = 0; i < runs.count; i++) {
        NSTextStorage *run = runs[i];
        Anchor *runAnchor = [run anchor];
        if (runAnchor == anchor && !foundStart) {
            startChars = chars;
        } else if (runAnchor != anchor && foundStart) {
            [self.window makeKeyAndOrderFront:self];
            NSRange range = NSMakeRange(startChars, chars - startChars);
            [self setSelectedRange:range];
            [self scrollRangeToVisible:range];
            return anchor;
        }
        chars += run.length;
    }

    if (TRACE)
        NSLog(@"HT: Anchor has no explicitly related text.\n");
    [self.window makeKeyAndOrderFront:self];
    return nil;
}

//    Convert a range of run indices to a character range
//    ---------------------------------------------------

- (NSRange)charRangeForRunRange:(NSRange)runRange {
    NSArray<NSTextStorage *> *runs = self.textStorage.attributeRuns;

    assert(runRange.location >= 0 && runRange.location < runs.count);
    assert(runRange.location + runRange.length <= runs.count);

    NSUInteger location = 0;

    for (NSUInteger i = 0; i < runRange.location; i++) {
        NSTextStorage *run = runs[i];
        location += run.length;
    }

    NSUInteger length = 0;

    for (NSUInteger j = 0; j < runRange.length; j++) {
        NSTextStorage *run = runs[runRange.location + j];
        length += run.length;
    }

    return NSMakeRange(location, length);
}

//

//	Return selected link (if any)				selectedLink:
//	-----------------------------
//
//	This implementation scans down the list of anchors to find the first one
//	on the list which is at least partially selected.
//

- (Anchor *)selectedLink {
    Anchor *a;
    NSArray<NSTextStorage *> *runs = self.textStorage.attributeRuns;
    NSRange runRange = [self runRangeContainingSelection];

    for (NSTextStorage *run in [runs subarrayWithRange:runRange]) {
        a = [run anchor];
        if (a) {
            break;
        }
    }

    if (!a) {
        if (TRACE)
            NSLog(@"HyperText: No anchor selected.\n");
        return nil;
    }

    //	Extend/reduce selection to entire anchor

    {
        while (runRange.location > 0) {
            Anchor *runAnchor = [runs[runRange.location] anchor];
            if (runAnchor == a) {
                runRange.location--;
                runRange.length++;
            }
        }

        while (runRange.location + runRange.length < runs.count) {
            Anchor *runAnchor = [runs[runRange.location + runRange.length] anchor];
            if (runAnchor == a) {
                runRange.length++;
            }
        }

        [self setSelectedRange:[self charRangeForRunRange:runRange]];
    }
    return a;
}

///	Follow selected link (if any)				followLink:
//	-----------------------------
//

//	Find selected link and follow it

- followLink {
    Anchor *a = [self selectedLink];

    if (!a)
        return a; // No link selected

    if ([a follow])
        return a; // Try to follow link

    if (TRACE)
        NSLog(@"HyperText: Can't follow anchor.\n");
    return a; // ... but we did highlight it.
}

- (void)setTitle:(const char *)title {
    [self.window setTitle:[NSString stringWithUTF8String:title]];
}

//				STYLE METHODS
//				=============
//

//	Find Unstyled Text
//	------------------
//
// We have to check whether the paragraph style for each run is one
// on the style sheet.
//
- (HyperText *)selectUnstyled:(HTStyleSheet *)sheet {
    NSUInteger chars = 0;
    NSArray<NSTextStorage *> *runs = self.textStorage.attributeRuns;
    for (NSUInteger i = 0; i < runs.count; i++) {
        NSTextStorage *run = runs[i];
        NSParagraphStyle *paraStyle = [run paragraphStyle];
        if (!HTStyleForParagraph(sheet, paraStyle)) {
            [self setSelectedRange:NSMakeRange(chars, run.length)]; /* Select unstyled run */
            return self;
        }
        chars += run.length;
    }
    return nil;
}

//  Extract the attributes for a given string.
//  -------------------------------------------------------
static NSDictionary<NSString *, id> *attributesForStyle(HTStyle *style) {
    NSMutableDictionary<NSString *, id> *attributes = [[NSMutableDictionary alloc] init];
    if (style->font) {
        attributes[NSFontAttributeName] = style->font;
    }
    if (style->paragraph) {
        attributes[NSParagraphStyleAttributeName] = style->paragraph;
    }
    if (style->anchor || style->clearAnchor) {
        attributes[AnchorAttributeName] = style->anchor;
        attributes[NSUnderlineStyleAttributeName] = @(style->anchor ? NSUnderlineStyleSingle : NSUnderlineStyleNone);
    }
    if (style->textColor) {
        attributes[NSForegroundColorAttributeName] = style->textColor;
    }
    return attributes;
}

//  Copy a style into an attributed string in the given range
//  ---------------------------------------------------------
static void applyRange(HTStyle *style, NSMutableAttributedString *r, NSRange range) {
    // TODO: Should we implement this in terms of attributesForStyle?
    // TODO: Factor out apply, applyRange, attributesForStyle into HTStyle.

    if (style->font) {
        [r setFont:style->font inRange:range];
    }
    if (style->paragraph) {
        [r setParagraphStyle:style->paragraph inRange:range];
    }
    if (style->anchor || style->clearAnchor) {
        [r setAnchor:style->anchor inRange:range];
    }

    if (style->textColor) {
        [r setColor:style->textColor inRange:range];
    }

    [r setUnderlineStyle:NSUnderlineStyleNone inRange:range];
    Anchor *a = [r anchor];
    if (a) {
        //    	r->textGray = 0.166666666;		/* Slightly grey - horrid */
        if ([a destination]) {
            //	    r->textGray = NX_DKGRAY;	/* Anchor highlighting */
            [r setUnderlineStyle:NSUnderlineStyleSingle inRange:range];
        }
    }
    // TODO: Do we need this?
    // r->rFlags.dummy = (r->info != 0); /* Keep track for typingRun */
}

//  Copy a style into an attributed string (e.g. a run)
//  ---------------------------------------------------
static void apply(HTStyle *style, NSMutableAttributedString *r) { applyRange(style, r, NSMakeRange(0, r.length)); }

//	Check whether copying a style into a run will change it
//	-------------------------------------------------------

static BOOL willChange(HTStyle *style, NSTextStorage *r) {
    if (r->font != style->font)
        return YES;

    if (style->textRGBColor >= 0)
        if (r->textRGBColor != style->textRGBColor)
            return YES;

    if (style->textGray >= 0)
        if (r->textGray != style->textGray)
            return YES;

    if (style->paragraph) {
        if (r->paraStyle != style->paragraph)
            return YES;
    }
    if (style->anchor) {
        if (r->info != style->anchor)
            return YES;
    }
    return NO;
}

//	Update a style
//	--------------
//
//
- (void)updateStyle:(HTStyle *)style {
    NSArray<NSTextStorage *> *runs = self.textStorage.attributeRuns;
    for (NSTextStorage *run in runs) {
        NSParagraphStyle *paraStyle = [run paragraphStyle];
        if (paraStyle == style->paragraph) {
            apply(style, run);
        }
    }
    // TODO: Do we need this?
    // [self calcLine];
    [self.window display];
}

//	Delete an anchor from this node, without freeing it.
//	----------------
//
//
- disconnectAnchor:(Anchor *)anchor {
    NSArray<NSTextStorage *> *runs = self.textStorage.attributeRuns;
    for (NSTextStorage *run in runs) {
        Anchor *runAnchor = [run anchor];
        if (runAnchor == anchor) {
            [run setAnchor:nil];
            [run setColor:[NSColor blackColor]];
        }
    }
    [self.window display];
    return nil;
}

//	Find start of paragraph
//	-----------------------
//
//	Returns the position of the character after the newline, or 0.
//
- (NSUInteger)startOfParagraph:(NSUInteger)pos {
    NSString *text = self.string;

    for (NSUInteger i = pos; i > 0; i--) {
        if ([text characterAtIndex:(i - 1)] == '\n') {
            return i;
        }
    }

    return 0;
}

//	Find end of paragraph
//	-----------------------
//
//	Returns the position after the newline, or the length of the text.
//	Note that any number of trailing newline characters are included in
//	this paragraph .. basically because the text object does not support
//	the concept of space after or before paragraphs, so extra paragrpah
//	marks must be used.
//
- (NSUInteger)endOfParagraph:(NSUInteger)pos {
    NSString *text = self.string;

    for (NSUInteger i = pos + 1; i < text.length; i++) {
        if ([text characterAtIndex:i] == '\n') {
            return i + 1;
        }
    }

    return text.length;
}

//	Do two runs imply the same format?
//	----------------------------------

BOOL run_match(NSTextStorage *r1, NSTextStorage *r2) { return [r1 isEqualToAttributedString:r2]; }

//	Apply style to a given region
//	-----------------------------

- (HyperText *)applyStyle:(HTStyle *)style inRange:(NSRange)range {
    applyRange(style, self.textStorage, range);
    // TODO: Do we need this?
    // [self calcLine];          /* Update line breaks */
    [self.window display]; /* Update window */
    return self;
}

//	Apply a style to the selection
//	------------------------------
//
//	If the style is a paragraph style, the
//	selection is extended to encompass a number of paragraphs.
//
- (HyperText *)applyStyle:(HTStyle *)style {
    NSRange selection = self.selectedRange;
    if (TRACE)
        NSLog(@"Applying style %p to (%lu,%lu)\n", style, selection.location, selection.location + selection.length);

    if (selection.length == 0) {                                  /* No selection */
        return [self applyStyle:style inRange:NSMakeRange(0, 0)]; /* Apply to typing run */
    }

    if (!style)
        return nil;

    if ([self isEditable])
        [self.window setDocumentEdited:YES];
    else
        return nil;

    if (style->paragraph) { /* Extend to an integral number of paras. */
        selection.location = [self startOfParagraph:selection.location];
        selection.length = [self endOfParagraph:selection.location + selection.length] - selection.location;
    }
    return [self applyStyle:style inRange:selection];
}

//	Apply style to all similar text
//	-------------------------------
//
//
- applyToSimilar:(HTStyle *)style {
    NSRange selection = self.selectedRange;
    NSRange selectionRunRange = [self runRangeContainingSelection];
    NSArray<NSTextStorage *> *runs = self.textStorage.attributeRuns;
    NSTextStorage *oldRun = runs[selectionRunRange.location];

    if (TRACE)
        NSLog(@"Applying style %p to unstyled text similar to (%lu,%lu)\n", style, selection.location,
              selection.location + selection.length);

    for (NSTextStorage *run in runs) {
        // TODO: Are we okay with comparing identities of NSParagraphStyle * objects here?
        if ([run paragraphStyle] == [oldRun paragraphStyle]) {
            if (TRACE)
                NSLog(@"    Applying to run %@\n", run);
            apply(style, run);
        }
    }

    // TODO: Do we need this?
    // [self calcLine];
    [self.window display];
    return self;
}

//	Pick up the style of the selection
//	----------------------------------

- (HTStyle *)selectionStyle:(HTStyleSheet *)sheet {
    NSTextStorage *run = [self runContainingSelectionStart];
    return HTStyleForRun(sheet, run); /* for start of selection */
}

//	Another replaceSel method, this time using styles:
//	-------------------------------------------------
//
//	The style is as given, or where that is not defined, as the
//	current style of the selection.

- (void)replaceSel:(const char *)aString style:(HTStyle *)aStyle {
    [self setSelectedTextAttributes:attributesForStyle(aStyle)];
    [self replaceCharactersInRange:self.selectedRange withString:[NSString stringWithUTF8String:aString]];
}

//	Read in as Plain Text					readText:
//	---------------------
//
//	This method overrides the method of Text, so as to force a plain text
//	hypertext to be monofont and fixed width.  Also, the window is updated.
//
- readText:(NXStream *)stream {
    //    [self setMonoFont:YES];		Seems to leave it in a strange state
    [self setHorizontallyResizable:YES];
    [self setNoWrap];
    [self setFont:[NSFont fontWithName:@"Ohlfs" size:10.0]]; // @@ Should be XMP
    [super readText:stream];
    format = WWW_PLAINTEXT; // Remember

#ifdef NOPE
    {
        NSRect frm; /* Try this to get over "text strangeness" */
        frm = self.frame;
        [self renewRuns:NULL text:NULL frame:&frm tag:0];
    }
#endif
    [self adjustWindow];
    return self;
}

//	Read in as Rich Text					readRichText:
//	---------------------
//
//	This method overrides the method of Text, so as to force a plain text
//	hypertext to be monofont and fixed width.  Also, the window is updated.
//
- readRichText:(NXStream *)stream {
    id status = [super readRichText:stream];
    [self adjustWindow];
    format = WWW_RICHTEXT; // Remember
    return status;
}

//				Window Delegate Methods
//				=======================

//	Prevent closure of edited window without save
//
- (void)windowWillClose:(NSNotification *)notification {
    if (![self.window isDocumentEdited])
        return;
    NSInteger choice =
        NSRunAlertPanel(@"Close", @"Save changes to `%s'?", @"Yes", @"No", @"Don't close", [self.window title]);
    if (choice == NSAlertAlternateReturn || choice == NSAlertOtherReturn)
        return;
    [server saveNode:self];
}

//	Change configuration as window becomes key window
//
- (void)windowDidBecomeMain:(NSNotification *)notification {
    if ([self.delegate respondsToSelector:@selector(hyperTextDidBecomeMain:)]) {
        [((id<HyperTextDelegate>)self.delegate) hyperTextDidBecomeMain:self];
    }
}

/*				FORMAT CONVERSION FROM SGML
**				===========================
**
**	As much as possible, this is written in C for portability. It is in a separate
**	include file which could be used elsewhere.
*/
/*		Input procedure for printing a trace as we go
*/
#define NEXT_CHAR NXGetc(sgmlStream)
#define BACK_UP NXUngetc(sgmlStream)

/*	Globals for using many subroutines within a method
*/
static NXStream *sgmlStream;
static HyperText *HT; /* Pointer to self for C */

//	Inputting from the text object:
//	------------------------------

static unsigned char *read_pointer; /* next character to be read */
static unsigned char *read_limit;
static NXTextBlock *read_block;

void start_input() {
    read_block = HT->firstTextBlock;
    read_pointer = read_block->text; /* next character to be read */
    read_limit = read_pointer + read_block->chars;
}

unsigned char next_input_block() {
    char c = *read_pointer;
    read_block = read_block->next;
    if (!read_block)
        read_block = HT->firstTextBlock; /* @@@ FUDGE */
    read_pointer = read_block->text;
    read_limit = read_pointer + read_block->chars;
    return c;
}
#define START_INPUT start_input()
#define NEXT_TEXT_CHAR (read_pointer + 1 == read_limit ? next_input_block() : *read_pointer++)

//			Outputting to the text object
//			=============================
//
//	These macros are used by the parse routines
//
#define BLOCK_SIZE NX_TEXTPER /* Match what Text seems to use */

static NXTextBlock *write_block;     /* Pointer to block being filled */
static unsigned char *write_pointer; /* Pointer to next characetr to be written */
static unsigned char *write_limit;   /* Pointer to the end of the allocated area*/
static NSTextStorage *lastRun;       /* Pointer to the run being appended to */
static int original_length;          /* of text */

#define OUTPUT(c)                                                                                                      \
    {                                                                                                                  \
        *write_pointer++ = (c);                                                                                        \
        if (write_pointer == write_limit) {                                                                            \
            end_output();                                                                                              \
            append_start_block();                                                                                      \
        }                                                                                                              \
    }
#define OUTPUTS(string)                                                                                                \
    {                                                                                                                  \
        const char *p;                                                                                                 \
        for (p = (string); *p; p++)                                                                                    \
            OUTPUT(*p);                                                                                                \
    }
#define START_OUTPUT append_begin()
#define FINISH_OUTPUT finish_output()
#define LOADPLAINTEXT loadPlainText()
#define SET_STYLE(s) set_style(s)

//	Allocate a text block to accumulate text
//
// Bugs:
// It might seem logical to set the "malloced" bit to 1, because the text block
// has been allocted with malloc(). However, this crashes the program as at the
// next edit of the text, the text object frees the block while still using it.
// Chaos results, sometimes corrupting the stack and/or looping for ages. @@
// We therefore set it to zero! (This might have been something else -TBL)
//
void append_start_block(void) {
    NXTextBlock *previous_block = write_block; /* to previous write block */

    if (TRACE)
        NSLog(@"    Starting to append new block.\n");

    lastRun = ((NSTextStorage *)((char *)HT->theRuns->runs + HT->theRuns->chunk.used)) - 1;
    write_block = (NXTextBlock *)malloc(sizeof(*write_block));
    write_block->tbFlags.malloced = 0; /* See comment above */
    write_block->text = (unsigned char *)malloc(BLOCK_SIZE);
    write_block->chars = 0; // For completeness: not used.
    write_pointer = write_block->text;
    write_limit = write_pointer + BLOCK_SIZE;

    //	Add the block into the linked list after previous block:

    write_block->prior = previous_block;
    write_block->next = previous_block->next;
    if (write_block->next)
        write_block->next->prior = write_block;
    else
        HT->lastTextBlock = write_block;
    previous_block->next = write_block;
}

// 	Start the output process altogether
//
void append_begin(void) {
    if (TRACE)
        NSLog(@"Begin append to text.\n");

    [HT setText:""]; // Delete everything there
    original_length = HT->textLength;
    if (TRACE)
        NSLog(@"Text now contains %i characters\n", original_length);

    lastRun = ((NSTextStorage *)((char *)HT->theRuns->runs + HT->theRuns->chunk.used)) - 1;

    //	Use the last existing text block:

    write_block = HT->lastTextBlock;

    //	It seems that the Text object doesn't like to be empty: it always wants to
    //	have a newline in at leats. However, we need it seriously empty and so we
    //	forcible empty it. CalcLine will crash if called with it in this state.

    if (original_length == 1) {
        if (TRACE)
            NSLog(@"HT: Clearing out single character from Text.\n");
        lastRun->chars = 0;     /* Empty the run */
        write_block->chars = 0; /* Empty the text block */
        HT->textLength = 0;     /* Empty the whole Text object */
        original_length = 0;    /* Note we have cleared it */
    }

    write_pointer = write_block->text + write_block->chars;
    write_limit = write_pointer + BLOCK_SIZE;
}

//	Set a style for new text
//
void set_style(HTStyle *style) {
    if (!style) {
        if (TRACE)
            NSLog(@"set_style: style is null!\n");
        return;
    }
    if (TRACE)
        NSLog(@"    Changing to style `%s' -- %s change.\n", style->name,
              willChange(style, lastRun) ? "will" : "won't");
    if (willChange(style, lastRun)) {
        int size = (write_pointer - write_block->text);
        lastRun->chars = lastRun->chars + size - write_block->chars;
        write_block->chars = size;
        if (lastRun->chars) {
            int new_used = (((char *)(lastRun + 2)) - (char *)HT->theRuns->runs);
            if (new_used > HT->theRuns->chunk.allocated) {
                if (TRACE)
                    NSLog(@"    HT: Extending runs.\n");
                HT->theRuns = (NXRunArray *)NXChunkGrow(&HT->theRuns->chunk, new_used);
                lastRun = ((NSTextStorage *)((char *)HT->theRuns->runs + HT->theRuns->chunk.used)) - 1;
            }
            lastRun[1] = lastRun[0];
            lastRun++;
            HT->theRuns->chunk.used = new_used;
        }
        apply(style, lastRun);
        lastRun->chars = 0; /* For now */
    }
}

//	Transfer text to date to the Text object
//	----------------------------------------
void end_output(void) {
    int size = (write_pointer - write_block->text);
    if (TRACE)
        NSLog(@"    HT: Adding block of %i characters, starts: `%.20s...'\n", size, write_block->text);
    lastRun->chars = lastRun->chars + size - write_block->chars;
    write_block->chars = size;
    HT->textLength = HT->textLength + size;
}

//	Finish altogether
//	-----------------

void finish_output(void) {
    int size = write_pointer - write_block->text;
    if (size == 0) {
        HT->lastTextBlock = write_block->prior; /* Remove empty text block */
        write_block->prior->next = 0;
        free(write_block->text);
        free(write_block);
    } else {
        end_output();
    }

    // get rid of zero length run if any

    if (lastRun->chars == 0) { /* Chop off last run */
        HT->theRuns->chunk.used = (char *)lastRun - (char *)HT->theRuns;
    }

    //	calcLine requires that the last character be a newline!
    {
        unsigned char *p = HT->lastTextBlock->text + HT->lastTextBlock->chars - 1;
        if (*p != '\n') {
            if (TRACE)
                NSLog(@"HT: Warning: Last character was %i not newline: overwriting!\n", *p);
            *p = '\n';
        }
    }

    [HT adjustWindow]; /* Adjustscrollers and window size */
}

//	Loading plain text

void loadPlainText(void) {
    [HT setMonoFont:YES];
    [HT setHorizontallyResizable:YES];
    [HT setNoWrap];
    [HT readText:sgmlStream]; /* will read to end */
    [HT adjustWindow];        /* Fix scrollers */
}

//	Methods enabling an external parser to add styled data
//	------------------------------------------------------
//
//	These use the macros above in the same way as a built-in parser would.
//
- appendBegin {
    HT = self;
    START_OUTPUT;
    return self;
}

- appendStyle:(HTStyle *)style {
    SET_STYLE(style);
    return self;
}
- appendText:(const char *)text {
    OUTPUTS(text);
    return self;
}

- appendEnd {
    FINISH_OUTPUT;
    return self;
}

//	Begin an anchor

- (Anchor *)appendBeginAnchor:(const char *)name to:(const char *)reference {
    HTStyle *style = HTStyleNew();
    char *parsed_address;
    Anchor *a = *name ? [[Anchor alloc] initWithParent:nodeAnchor tag:name] : [self anchor];

    style->anchor = a;
    style->clearAnchor = NO;
    [(Anchor *)style->anchor isLastChild]; /* Put in correct order */
    if (*reference) {                      /* Link only if href */
        parsed_address = HTParse(reference, [nodeAnchor address], PARSE_ALL);
        [(Anchor *)(style->anchor) linkTo:[[Anchor alloc] initWithAddress:parsed_address]];
        free(parsed_address);
    }
    SET_STYLE(style); /* Start anchor here */
    free(style);
    return a;
}

- appendEndAnchor // End it
{
    HTStyle *style = HTStyleNew();
    style->anchor = nil;
    style->clearAnchor = YES;
    SET_STYLE(style); /* End anchor here */
    free(style);
    return self;
}

//	Reading from a NeXT stream
//	--------------------------

#define END_OF_FILE NXAtEOS(sgmlStream)
#define NEXT_CHAR NXGetc(sgmlStream)
#define BACK_UP NXUngetc(sgmlStream)

#include "ParseHTML.h"

//			Methods overriding Text methods
//			===============================
//
//	Respond to mouse events
//	-----------------------
//
// The first click will have set the selection point.  On the second click,
// we follow a link if possible, otherwise we allow Text to select a word as usual.
//
- mouseDown:(NSEvent *)theEvent {
    if (theEvent->data.mouse.click != 2)
        return [super mouseDown:theEvent];
    if (![self followLink])
        return [super mouseDown:theEvent];
    return self;
}

//	The following are necessary to undo damage done by the Text object
//	in version 2.0 of NeXTStep. For some reason, iff the "info" is
//	nonzero, text typed in is given
//	a different copy of the typingRun parastyle, and zero anchor info.
//	Otherwise, the current run is broken in two at the insertion point,
//	but no changes made to the run contents.
//	The problem with simply repairing is that many runs will be made inside
//	an anchor.
//	We have to use a "dummy" flag to mean "This has an anchor: be careful!"
//	This is horrible.

- keyDown:(NSEvent *)theEvent
#ifdef TRY1
{
    id result;
    NSParagraphStyle *typingPara = typingRun.paraStyle;
    int originalLength = textLength;
    int originalStart = sp0.cp;
    int originalEnd = spN.cp;
    result = [super keyDown:theEvent];

    {
        int inserted = originalEnd - originalStart + textLength - originalLength;

        if (TRACE)
            NSLog(@"KeyDown, size(sel) %i (%i-%i)before, %i (%i-%i)after.\n", originalLength, originalStart,
                  originalEnd, textLength, sp0.cp, spN.cp);

        if (inserted > 0) {
            NSTextStorage *s;
            int pos;
            int start = sp0.cp - inserted;
            for (pos = 0, s = theRuns->runs; pos + s->chars <= start; pos = pos + ((s++)->chars)) /*loop*/
                ;

            //	s points to run containing first char of insertion

            if (pos != start)
                NSLog(@"HT: Strange: inserted %i at %i, start of run=%i !!\n", inserted, start, pos);

            if (s > theRuns->runs) {       /* ie s-1 is valid */
                s->paraStyle = typingPara; /* Repair damage to runs */
                /* What about freeing the old paragraph style? @@ */
                s->info = (s - 1)->info;
                s->rFlags.dummy = 1; /* Pass on flag */
            }
        }
    }
    return result;
}
#else
//	The typingRun field does not seem to reliably reflect the
//	format which would be appropriate if typing were to occur.
//	We have to use our own.
{
    NXRun run;
    {
        NSTextStorage *s; /* To point to run BEFORE selection */
        int pos;

        /* 	If there is a nonzero selection, take the run containing the
**	first character. If the selection is empty, take the run containing the
**	character before the selection.
*/
        if (sp0.cp == spN.cp) {
            for (pos = 0, s = theRuns->runs; pos + s->chars < sp0.cp; /* Before */
                 pos = pos + ((s++)->chars))                          /*loop*/
                ;
        } else {
            for (pos = 0, s = theRuns->runs; pos + s->chars <= sp0.cp; /* First ch */
                 pos = pos + ((s++)->chars))                           /*loop*/
                ;
        }

        /*	Check our understanding */

        if (typingRun.paraStyle != 0) {
            if (typingRun.paraStyle != s->paraStyle)
                NSLog(@"WWW: Strange: Typing run has bad style.\n");
            if ((s->info != 0) && (typingRun.info != s->info))
                NSLog(@"WWW: Strange: Typing run has bad anchor info.\n");
        }

        typingRun = *s; /* Copy run to be used for insertion */
        run = *s;       /* save a copy */
    }

    if (!run.rFlags.dummy)
        return [super keyDown:theEvent]; // OK!

    {
        id result;
        int originalLength = textLength;
        int originalStart = sp0.cp;
        int originalEnd = spN.cp;
        result = [super keyDown:theEvent];

        /* 	Does it really change? YES!
*/
        if (TRACE) {
            if (typingRun.info != run.info)
                NSLog(@"Typing run info was %p, now %p !!\n", run.info, typingRun.info);
            if (typingRun.paraStyle != run.paraStyle)
                NSLog(@"Typing run paraStyle was %p, now %p !!\n", run.paraStyle, typingRun.paraStyle);
        }
        /*	Patch the new run if necessary:
*/
        {
            int inserted = originalEnd - originalStart + textLength - originalLength;

            if (TRACE)
                NSLog(@"KeyDown, size(sel) %i (%i-%i)before, %i (%i-%i)after.\n", originalLength, originalStart,
                      originalEnd, textLength, sp0.cp, spN.cp);

            if (inserted > 0) {
                NSTextStorage *s;
                int pos;
                int start = sp0.cp - inserted;
                for (pos = 0, s = theRuns->runs; pos + s->chars <= start; pos = pos + ((s++)->chars)) /*loop*/
                    ;

                //	s points to run containing first char of insertion

                if (pos != start) { /* insert in middle of run */
                    if (TRACE)
                        NSLog(@"HT: Inserted %i at %i, in run starting at=%i\n", inserted, start, pos);

                } else { /* inserted stuff starts run */
                    if (TRACE)
                        NSLog(@"Patching info from %d to %d\n", s->info, run.info);
                    s->info = run.info;
                    s->paraStyle = run.paraStyle; /* free old one? */
                    s->rFlags.dummy = 1;
                }
            } /* if inserted>0 */

        } /* block */
        return result;
    }
}
#endif
//	After paste, determine paragraph styles for pasted material:
//	------------------------------------------------------------

- paste:sender;
{
    id result;
    int originalLength = textLength;
    int originalStart = sp0.cp;
    int originalEnd = spN.cp;
    Anchor *typingInfo;

    result = [super paste:sender]; // Do the paste

    {
        int inserted = originalEnd - originalStart + textLength - originalLength;

        if (TRACE)
            NSLog(@"Paste, size(sel) %i (%i-%i)before, %i (%i-%i)after.\n", originalLength, originalStart, originalEnd,
                  textLength, sp0.cp, spN.cp);

        if (inserted > 0) {
            NSTextStorage *s, *r;
            int pos;
            int start = sp0.cp - inserted;
            for (pos = 0, s = theRuns->runs; pos + s->chars <= start; pos = pos + ((s++)->chars)) /*loop*/
                ;
            //		s points to run containing first char of insertion

            if (pos != sp0.cp - inserted)
                NSLog(@"HT paste: Strange: insert@%i != run@%i !!\n", start, pos);

            if (s > theRuns->runs)
                typingInfo = (s - 1)->info;
            else
                typingInfo = 0;

            for (r = s; pos + r->chars < sp0.cp; pos = pos + (r++)->chars) {
                r->paraStyle = HTStyleForRun(styleSheet, r)->paragraph;
                r->info = typingInfo;
            }
        }
    }

    return result;
}

@end
