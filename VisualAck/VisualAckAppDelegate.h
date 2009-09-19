#import <Cocoa/Cocoa.h>
#import <AppKit/NSApplication.h>

@class MainWindowController;

@interface VisualAckAppDelegate : NSObject {
    MainWindowController *mainWindowController;
}

@property (assign) IBOutlet MainWindowController *mainWindowController;

@end
