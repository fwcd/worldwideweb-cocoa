//
//  HyperTextDelegate.h
//  WorldWideWeb
//
//  Created on 13.09.24
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HyperTextDelegate <NSObject>

- (void)hyperTextDidBecomeMain:(id)hyperText;

@end

NS_ASSUME_NONNULL_END
