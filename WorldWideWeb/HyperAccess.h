//	A HyperAccess object provides access to hyperinformation, using particular
//	protocols and data format transformations.

// History:
//	26 Sep 90	Written TBL

#pragma once

#import "Anchor.h"
#import "HyperText.h"
#import <Foundation/Foundation.h>

@interface HyperAccess : NSObject {
    id manager; // The object which manages different access mechanisms.
}

//	Target variables for interface builder hookups:

@property(nonatomic) id contentSearch;
@property(nonatomic) IBOutlet NSForm *openString;
@property(nonatomic) IBOutlet NSForm *titleString;
@property(nonatomic) IBOutlet NSForm *keywords;
@property(nonatomic) IBOutlet NSTextField *addressString;

//  Interface builder initialisation methods:

- setManager:anObject;

//	Action methods for buttons etc:

- search:sender;
- searchRTF:sender;
- searchSGML:sender;

- open:sender;
- openRTF:sender;
- openSGML:sender;
- saveNode:(HyperText *)aText;

//	Calls form other code:

- manager;
- (const char *)name;                           // Name for this access method
- loadAnchor:(Anchor *)a;                       // Loads an anchor.
- loadAnchor:(Anchor *)a Diagnostic:(int)level; // Loads an anchor.

//	Text delegate methods:

- textDidChange:textObject;
- (BOOL)textWillChange:textObject;

//	HyperText delegate methods:

- hyperTextDidBecomeMain:sender;

@end
