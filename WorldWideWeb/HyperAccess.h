//	A HyperAccess object provides access to hyperinformation, using particular
//	protocols and data format transformations.

// History:
//	26 Sep 90	Written TBL

#pragma once

#import "Anchor.h"
#import "HyperText.h"
#import "HyperTextDelegate.h"
#import <Foundation/Foundation.h>

@interface HyperAccess : NSObject <HyperTextDelegate>

//	Target variables for interface builder hookups:

@property(nonatomic) IBOutlet id manager; // The object which manages different access mechanisms.
@property(nonatomic) id contentSearch;
@property(nonatomic) IBOutlet NSForm *openString;
@property(nonatomic) IBOutlet NSForm *titleString;
@property(nonatomic) IBOutlet NSForm *keywords;
@property(nonatomic) IBOutlet NSTextField *addressString;

//  Overridden setter

- (void)setManager:anObject;

//	Action methods for buttons etc:

- (IBAction)search:sender;
- (IBAction)searchRTF:sender;
- (IBAction)searchSGML:sender;

- (IBAction)open:sender;
- (IBAction)openRTF:sender;
- (IBAction)openSGML:sender;
- (id)saveNode:(HyperText *)aText;

//	Calls form other code:

- manager;
- (const char *)name;                           // Name for this access method
- loadAnchor:(Anchor *)a;                       // Loads an anchor.
- loadAnchor:(Anchor *)a Diagnostic:(int)level; // Loads an anchor.

//	Text delegate methods:

- textDidChange:textObject;
- (BOOL)textWillChange:textObject;

//	HyperText delegate methods:

- (void)hyperTextDidBecomeMain:(HyperText *)sender;

@end
