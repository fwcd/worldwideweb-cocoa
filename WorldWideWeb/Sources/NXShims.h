//
//  NXShims.h
//  WorldWideWeb
//
//  Created by Chris Brandow on 8/23/24.
//

#pragma once

#import <AppKit/AppKit.h>
#import <stdio.h>

/// These are largely just copied from Next Manual
/// http://www.bitsavers.org/pdf/next/Release_1_Dec90/NEXTstep_Reference_Volume_1_Dec90.pdf
/// http://www.bitsavers.org/pdf/next/Release_1_Dec90/NEXTstep_Reference_Volume_2_Dec90.pdf

typedef struct _NXTextBlock {
    struct _NXTextBlock *next;  /* Next block in linked list */
    struct _NXTextBlock *prior; /* Previous block in linked list */
    struct _bFlags {
        unsigned int malloced : 1; /* True if block was malloced */
        unsigned int PAD : 15;
    } tbFlags;
    short chars;         /* Number of characters in block */
    unsigned char *text; /* The text */
} NXTextBlock;

typedef float NXCoord;

/* Describes tabstop. */
typedef struct _NXTabStop {
    short kind; /* Only NX_LEFTTAB implemented */
    NXCoord x;  /* x coordinate for stop */
} NXTabStop;

// TODO: Add functions for converting to/from NSParagraphStyle

/* Describes text layout and tab stops. */
typedef struct _NXTextStyle {
    NXCoord indent1st; /* How far first line in paragraph is */  /* indented */
    NXCoord indent2nd; /* How far second and subsequent lines */ /* are indented */
    NXCoord lineHt;                                              /* Line height */
    NXCoord descentLine;                                         /* Distance from baseline to bottom of line */
    short alignment;                                             /* Text alignment */
    short numTabs;                                               /* Number of tab stops */
    NXTabStop *tabs;                                             /* Array of tab stops */
} NXTextStyle;

typedef struct _NXChunk {
    short growby;  /* Increment to grow by */
    int allocated; /* Number of bytes allocated */
    int used;      /* Number of bytes used */
} NXChunk;

typedef struct {
    unsigned int underline : 1;        /* True if text is underlined */
    unsigned int dummy : 1;            /* Unused */
    unsigned int subclassWantsRTF : 1; /* Obsolete */
    unsigned int graphic : 1;          /* True if graphic is present */
    unsigned int RESERVED : 12;
} NXRunFlags;

/* NXRun represents a single sequence of text with a given format. */
typedef struct _NXRun {
    id font;                   /* Font id */
    int chars;                 /* Number of characters in run */
    void *paraStyle;           /* paragraph style information */
    float textGray;            /* Text gray of current run */
    float textRGBColor;        /* Text color of current run */
    unsigned char superscript; /* Superscript in points */
    unsigned char subscript;   /* Subscript in points */
    id info;                   /* For subclasses of Text */
    NXRunFlags rFlags;         /* Indicates underline etc. */
} NXRun;

/* An NXRunArray holds the array of text runs.*/
typedef struct _NXRunArray {
    NXChunk chunk;
    NXRun runs[1];
} NXRunArray;

typedef FILE NXStream;

#define NXScanf fscanf
#define NXPrintf fprintf
#define NXOpenFile fopen
#define NXFlush fflush
#define NXClose fclose
#define NXGetc getc
#define NXUngetc ungetc
#define NXAtEOS feof

#define NX_READONLY "r"
#define NX_WRITEONLY "w"
