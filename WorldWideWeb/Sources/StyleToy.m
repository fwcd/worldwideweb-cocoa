/*	Style Toy:	Allows user manipulation of styles	StyleToy.m
**	---------	----------------------------------
*/

#import "StyleToy.h"
#import "HTParse.h"
#import "HTStyle.h"
#import "HTUtils.h"
#import "NXShims.h"

#import "HyperText.h"
#define THIS_TEXT (HyperText *)[[[NSApp mainWindow] contentView] documentView]

/*	Field numbers in the parameter form:
*/
#define SGMLTAG_FIELD 4
#define FONT_NAME_FIELD 2
#define FONT_SIZE_FIELD 3
#define FIRST_INDENT_FIELD 0
#define SECOND_INDENT_FIELD 1

@implementation StyleToy

extern NSString *appDirectory; /* Pointer to directory for application */

//	Global styleSheet available to every one:

HTStyleSheet *styleSheet = 0;

static HTStyle *style;          /* Current Style */
static NSOpenPanel *open_panel; /* Keep the open panel alive */
static NSSavePanel *save_panel; /* Keep a Save panel too */

//	Create new one:

- init {
    self = [super init];
    [self loadDefaultStyleSheet];
    return self;
}

//			ACTION METHODS
//			==============

//	Display style in the panel

- display_style {
    if (style->name)
        [(NSFormCell *)[self.NameForm cellAtIndex:0] setStringValue:[NSString stringWithUTF8String:style->name]];
    else
        [(NSFormCell *)[self.NameForm cellAtIndex:0] setStringValue:@""];

    if (style->SGMLTag)
        [(NSFormCell *)[self.ParameterForm cellAtIndex:SGMLTAG_FIELD]
            setStringValue:[NSString stringWithCString:style->SGMLTag encoding:NSUTF8StringEncoding]];
    else
        [(NSFormCell *)[self.ParameterForm cellAtIndex:SGMLTAG_FIELD] setStringValue:@""];

    [(NSFormCell *)[self.ParameterForm cellAtIndex:FONT_NAME_FIELD] setStringValue:[style->font fontName]];

    [(NSFormCell *)[self.ParameterForm cellAtIndex:FONT_SIZE_FIELD] setFloatValue:style->fontSize];

    if (style->paragraph) {
        char tabstring[255];
        [(NSFormCell *)[self.ParameterForm cellAtIndex:FIRST_INDENT_FIELD]
            setFloatValue:style->paragraph.firstLineHeadIndent];
        [(NSFormCell *)[self.ParameterForm cellAtIndex:SECOND_INDENT_FIELD] setFloatValue:style->paragraph.headIndent];
        tabstring[0] = 0;
        for (NSTextTab *tab in style->paragraph.tabStops) {
            sprintf(tabstring + strlen(tabstring), "%.0f ", tab.location);
        }
        [(NSFormCell *)[self.TabForm cellAtIndex:0] setStringValue:[NSString stringWithUTF8String:tabstring]];
    }
    return self;
}

//	Load style from Panel
//
//	@@ Tabs not loaded

- load_style {
    char *name = 0;
    char *stripped;

    style->fontSize = [(NSFormCell *)[self.ParameterForm cellAtIndex:FONT_SIZE_FIELD] floatValue];
    StrAllocCopy(name, [[(NSFormCell *)[self.NameForm cellAtIndex:0] stringValue] UTF8String]);
    stripped = HTStrip(name);
    if (*stripped) {
        NSFont *font;
        font = [NSFont fontWithName:[NSString stringWithUTF8String:stripped] size:style->fontSize];
        if (font)
            style->font = font;
    }
    free(name);
    name = 0;

    StrAllocCopy(name, [[(NSFormCell *)[self.ParameterForm cellAtIndex:SGMLTAG_FIELD] stringValue] UTF8String]);
    stripped = HTStrip(name);
    if (*stripped) {
        StrAllocCopy(style->SGMLTag, stripped);
    }
    free(name);
    name = 0;

    if (!style->paragraph)
        style->paragraph = [[NSMutableParagraphStyle alloc] init];
    style->paragraph.firstLineHeadIndent =
        [(NSFormCell *)[self.ParameterForm cellAtIndex:FIRST_INDENT_FIELD] floatValue];
    style->paragraph.headIndent = [(NSFormCell *)[self.ParameterForm cellAtIndex:SECOND_INDENT_FIELD] floatValue];

    return self;
}

//	Open a style sheet from a file
//	------------------------------
//
//	We overlay any previously defined styles with new ones, but leave
//	old ones which are not redefined.

- (IBAction)open:sender {
    NXStream *s;                                   //	The file stream
    NSString *filename;                            //	The name of the file
    NSArray<NSString *> *typelist = @[ @"style" ]; //	Extension must be ".style."

    if (!open_panel) {
        open_panel = [NSOpenPanel new];
        [open_panel setAllowsMultipleSelection:NO];
    }

    if (![open_panel runModalForTypes:typelist]) {
        if (TRACE)
            NSLog(@"No file selected.");
        return;
    }

    filename = [open_panel filename];

    if (!styleSheet)
        styleSheet = HTStyleSheetNew();
    StrAllocCopy(styleSheet->name, [filename UTF8String]);

    s = NXOpenFile(styleSheet->name, NX_READONLY);
    if (!s) {
        if (TRACE)
            NSLog(@"Styles: Can't open file %@", filename);
        return;
    }
    if (TRACE)
        NSLog(@"Stylesheet: New one called %s.", styleSheet->name);
    (void)HTStyleSheetRead(styleSheet, s);
    NXClose(s);
    style = styleSheet->styles;
    [self display_style];
}

//	Load default style sheet
//	------------------------
//
//	We load EITHER the user's style sheet (if it exists) OR the system one.
//	This saves a bit of time on load. An alternative would be to load the
//	system style sheet and then overload the styles in the user's, so that
//	he could redefine a subset only of the styles.
//	If the HOME directory is defined, then it is always used a the
//	style sheet name, so that any changes will be saved in the user's
//	$(HOME)/WWW directory.

- (void)loadDefaultStyleSheet {
    NXStream *stream;

    if (!styleSheet)
        styleSheet = HTStyleSheetNew();
    styleSheet->name = malloc([appDirectory lengthOfBytesUsingEncoding:NSUTF8StringEncoding] + 13 + 1);
    strcpy(styleSheet->name, appDirectory.UTF8String);
    strcat(styleSheet->name, "default.style");

    if (getenv("HOME")) {
        char name[256];
        strcpy(name, getenv("HOME"));
        strcat(name, "/WWW/default.style");
        StrAllocCopy(styleSheet->name, name);
        stream = NXOpenFile(name, NX_READONLY);
    } else
        stream = 0;

    if (!stream) {
        char name[256];
        strcpy(name, appDirectory.UTF8String);
        strcat(name, "default.style");
        if (TRACE)
            NSLog(@"Couldn't open $(HOME)/WWW/default.style");
        stream = NXOpenFile(name, NX_READONLY);
        if (!stream)
            NSLog(@"Couldn't open %s, errno=%i", name, errno);
    }

    if (stream) {
        (void)HTStyleSheetRead(styleSheet, stream);
        NXClose(stream);
        style = styleSheet->styles;
        [self display_style];
    }
}

//	Save style sheet to a file
//	--------------------------

- (IBAction)saveAs:sender {
    NXStream *s; //	The file stream
    NSString *slash;
    int status;
    NSString *suggestion = 0; //	The name of the file to suggest
    NSString *filename;       //	The name chosen

    if (!save_panel) {
        save_panel = [NSSavePanel new]; //	Keep between invocations
    }

    suggestion = [NSString stringWithUTF8String:styleSheet->name];
    slash = [suggestion lastPathComponent];
    if (slash) {
        suggestion = [suggestion stringByDeletingLastPathComponent];
        status = [save_panel runModalForDirectory:suggestion file:slash];
    } else {
        status = [save_panel runModalForDirectory:@"." file:suggestion];
    }

    if (!status) {
        if (TRACE)
            NSLog(@"No file selected.");
        return;
    }

    filename = [save_panel filename];
    StrAllocCopy(styleSheet->name, [filename UTF8String]);
    s = NXOpenFile(styleSheet->name, NX_WRITEONLY);
    if (!s) {
        if (TRACE)
            NSLog(@"Styles: Can't open file %@ for write", filename);
        return;
    }
    if (TRACE)
        NSLog(@"StylestyleSheet: Saving as `%s'.", styleSheet->name);
    (void)HTStyleSheetWrite(styleSheet, s);
    NXClose(s);
    style = styleSheet->styles;
    [self display_style];
}

//	Move to next style
//	------------------

- (IBAction)NextButton:sender {
    if (styleSheet->styles)
        if (styleSheet->styles->next)
            if (style->next) {
                style = style->next;
            } else {
                style = styleSheet->styles;
            }
    [self display_style];
}

- (IBAction)FindUnstyledButton:sender {
    [THIS_TEXT selectUnstyled:styleSheet];
}

//	Apply current style to selection
//	--------------------------------

- (IBAction)ApplyButton:sender {
    [THIS_TEXT applyStyle:style];
}

- applyStyleNamed:(const char *)name {
    HTStyle *thisStyle = HTStyleNamed(styleSheet, name);
    if (!thisStyle)
        return nil;
    return [THIS_TEXT applyStyle:thisStyle];
}

- (IBAction)heading1Button:sender {
    [self applyStyleNamed:"Heading1"];
}
- (IBAction)heading2Button:sender {
    [self applyStyleNamed:"Heading2"];
}
- (IBAction)heading3Button:sender {
    [self applyStyleNamed:"Heading3"];
}
- (IBAction)heading4Button:sender {
    [self applyStyleNamed:"Heading4"];
}
- (IBAction)heading5Button:sender {
    [self applyStyleNamed:"Heading5"];
}
- (IBAction)heading6Button:sender {
    [self applyStyleNamed:"Heading6"];
}
- (IBAction)normalButton:sender {
    [self applyStyleNamed:"Normal"];
}
- (IBAction)addressButton:sender {
    [self applyStyleNamed:"Address"];
}
- (IBAction)exampleButton:sender {
    [self applyStyleNamed:"Example"];
}
- (IBAction)listButton:sender {
    [self applyStyleNamed:"List"];
}
- (IBAction)glossaryButton:sender {
    [self applyStyleNamed:"Glossary"];
}

//	Move to previous style
//	----------------------

- (IBAction)PreviousButton:sender {
    HTStyle *scan;
    for (scan = styleSheet->styles; scan; scan = scan->next) {
        if ((scan->next == style) || (scan->next == 0)) {
            style = scan;
            break;
        }
    }
    [self display_style];
}

- (IBAction)SetButton:sender {
    [self load_style];
    [THIS_TEXT updateStyle:style];
}

- (IBAction)PickButton:sender {
    HTStyle *st = [THIS_TEXT selectionStyle:styleSheet];
    if (st) {
        style = st;
        [self display_style];
    }
}

- (IBAction)ApplyToSimilar:sender {
    [THIS_TEXT applyToSimilar:style];
}

@end
