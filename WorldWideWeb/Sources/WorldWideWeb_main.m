/*
 *     Generated by the NeXT Interface Builder.
 * 
 * History:
 *	27 Feb 91	Modified TBL to initialise NXArgv early on
 *	19 Mar 91	Page info deafults
 */

#import "HTUtils.h" /* TBL */
#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import <libc.h> /* TBL */
#import <stdlib.h>
#import <string.h> /* TBL */

// Exported global variables

int WWW_TraceFlag = 1; /* Global variable for whether trace output is enabled. */
NSString *appDirectory; /* Name of the directory containing the application */

int main(int argc, const char *argv[]) {
    // Cocoa port note: Some of the logic been moved to the AppDelegate, so we can use NSApplicationMain

    appDirectory = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/"];

    if (TRACE)
        NSLog(@"WWW: Run from %@", appDirectory);

    return NSApplicationMain(argc, argv);
}
