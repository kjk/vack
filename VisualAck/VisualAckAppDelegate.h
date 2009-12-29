#import <Cocoa/Cocoa.h>
#import <AppKit/NSApplication.h>

@class MainWindowController;

@interface VisualAckAppDelegate : NSObject {
    MainWindowController *mainWindowController_;
    
    NSOperationQueue *  operationQueue_;
}

+ (id)shared;
- (void)addOperation:(NSOperation*)operation;
- (IBAction)showMainWindow:(id)sender;
- (IBAction)showAboutWindow:(id)sender;
- (BOOL)isNewSearchMenuEnabled;

@end
