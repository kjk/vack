#import <Cocoa/Cocoa.h>
#import "FileSearchProtocol.h"

@interface SearchWindowController : NSWindowController <FileSearchProtocol> {

    IBOutlet NSView *           viewSearch_;
    IBOutlet NSView *           viewSearchResults_;

    // Outlets for main window
    IBOutlet NSSearchField *    searchTermField_;
    IBOutlet NSTextField *      dirField_;
    IBOutlet NSButton *         buttonSearch_;
    IBOutlet NSButton *         buttonChooseDir_;
	IBOutlet NSTableView *		tableViewRecentSearches_;

    // Outlets for results window
    IBOutlet NSTableView *      tableView_;
    IBOutlet NSView *           customView_;
	
	NSMutableArray *            searchResults_;
    int                         resultsCount_;

    NSDictionary *              filePathStringAttrs_;
    NSDictionary *              matchStringAttrs_;
}

- (IBAction)showWindow:(id)sender;
- (IBAction)search:(id)sender;
- (IBAction)chooseDir:(id)sender;
- (IBAction)tableViewDoubleClick:(id)sender;

- (void)startSearch:(NSString*)searchTerm inDirectory:(NSString*)dir;

// tableView_ and tableViewRecentSearches_ data source methods
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;

// tableViewRecentSearches_ delegate methods
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;

@end
