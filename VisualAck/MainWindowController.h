#import <Cocoa/Cocoa.h>
#import "FileSearchProtocol.h"

@interface MainWindowController : NSWindowController <FileSearchProtocol> {

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
    IBOutlet NSTextField *      textFieldStatus_;
    IBOutlet NSProgressIndicator* searchProgressIndicator_;
	
	NSMutableArray *            searchResults_;
    int                         resultsCount_;

    NSDictionary *              filePathStringAttrs_;
    NSDictionary *              matchStringAttrs_;
    NSDictionary *              lineNumberStringAttrs_;

	NSDictionary *				dirStringAttrs_;

    // array of NSString for recent searches. It has 2 strings per
    // search: search term and search location(s) (separated by ';' if
    // more than one). Recent searches are at the end.
    NSMutableArray *            recentSearches_;

    NSInteger                   searchedFiles_;
    NSInteger                   skippedDirs_;
    NSInteger                   skippedFiles_;
}

- (IBAction)showWindow:(id)sender;
- (IBAction)search:(id)sender;
- (IBAction)chooseDir:(id)sender;
- (IBAction)tableViewDoubleClick:(id)sender;

- (NSInteger)searchCount;

- (void)startSearch:(NSString*)searchTerm inDirectory:(NSString*)dir;

// tableView_ and tableViewRecentSearches_ data source methods
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;

// tableViewRecentSearches_ delegate methods
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;

@end
