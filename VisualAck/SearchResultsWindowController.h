#import <Cocoa/Cocoa.h>

#import "FileSearchProtocol.h"

@interface SearchResultsWindowController : NSWindowController <FileSearchProtocol> {
    IBOutlet NSTableView *  tableView_;
    IBOutlet NSView *       customView_;
	
	NSMutableArray *        searchResults_;
    int                     resultsCount_;

    NSDictionary *          filePathStringAttrs_;
    NSDictionary *          matchStringAttrs_;
}

- (void)startSearch:(NSString*)searchTerm inDirectory:(NSString*)dir;

// We're also a data source for tableView_
// TODO: maybe make a separate object be a data source
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;

- (id)tableView:(NSTableView *)aTableView 
	objectValueForTableColumn:(NSTableColumn *)aTableColumn
			row:(int)rowIndex;

@end
