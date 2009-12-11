#import <Cocoa/Cocoa.h>
#import <AppKit/NSApplication.h>

@class MainWindowController;

@interface VisualAckAppDelegate : NSObject {
    MainWindowController *searchWindowController_;
    
    NSOperationQueue *  operationQueue_;
}

+ (id)shared;
- (void)addOperation:(NSOperation*)operation;

@end
