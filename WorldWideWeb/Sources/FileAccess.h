
/* Generated by Interface Builder */

#pragma once

#import "HyperAccess.h"
#import "HyperManager.h"

@interface FileAccess : HyperAccess {
}

+ initialize;

- (IBAction)saveAs:sender;
- (IBAction)saveAsRichText:sender;
- (IBAction)saveAsPlainText:sender;
- (Anchor *)makeNewNode:sender;
- (IBAction)makeNew:sender;
- (IBAction)linkToNew:sender;
- (IBAction)linkToFile:sender;
- (Anchor *)openMy:(const char *)filename diagnostic:(int)diagnostic;
- (IBAction)goHome:sender;
@end
