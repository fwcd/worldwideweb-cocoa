//
//  AppDelegate.m
//  WorldWideWeb
//
//  Created on 20.05.24
//

#import "AppDelegate.h"

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import <libc.h> /* TBL */
#import <stdlib.h>
#import <string.h> /* TBL */

@interface AppDelegate ()

@property(strong) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    NSDictionary<NSString *, id> *myDefaults = @{
        @"PaperType" : @"Letter", // Non-USA users will have to override
        @"LeftMargin" : @"72",    //  (72) Space for ring binding
        @"RightMargin" : @"36",   //  (72) Note printers need some margin
        @"TopMargin" : @"36",     // (108) All margins in points
        @"BottomMargin" : @"36",  // (108) PrintInfo defaults in brackets
    };

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults registerDefaults:myDefaults];

    //    The default margins seem to be 72, 72, 108, 108 which is a lot.
    {
        NSInteger leftM = [defaults integerForKey:@"LeftMargin"];
        NSInteger rightM = [defaults integerForKey:@"RightMargin"];
        NSInteger topM = [defaults integerForKey:@"TopMargin"];
        NSInteger bottomM = [defaults integerForKey:@"BottomMargin"];

        NSPrintInfo *pi = [NSPrintInfo sharedPrintInfo];
        // TOOD: Is paper name the equivalent of paper type?
        [pi setPaperName:[[NSUserDefaults standardUserDefaults] stringForKey:@"PaperType"]];
        [pi setVerticallyCentered:NO];
        [pi setLeftMargin:leftM];
        [pi setRightMargin:rightM];
        [pi setTopMargin:topM];
        [pi setBottomMargin:bottomM];
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

@end
