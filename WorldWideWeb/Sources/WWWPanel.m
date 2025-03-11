//
//  WWWPanel.m
//  WorldWideWeb
//
//  Created on 11.03.25
//

#import "WWWPanel.h"

@implementation WWWPanel

- (void)close {
    // Hide the panel instead of closing it
    [self orderOut:self];
}

@end
