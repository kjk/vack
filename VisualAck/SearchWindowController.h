#import <Cocoa/Cocoa.h>

@interface SearchWindowController : NSWindowController {
    IBOutlet NSSearchField *    searchTermField_;
    IBOutlet NSTextField *      dirField_;
    IBOutlet NSButton *         buttonSearch_;
    IBOutlet NSButton *         buttonChooseDir_;
	IBOutlet NSTableView *		tableViewRecentSearches_;
}

- (IBAction)showWindow:(id)sender;
- (IBAction)search:(id)sender;
- (IBAction)chooseDir:(id)sender;
- (IBAction)tableViewDoubleClick:(id)sender;

// tableViewRecentSearches_ data source methods
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;

// tableViewRecentSearches_ delegate methods
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;

@end
