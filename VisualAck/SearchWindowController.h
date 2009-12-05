#import <Cocoa/Cocoa.h>

@interface SearchWindowController : NSWindowController {
    IBOutlet NSTextField *      searchTermField_;
    IBOutlet NSTextField *      dirField_;
    IBOutlet NSButton *         buttonSearch_;
    IBOutlet NSButton *         buttonChooseDir_;
}

- (IBAction)showWindow:(id)sender;
- (IBAction)search:(id)sender;
- (IBAction)chooseDir:(id)sender;

// We're also a data source for tableView_
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;

- (id)tableView:(NSTableView *)aTableView 
objectValueForTableColumn:(NSTableColumn *)aTableColumn
			row:(int)rowIndex;

@end
