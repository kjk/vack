#import <Cocoa/Cocoa.h>
#import <AppKit/NSApplication.h>

@class SearchWindowController;
@class SearchResultsWindowController;

@interface VisualAckAppDelegate : NSObject {
    SearchWindowController *searchWindowController_;
    SearchResultsWindowController *searchResultsWindowController_;
    
    NSOperationQueue *operationQueue_;
}

+ (id)shared;
- (void)addOperation:(NSOperation*)operation;

- (IBAction)showSearchWindow:(id)sender;
- (void)incSearchCount;
- (void)startSearch:(NSString *)searchTerm inDirectory:(NSString*)dir;

@end
