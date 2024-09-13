//	HyperText Access method manager Object			HyperManager.m
//	--------------------------------------
//
//	It is the job of a hypermanager to keep track of all the HyperAccess modules
//	which exist, and to pass on to the right one a general request.
//
// History:
//	   Oct 90	Written TBL
//
#import "HyperManager.h"
#import "FileAccess.h"
#import "HTParse.h"
#import "HTUtils.h"
#import "HyperText.h"
#import "WWWPageLayout.h"
#import <AppKit/AppKit.h>

@implementation HyperManager

#define THIS_TEXT (HyperText *)[[[NSApp mainWindow] contentView] documentView]

extern char *WWW_nameOfFile(const char *name); /* In file access */

/*	Exported to everyone */

int WWW_TraceFlag;  /* Exported to everyone */
char *appDirectory; /* Name of the directory containing the application */

/*	Private to this module
*/
PRIVATE FileAccess *fileAccess = nil;

- init {
    self = [super init];
    accesses = [NSMutableArray new]; // Create and clear list
    return self;
}

- (IBAction)traceOn:sender {
    WWW_TraceFlag = 1;
}
- (IBAction)traceOff:sender {
    WWW_TraceFlag = 0;
}

- manager {
    return nil;
} // we have no manager
- setManager {
    return nil;
} // we have no manager

- (const char *)name {
    return "any";
}

//			Access Management functions
//
- (void)registerAccess:(HyperAccess *)access {
    if (!accesses)
        accesses = [NSMutableArray new];
    if (TRACE)
        NSLog(@"HyperManager: Registering access `%s'.", [access name]);
    if (0 == strcmp([access name], "file"))
        fileAccess = (FileAccess *)access; /* We need that one */
    [accesses addObject:access];
}

//	Load an anchor from some access				loadAnchor:
//	-------------------------------
//
//	This implementation simply looks for an access with the right name.
//	It also checks whether in fact the anchor
//	is already loaded and linked, and that the address string is not null.
//
// On exit:
//	If a duplicate node is found, that anchor is returned
//	If there is no success, nil is returned.
//	Otherwise, the anchor is returned.

- loadAnchor:(Anchor *)anAnchor Diagnostic:(int)diagnostic {

    char *s = 0;
    const char *addr;
    int i;
    HyperAccess *access;

    if ([anAnchor node]) {
        return [[anAnchor node] nodeAnchor]; /* Already loaded and linked. */
        if (TRACE)
            NSLog(@"HyperManger: Anchor already has a node.");
    }

    addr = [anAnchor address];
    if (!addr) {
        if (TRACE)
            NSLog(@"HyperManger: Anchor has no address - can't load it.");
        return nil; /* No address? Can't load it. */
    }

    if (TRACE)
        NSLog(@"HyperManager: Asked for `%s'", addr);

    s = HTParse(addr, "", PARSE_ACCESS);
    for (i = 0; i < [accesses count]; i++) {
        access = [accesses objectAtIndex:i];
        if (0 == strcmp(s, [access name])) {
            id status;
            HyperText *HT;
            if (TRACE)
                NSLog(@"AccessMgr: Loading `%s' using `%s' access.", [anAnchor address], [access name]);
            free(s);
            status = [access loadAnchor:anAnchor Diagnostic:diagnostic];
            if (!status)
                return nil;

            //	The node may have become an index: update the existence
            //   state of the panel.

            HT = [anAnchor node];
            if ([HT isIndex]) {
                [[self.keywords window] makeKeyAndOrderFront:self];
            } else {
                [[self.keywords window] close];
                //		[[self.keywords window] orderOut:self];    @@ bug?
            }

            return status;
        }
    }

    //	Error: No access. Print useful error message.

    {
        NSString *got = @"";

        for (i = 0; i < [accesses count]; i++) {
            got = [NSString stringWithFormat:@"%@%@: ", got, [[accesses objectAtIndex:i] name]];
        }

        NSString *message;

        if (*s) {
            message =
                [NSString stringWithFormat:@"Invalid access prefix for `%s'\n    Can be one of %@ but not `%s:'.\n",
                                           [anAnchor address], got, s];
        } else {
            message = [NSString stringWithFormat:@"No access prefix specified for `%s'\n    Accesses are: %@ .\n",
                                                 [anAnchor address], got];
        }

        NSLog(@"%@", message);

        NSAlert *alert = [[NSAlert alloc] init];
        [alert setInformativeText:message];
        [alert runModal];
    }
    free(s);
    return nil;
}

//______________________________________________________________________________

//	Open or search  by name
//	-----------------------
//
//
- (Anchor *)accessName:(const char *)arg Diagnostic:(int)diagnostic {
    return [[[Anchor alloc] initWithAddress:arg] selectDiagnostic:diagnostic];
}

//	Search with a given diagnostic level
//
//	This involves making a special address string, being the index address
//	with a ? sign followed by a "+" separated list of keywords.
//
- searchDiagnostic:(int)diagnostic {
    char addr[256];
    char keys[256];
    char *p, *q;
    HyperText *HT = THIS_TEXT;
    if (!HT)
        return nil;
    strcpy(addr, [[HT nodeAnchor] address]);
    if ((p = strchr(addr, '?')) != 0)
        *p = 0; /* Chop off existing search string */
    strcat(addr, "?");
    strcpy(keys, [[[self.keywords cellAtIndex:0] stringValue] UTF8String]);
    q = HTStrip(keys); /* Strip leading and trailing */
    for (p = q; *p; p++)
        if (WHITE(*p)) {
            *p = '+'; /* Separate with plus signs */
            while (WHITE(p[1]))
                p++; /* Skip multiple blanks */
            if (p[1] == 0)
                *p = 0; /* Chop a single trailing space */
        }
    strcat(addr, keys); /* Make combined node name */
    return [self accessName:HTStrip(addr) Diagnostic:diagnostic];
}

//				N A V I G A T I O N

//	Realtive moves
//	--------------
//
//	These navigate around the web as though it were a tree, from the point of
//	view of the user's browsing order.

- (IBAction)back:sender {
    [Anchor back];
}
- (IBAction)next:sender {
    [Anchor next];
}
- (IBAction)previous:sender {
    [Anchor previous];
}

//	@@ Note: the following 2 methods are duplicated (virtually) in FileAccess.m
//	and should not be here.

//	Go Home
//	-------
//
//	This accesses the default page of text for the user or, failing that,
//	for the system.
//
- (IBAction)goHome:sender {
    [fileAccess openMy:"default.html" diagnostic:0];
}

//	Load Help information
//	---------------------
//
//
- (IBAction)help:sender {
    [fileAccess openMy:"help.html" diagnostic:0];
}

//	Go to the Blank Page
//	--------------------
//
//
- (IBAction)goToBlank:sender {
    [fileAccess openMy:"blank.html" diagnostic:0];
}

//				Application Delegate Methods
//				============================

//	On Initialisation, Load Initial File
//	------------------------------------

- (void)appDidInit:sender {
    if (TRACE)
        NSLog(@"HyperManager: appDidInit");

    //    StrAllocCopy(appDirectory, NXArgv[0]);
    //    if (p = strrchr(appDirectory, '/')) p[1]=0;	/* Chop home slash */
    //    if (TRACE) NSLog(@"WWW: Run from %s", appDirectory);

    [Anchor setManager:self];
    [self goHome:self];
}

//	Accept that we can open files from the workspace

- (BOOL)appAcceptsAnotherFile:sender {
    return YES;
}

//	Open file from the Workspace
//
- (int)appOpenFile:(const char *)filename type:(const char *)aType {
    char *name = WWW_nameOfFile(filename);
    HyperText *HT = [self accessName:name Diagnostic:0];
    free(name);
    return (HT != 0);
}

//	Open Temporary file
//
//	@@ Should unlink(2) the file when we have done with it!

- (int)appOpenTempFile:(const char *)filename type:(const char *)aType {
    char *name = WWW_nameOfFile(filename); /* No host */
    HyperText *HT = [self accessName:name Diagnostic:0];
    free(name);
    return (HT != 0);
}

//		Actions:
//		-------
- (IBAction)search:sender {
    [self searchDiagnostic:0];
}

- (IBAction)searchRTF:sender {
    [self searchDiagnostic:1];
}

- (IBAction)searchSGML:sender {
    [self searchDiagnostic:2];
}

//	Direct open buttons:

- (IBAction)open:sender {
    [self accessName:[[[self.openString cellAtIndex:0] stringValue] UTF8String] Diagnostic:0];
}

- (IBAction)linkToString:sender {
    [THIS_TEXT linkSelTo:[[Anchor alloc] initWithAddress:[[[self.openString cellAtIndex:0] stringValue] UTF8String]]];
}

- (IBAction)openRTF:sender {
    [self accessName:[[[self.openString cellAtIndex:0] stringValue] UTF8String] Diagnostic:1];
}

- (IBAction)openSGML:sender {
    [self accessName:[[[self.openString cellAtIndex:0] stringValue] UTF8String] Diagnostic:2];
}

//	Save a hypertext back to its original server
//	--------------------------------------------
- save:sender {
    HyperText *HT = THIS_TEXT;
    id status = [(HyperAccess *)[HT server] saveNode:HT];
    if (status)
        [[HT window] setDocumentEdited:NO];
    return status;
}

//	Save all hypertexts back
//	-------------------------

- saveAll:sender {
    NSArray *windows = [NSApp windows];
    id cv;
    int i;
    int n = [windows count];

    for (i = 0; i < n; i++) {
        NSWindow *w = [windows objectAtIndex:i];
        if (cv = [w contentView])
            if ([cv respondsToSelector:@selector(documentView)])
                if ([w isDocumentEdited]) {
                    HyperText *HT = [[w contentView] documentView];
                    if ([(HyperAccess *)[HT server] saveNode:HT])
                        [w setDocumentEdited:NO];
                }
    }

    return self;
}

//	Close all unedited windows except this one
//	------------------------------------------
//

- (IBAction)closeOthers:sender {
    NSWindow *thisWindow = [NSApp mainWindow];
    NSArray *windows = [NSApp windows];

    {
        int i;
        id cv; // Content view
        int n = [windows count];
        for (i = 0; i < n; i++) {
            NSWindow *w = [windows objectAtIndex:i];
            if (w != thisWindow)
                if (cv = [w contentView])
                    if ([cv respondsToSelector:@selector(documentView)]) {
                        if (![w isDocumentEdited]) {
                            if (TRACE)
                                NSLog(@" Closing window %p", w);
                            [w performClose:self];
                        }
                    }
        }
    }
}

//	Print Postscript code for the main window
//	-----------------------------------------

- (IBAction)print:sender {
    // TODO: Figure out how we could implement this
    // [THIS_TEXT printPSCode:sender];
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"PostScript printing is not supported!";
    [alert addButtonWithTitle:@"Ok"];
    [alert runModal];
}

//	Run the page layout panel
//
- (IBAction)runPagelayout:sender {
    NSPageLayout *pl = [WWWPageLayout new];
    [pl runModal];
}

//	Set the title of the main window
//	--------------------------------

- (IBAction)setTitle:sender {
    NSWindow *thisWindow = [NSApp mainWindow];
    [thisWindow setTitle:[[self.titleString cellAtIndex:0] stringValue]];
    [thisWindow setDocumentEdited:YES];
}

//	Inspect Link
//	------------

- (IBAction)inspectLink:sender {
    Anchor *source = [THIS_TEXT selectedLink];
    Anchor *destination;
    if (!source) {
        [[self.openString cellAtIndex:0] setStringValue:@"(No anchor selected in main document.)"];
        return;
    }
    {
        char *source_address = [source fullAddress];
        [self.addressString setStringValue:[NSString stringWithUTF8String:source_address]];
        free(source_address);
    }

    destination = [source destination];
    if (destination) {
        char *destination_address = [destination fullAddress];
        [[self.openString cellAtIndex:0] setStringValue:[NSString stringWithUTF8String:destination_address]];
        free(destination_address);
    } else {
        [[self.openString cellAtIndex:0] setStringValue:@"Anchor not linked."];
    }
}

//	Copy address of document
//	------------------------
- (IBAction)copyAddress:sender {
    [[self.openString cellAtIndex:0] setStringValue:[NSString stringWithUTF8String:[[THIS_TEXT nodeAnchor] address]]];
}

//		HyperText delegate methods
//		==========================
//
//	This one has been passed from a window
//	to the hypertext which is its delegate,
//	to the access server module of that hypertext,
//	to this access manager.
//
// When a hypertext windown becomes a key window, the search
// panel is turned on or off depending on whether a search can be done,
// and the default address in the "open using full reference" panel
// is set to the address of the current hypertext.
//
- (void)hyperTextDidBecomeMain:(HyperText *)sender {
    if ([sender isIndex]) {
        [[self.keywords window] makeKeyAndOrderFront:self];
    } else {
        [[self.keywords window] close];
        //        [[keywords window] orderOut:self];	bug?
    }
    [[self.titleString cellAtIndex:0] setStringValue:[[sender window] title]];
    [self.addressString setStringValue:[NSString stringWithUTF8String:[[sender nodeAnchor] address]]];
    //  [openString setStringValue: [[sender nodeAnchor] address] at:0];
}

//	Panel delegate methods
//
//	The only windows to which this object is a delegate
//	are the open and search panels. When they become key,
//	we ensure that the text is selected.

- (void)windowDidBecomeKey:(NSNotification *)notification {
    id sender = notification.object;
    if (sender == [self.openString window])
        [self.openString selectTextAtIndex:0]; // Preselect the text
    else if (sender == [self.keywords window])
        [self.keywords selectTextAtIndex:0]; // Preselect the text
}
@end
