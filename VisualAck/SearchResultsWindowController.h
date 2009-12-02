#import <Cocoa/Cocoa.h>

#import "FileSearchProtocol.h"

@interface SearchResultsWindowController : NSWindowController <FileSearchProtocol> {
    IBOutlet NSTableView *tableView_;
    IBOutlet NSView *customView_;
}

- (void)startSearch:(NSString*)searchTerm inDirectory:(NSString*)dir;

@end
