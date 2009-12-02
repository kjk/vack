#import <Cocoa/Cocoa.h>
#import <AppKit/NSApplication.h>

@class SearchWindowController;

@interface VisualAckAppDelegate : NSObject {
    SearchWindowController *searchWindowController;    
}

- (void)incSearchCount;

@property (assign) SearchWindowController *searchWindowController;

@end
