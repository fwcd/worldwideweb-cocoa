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

extern char *appDirectory; /* Name of the directory containing the application */

int main(int argc, const char *argv[]) {
    // Cocoa port note: Some of the logic been moved to the AppDelegate, so we can use NSApplicationMain

    char *p;

    appDirectory = malloc(strlen(argv[0]));
    strcpy(appDirectory, argv[0]);
    if ((p = strrchr(appDirectory, '/')))
        p[1] = 0; /* Chop home directory after slash */
    if (TRACE)
        NSLog(@"WWW: Run from %s", appDirectory);

    return NSApplicationMain(argc, argv);
}
