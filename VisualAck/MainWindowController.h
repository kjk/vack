#import <Cocoa/Cocoa.h>
#import "FileSearchProtocol.h"
#import "SearchOptions.h"

@class MyTextFieldCell;

@interface MainWindowController : NSWindowController <FileSearchProtocol> {

    IBOutlet NSView *           viewSearch_;
    IBOutlet NSView *           viewSearchResults_;

    // Outlets for search window
    IBOutlet NSSearchField *    searchTermField_;
    IBOutlet NSTextField *      dirField_;
    IBOutlet NSTextField *      errorField_;
    IBOutlet NSButton *         buttonSearch_;
    IBOutlet NSButton *         buttonChooseDir_;
	IBOutlet NSTableView *		tableViewRecentSearches_;
	IBOutlet NSButton *			websiteUrl_;

    // Outlets for results window
    IBOutlet NSButton *         stopButton_;
    IBOutlet NSButton *         searchButton_;
    IBOutlet NSTextField *      searchTermField2_;
    IBOutlet NSTextField *      dirField2_;

    IBOutlet NSOutlineView *    searchResultsView_;
    IBOutlet NSView *           customView_;
    IBOutlet NSTextField *      textFieldStatus_;
    IBOutlet NSProgressIndicator* searchProgressIndicator_;
	IBOutlet NSTextField *      textNoResultsFound_;

	NSMutableArray *            searchResults_;
	NSInteger					resultsInCurrentFile_;

	BOOL						forceSearchEnd_;

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
- (IBAction)search2:(id)sender;
- (IBAction)stopSearch:(id)sender;
- (IBAction)chooseDir:(id)sender;
- (IBAction)tableViewDoubleClick:(id)sender;
- (IBAction)launchWebsite:(id)sender;

- (BOOL)isFontBold;

- (NSInteger)searchCount;

- (void)startSearch:(NSString*)searchTerm inDirectory:(NSString*)dir;
- (void)startSearchForSearchOptions:(search_options)searchOptions;

// tableView_ and tableViewRecentSearches_ data source methods
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;

// tableViewRecentSearches_ delegate methods
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;

@end
