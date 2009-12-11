#import <Cocoa/Cocoa.h>
#import <AppKit/NSApplication.h>

@class SearchWindowController;

@interface VisualAckAppDelegate : NSObject {
    SearchWindowController *searchWindowController_;
    
    NSOperationQueue *  operationQueue_;
}

+ (id)shared;
- (void)addOperation:(NSOperation*)operation;

//- (void)positionWindow:(NSWindow*)dst atSamePositionAs:(NSWindow*)src;
@end
