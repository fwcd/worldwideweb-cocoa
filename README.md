# WorldWideWeb Cocoa

An experimental Cocoa port of Tim Berners-Lee's original [WorldWideWeb](https://en.wikipedia.org/wiki/WorldWideWeb) web browser.

## Background

The main motivation behind this port is mostly academic curiosity, specifically learning about the implementation of the first web browser (how HTML rendering works etc.) and learning about the NeXTStep API. The goal is to eventually have a working Cocoa application that stays as faithful to the original code as possible.

### The NeXTStep API vs. Cocoa/AppKit

While the original NeXTStep API and modern AppKit still share substantial similarities, many things have changed over the last 30 years. The most noticeable difference is perhaps the `NS` prefix, which replaced the older `NX` prefix, but more subtle changes exist too, specifically classes like [`NSParagraphStyle`](https://developer.apple.com/documentation/uikit/nsparagraphstyle?language=objc), which are more encapsulated (i.e. expose a lot less of their internal state) than back in the NeXTStep days. This unfortunately complicates the migration, because much of the rendering engine (see e.g. the [`HyperText`](https://github.com/fwcd/worldwideweb-cocoa/blob/4276fe7bd1e70c24a6d70fc96a13e06aa5f6fc67/WorldWideWeb/HyperText.m) class) relied on these internals of [`NSText`](https://developer.apple.com/documentation/appkit/nstext) (or `Text` in the NeXTStep API) etc.

For more information, see [issue #2](https://github.com/fwcd/worldwideweb-cocoa/issues/2).

### The Interface Builder NIB Format

Another major hurdle to overcome is the legacy Interface Builder NIB format. This format has changed a few times over the years, from the original `NXTypedStream` (see [this Python reimplementation](https://github.com/dgelessus/python-typedstream)) to the modern XML-based XIB format. While Xcode is capable of reading older versions of the XML-based format, the [`WorldWideWeb.nib`](https://github.com/fwcd/worldwideweb-cocoa/tree/4276fe7bd1e70c24a6d70fc96a13e06aa5f6fc67/WorldWideWeb/WorldWideWeb.nib) turned out to be too old even for versions of Project Builder, the predecessor of Xcode. Our approach here is to use [a custom Python script](Scripts/convert-nib-to-xib) to convert the legacy NIB to a modern XIB.

More information on this can be found in [issue #1](https://github.com/fwcd/worldwideweb-cocoa/issues/1).
