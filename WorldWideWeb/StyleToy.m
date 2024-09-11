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

extern char *appDirectory; /* Pointer to directory for application */

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

//	Set connections to other objects:

- setTabForm:(NSForm *)anObject {
    TabForm = anObject;
    return self;
}

- setParameterForm:(NSForm *)anObject {
    ParameterForm = anObject;
    return self;
}

- setStylePanel:anObject {
    StylePanel = anObject;
    return self;
}

- setNameForm:(NSForm *)anObject {
    NameForm = anObject;
    return self;
}

//			ACTION METHODS
//			==============

//	Display style in the panel

- display_style {
    if (style->name)
        [(NSFormCell *)[NameForm cellAtIndex:0] setStringValue:[NSString stringWithCString:style->name
                                                                                  encoding:NSUTF8StringEncoding]];
    else
        [(NSFormCell *)[NameForm cellAtIndex:0] setStringValue:@""];

    if (style->SGMLTag)
        [(NSFormCell *)[ParameterForm cellAtIndex:SGMLTAG_FIELD]
            setStringValue:[NSString stringWithCString:style->SGMLTag encoding:NSUTF8StringEncoding]];
    else
        [(NSFormCell *)[ParameterForm cellAtIndex:SGMLTAG_FIELD] setStringValue:@""];

    [(NSFormCell *)[ParameterForm cellAtIndex:FONT_NAME_FIELD] setStringValue:[style->font fontName]];

    [(NSFormCell *)[ParameterForm cellAtIndex:FONT_SIZE_FIELD] setFloatValue:style->fontSize];

    if (style->paragraph) {
        char tabstring[255];
        int i;
        [(NSFormCell *)[ParameterForm cellAtIndex:FIRST_INDENT_FIELD] setFloatValue:style->paragraph->indent1st];
        [(NSFormCell *)[ParameterForm cellAtIndex:SECOND_INDENT_FIELD] setFloatValue:style->paragraph->indent2nd];
        tabstring[0] = 0;
        for (i = 0; i < style->paragraph->numTabs; i++) {
            sprintf(tabstring + strlen(tabstring), "%.0f ", style->paragraph->tabs[i].x);
        }
        [(NSFormCell *)[TabForm cellAtIndex:0] setStringValue:[NSString stringWithCString:tabstring
                                                                                 encoding:NSUTF8StringEncoding]];
    }
    return self;
}

//	Load style from Panel
//
//	@@ Tabs not loaded

- load_style {
    char *name = 0;
    char *stripped;

    style->fontSize = [(NSFormCell *)[ParameterForm cellAtIndex:FONT_SIZE_FIELD] floatValue];
    StrAllocCopy(name,
                 [[(NSFormCell *)[NameForm cellAtIndex:0] stringValue] cStringUsingEncoding:NSUTF8StringEncoding]);
    stripped = HTStrip(name);
    if (*stripped) {
        NSFont *font;
        font = [NSFont fontWithName:[NSString stringWithCString:stripped encoding:NSUTF8StringEncoding]
                               size:style->fontSize];
        if (font)
            style->font = font;
    }
    free(name);
    name = 0;

    StrAllocCopy(name, [[(NSFormCell *)[ParameterForm cellAtIndex:SGMLTAG_FIELD] stringValue]
                           cStringUsingEncoding:NSUTF8StringEncoding]);
    stripped = HTStrip(name);
    if (*stripped) {
        StrAllocCopy(style->SGMLTag, stripped);
    }
    free(name);
    name = 0;

    if (!style->paragraph)
        style->paragraph = malloc(sizeof(*(style->paragraph)));
    style->paragraph->indent1st = [(NSFormCell *)[ParameterForm cellAtIndex:FIRST_INDENT_FIELD] floatValue];
    style->paragraph->indent2nd = [(NSFormCell *)[ParameterForm cellAtIndex:SECOND_INDENT_FIELD] floatValue];

    return self;
}

//	Open a style sheet from a file
//	------------------------------
//
//	We overlay any previously defined styles with new ones, but leave
//	old ones which are not redefined.

- open:sender {
    NXStream *s;                                   //	The file stream
    NSString *filename;                            //	The name of the file
    NSArray<NSString *> *typelist = @[ @"style" ]; //	Extension must be ".style."

    if (!open_panel) {
        open_panel = [NSOpenPanel new];
        [open_panel setAllowsMultipleSelection:NO];
    }

    if (![open_panel runModalForTypes:typelist]) {
        if (TRACE)
            printf("No file selected.\n");
        return nil;
    }

    filename = [open_panel filename];

    if (!styleSheet)
        styleSheet = HTStyleSheetNew();
    StrAllocCopy(styleSheet->name, [filename cStringUsingEncoding:NSUTF8StringEncoding]);

    s = NXOpenFile(styleSheet->name, NX_READONLY);
    if (!s) {
        if (TRACE)
            printf("Styles: Can't open file %s\n", filename);
        return nil;
    }
    if (TRACE)
        printf("Stylesheet: New one called %s.\n", styleSheet->name);
    (void)HTStyleSheetRead(styleSheet, s);
    NXClose(s);
    style = styleSheet->styles;
    [self display_style];
    return self;
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

- loadDefaultStyleSheet {
    NXStream *stream;

    if (!styleSheet)
        styleSheet = HTStyleSheetNew();
    styleSheet->name = malloc(strlen(appDirectory) + 13 + 1);
    strcpy(styleSheet->name, appDirectory);
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
        strcpy(name, appDirectory);
        strcat(name, "default.style");
        if (TRACE)
            printf("Couldn't open $(HOME)/WWW/default.style\n");
        stream = NXOpenFile(name, NX_READONLY);
        if (!stream)
            printf("Couldn't open %s, errno=%i\n", name, errno);
    }

    if (stream) {
        (void)HTStyleSheetRead(styleSheet, stream);
        NXClose(stream);
        style = styleSheet->styles;
        [self display_style];
    }
    return self;
}

//	Save style sheet to a file
//	--------------------------

- saveAs:sender {
    NXStream *s; //	The file stream
    NSString *slash;
    int status;
    NSString *suggestion = 0; //	The name of the file to suggest
    NSString *filename;       //	The name chosen

    if (!save_panel) {
        save_panel = [NSSavePanel new]; //	Keep between invocations
    }

    suggestion = [NSString stringWithCString:styleSheet->name encoding:NSUTF8StringEncoding];
    slash = [suggestion lastPathComponent];
    if (slash) {
        suggestion = [suggestion stringByDeletingLastPathComponent];
        status = [save_panel runModalForDirectory:suggestion file:slash];
    } else {
        status = [save_panel runModalForDirectory:@"." file:suggestion];
    }

    if (!status) {
        if (TRACE)
            printf("No file selected.\n");
        return nil;
    }

    filename = [save_panel filename];
    StrAllocCopy(styleSheet->name, [filename cStringUsingEncoding:NSUTF8StringEncoding]);
    s = NXOpenFile(styleSheet->name, NX_WRITEONLY);
    if (!s) {
        if (TRACE)
            printf("Styles: Can't open file %s for write\n", filename);
        return nil;
    }
    if (TRACE)
        printf("StylestyleSheet: Saving as `%s'.\n", styleSheet->name);
    (void)HTStyleSheetWrite(styleSheet, s);
    NXClose(s);
    style = styleSheet->styles;
    [self display_style];
    return self;
}

//	Move to next style
//	------------------

- NextButton:sender {
    if (styleSheet->styles)
        if (styleSheet->styles->next)
            if (style->next) {
                style = style->next;
            } else {
                style = styleSheet->styles;
            }
    [self display_style];
    return self;
}

- FindUnstyledButton:sender {
    [THIS_TEXT selectUnstyled:styleSheet];
    return self;
}

//	Apply current style to selection
//	--------------------------------

- ApplyButton:sender {
    [THIS_TEXT applyStyle:style];
    return self;
}

- applyStyleNamed:(const char *)name {
    HTStyle *thisStyle = HTStyleNamed(styleSheet, name);
    if (!thisStyle)
        return nil;
    return [THIS_TEXT applyStyle:thisStyle];
}

- heading1Button:sender {
    return [self applyStyleNamed:"Heading1"];
}
- heading2Button:sender {
    return [self applyStyleNamed:"Heading2"];
}
- heading3Button:sender {
    return [self applyStyleNamed:"Heading3"];
}
- heading4Button:sender {
    return [self applyStyleNamed:"Heading4"];
}
- heading5Button:sender {
    return [self applyStyleNamed:"Heading5"];
}
- heading6Button:sender {
    return [self applyStyleNamed:"Heading6"];
}
- normalButton:sender {
    return [self applyStyleNamed:"Normal"];
}
- addressButton:sender {
    return [self applyStyleNamed:"Address"];
}
- exampleButton:sender {
    return [self applyStyleNamed:"Example"];
}
- listButton:sender {
    return [self applyStyleNamed:"List"];
}
- glossaryButton:sender {
    return [self applyStyleNamed:"Glossary"];
}

//	Move to previous style
//	----------------------

- PreviousButton:sender {
    HTStyle *scan;
    for (scan = styleSheet->styles; scan; scan = scan->next) {
        if ((scan->next == style) || (scan->next == 0)) {
            style = scan;
            break;
        }
    }
    [self display_style];
    return self;
}

- SetButton:sender {
    [self load_style];
    [THIS_TEXT updateStyle:style];
    return self;
}

- PickButton:sender {
    HTStyle *st = [THIS_TEXT selectionStyle:styleSheet];
    if (st) {
        style = st;
        [self display_style];
    }
    return self;
}

- ApplyToSimilar:sender {
    return [THIS_TEXT applyToSimilar:style];
}

@end
