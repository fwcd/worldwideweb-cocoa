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

static int int_default(NSString *param) { return [[NSUserDefaults standardUserDefaults] integerForKey:param]; }

int main(int argc, char *argv[]) {
    //    NXArgc = argc;		/* TBL */
    //    NXArgv = argv;		/* TBL */

    char *p;

    NSDictionary<NSString *, id> *myDefaults = @{
        @"PaperType" : @"Letter", // Non-USA users will have to override
        @"LeftMargin" : @"72",    //  (72) Space for ring binding
        @"RightMargin" : @"36",   //  (72) Note printers need some margin
        @"TopMargin" : @"36",     // (108) All margins in points
        @"BottomMargin" : @"36",  // (108) PrintInfo defaults in brackets
    };

    appDirectory = malloc(strlen(argv[0]));
    strcpy(appDirectory, argv[0]);
    if (p = strrchr(appDirectory, '/'))
        p[1] = 0; /* Chop home directory after slash */
    if (TRACE)
        NSLog(@"WWW: Run from %s\n", appDirectory);

    [[NSUserDefaults standardUserDefaults] registerDefaults:myDefaults];

    NSArray *tl;
    [[NSBundle mainBundle] loadNibNamed:@"WorldWideWeb.nib" owner:NSApp topLevelObjects:&tl];

    //	The default margins seem to be 72, 72, 108, 108 which is a lot.
    {
        int leftM = int_default(@"LeftMargin");
        int rightM = int_default(@"RightMargin");
        int topM = int_default(@"TopMargin");
        int bottomM = int_default(@"BottomMargin");

        NSPrintInfo *pi = [NSPrintInfo sharedPrintInfo];
        // TOOD: Is paper name the equivalent of paper type?
        [pi setPaperName:[[NSUserDefaults standardUserDefaults] stringForKey:@"PaperType"]];
        [pi setVerticallyCentered:NO];
        [pi setLeftMargin:leftM];
        [pi setRightMargin:rightM];
        [pi setTopMargin:topM];
        [pi setBottomMargin:bottomM];
    }

    [NSApp run];
    return 0;
}
