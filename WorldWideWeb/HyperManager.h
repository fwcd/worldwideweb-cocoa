//	HyperText Access method manager Object			HyperManager.h
//	--------------------------------------
//
//	It is the job of a hypermanager to keep track of all the HyperAccess modules
//	which exist, and to pass on to the right one a general request.
//
// History:
//	   Oct 90	Written TBL
//

#pragma once

#import <AppKit/AppKit.h>
#import "HyperAccess.h"

@interface HyperManager : HyperAccess <NSWindowDelegate>

{
    NSMutableArray *accesses;
}

- (IBAction)traceOn:sender;       // Diagnostics: Enable output to console
- (IBAction)traceOff:sender;      //	Disable output to console
- (void)registerAccess:anObject;  //	Register a subclass of HyperAccess
- (IBAction)back:sender;          // Return whence we came
- (IBAction)next:sender;          //	Take link after link taken to get here
- (IBAction)previous:sender;      //	Take link before link taken to get here
- (IBAction)goHome:sender;        //	Load the home node
- (IBAction)goToBlank:sender;     //	Load the blank page
- (IBAction)help:sender;          //	Go to help page
- (IBAction)closeOthers:sender;   //	Close unedited windows
- (IBAction)save:sender;          //	Save main window's document
- (IBAction)inspectLink:sender;   //	Look at the selected link
- (IBAction)copyAddress:sender;   //	Pick up the URL of the current document
- (IBAction)linkToString:sender;  //	Make link to open string
- (IBAction)saveAll:sender;       //	Save back all modified windows
- (IBAction)setTitle:sender;      //	Set the main window's title
- (IBAction)print:sender;         //	Print the main window
- (IBAction)runPagelayout:sender; //	Run the page layout panel for the app.

- (void)windowDidBecomeKey:(NSNotification *)sender; //	Window delegate method

@end
