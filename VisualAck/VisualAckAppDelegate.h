#import <Cocoa/Cocoa.h>
#import <AppKit/NSApplication.h>

@class SearchWindowController;

@interface VisualAckAppDelegate : NSObject {
    SearchWindowController *searchWindowController_;
    
    NSOperationQueue *  operationQueue_;
    // array of NSString for recent searches. It has 2 strings per
    // search: search term and search location(s) (separated by ';' if
    // more than one). Recent searches are at the end.
    NSMutableArray *    recentSearches_;
}

+ (id)shared;
- (void)addOperation:(NSOperation*)operation;
- (NSMutableArray*)recentSearches;
- (void)rememberSearchFor:(NSString*)searchTerm inDirectory:(NSString*)dir;

//- (void)positionWindow:(NSWindow*)dst atSamePositionAs:(NSWindow*)src;
@end
