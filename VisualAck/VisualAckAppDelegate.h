#import <Cocoa/Cocoa.h>
#import <AppKit/NSApplication.h>

@class SearchWindowController;

@interface VisualAckAppDelegate : NSObject {
    SearchWindowController *searchWindowController;
}

@property (assign) SearchWindowController *searchWindowController;

@end
