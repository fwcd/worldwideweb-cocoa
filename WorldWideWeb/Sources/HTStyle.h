/*	Style Definition for Hypertext				HTStyle.h
**	==============================
**
**	Styles allow the translation between a logical property of a piece of
**	text and its physical representation.
**
**	A StyleSheet is a collection of styles, defining the
**	translation necessary to represent a document.
**	It is a linked list of styles.
*/

#pragma once

#import "Anchor.h"
#import "NXShims.h"
#import <AppKit/AppKit.h>

#define STYLE_NAME_LENGTH 80

typedef enum _SGML_tagtype {
    NONE,   /* Style holds until further notice 	*/
    ENDTAG, /* Style holds until end tag </xxx> 	*/
    LINE    /* Style holds until end of line (ugh!)	*/
} SGML_tagtype;

typedef float HTCoord;

typedef struct _HTStyle {
    struct _HTStyle *next; /* Link for putting into stylesheet */
    char *name;            /* Style name */
    char *SGMLTag;         /* Tag name to start */
    SGML_tagtype SGMLType; /* How to end it */

    NSFont *font;                       /* The character representation */
    HTCoord fontSize;                   /* The size of font, not independent */
    NSMutableParagraphStyle *paragraph; /* Null means not defined */
#ifdef V1
    float textColor; /* Colour of text */
#else
    NSColor *textColor; /**Colour of text.*/
#endif
    HTCoord spaceBefore; /* Omissions from NSParagraphStyle */
    HTCoord spaceAfter;
    Anchor *anchor; /* Anchor id if any, else zero */
    bool clearAnchor;
} HTStyle;

/*	Style functions:
*/
extern HTStyle *HTStyleNew(void);
extern HTStyle *HTStyleFree(HTStyle *self);
extern HTStyle *HTStyleRead(HTStyle *self, NXStream *stream);
extern HTStyle *HTStyleWrite(HTStyle *self, NXStream *stream);
extern HTStyle *HTStyleApply(HTStyle *self, NSText *text);
extern HTStyle *HTStylePick(HTStyle *self, NSText *text);
typedef struct _HTStyleSheet {
    char *name;
    HTStyle *styles;
} HTStyleSheet;

/*	Stylesheet functions:
*/
extern HTStyleSheet *HTStyleSheetNew(void);
extern HTStyleSheet *HTStyleSheetFree(HTStyleSheet *self);
extern HTStyle *HTStyleNamed(HTStyleSheet *self, const char *name);
extern HTStyle *HTStyleForParagraph(HTStyleSheet *self, NSParagraphStyle *paraStyle);
extern HTStyle *HTStyleForRun(HTStyleSheet *self, NSTextStorage *run);
extern HTStyleSheet *HTStyleSheetAddStyle(HTStyleSheet *self, HTStyle *style);
extern HTStyleSheet *HTStyleSheetRemoveStyle(HTStyleSheet *self, HTStyle *style);
extern HTStyleSheet *HTStyleSheetRead(HTStyleSheet *self, NXStream *stream);
extern HTStyleSheet *HTStyleSheetWrite(HTStyleSheet *self, NXStream *stream);
