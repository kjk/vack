#import "SearchWindowController.h"

#import "VisualAckAppDelegate.h"

@interface SearchWindowController(Private)
- (BOOL)isSearchButtonEnabled;
- (void)updateSearchButtonStatus;
@end

@implementation SearchWindowController

- (void)awakeFromNib {
	[tableViewRecentSearches_ setDoubleAction:@selector(tableViewDoubleClick:)];
}

- (IBAction)showWindow:(id)sender {
	// asking for window loads it for nib file and initializes bindings
    NSWindow *window = [self window];
    [dirField_ setStringValue:[@"~" stringByExpandingTildeInPath]];
    [self updateSearchButtonStatus];
    [window makeKeyAndOrderFront:sender];
    //[window makeFirstResponder:searchTermField_];
}

- (BOOL)isSearchButtonEnabled {
    if ([[searchTermField_ stringValue] length] == 0)
        return NO;
    // TODO: verify that all entries are valid directories
    if ([[dirField_ stringValue] length] == 0)
        return NO;
    return YES;
}

- (void)updateSearchButtonStatus {
    BOOL enabled = [self isSearchButtonEnabled];
    [buttonSearch_ setEnabled:enabled];
}

- (void)controlTextDidChange:(NSNotification*)aNotification {
    [self updateSearchButtonStatus];
}

// Sent by "Search" button
- (IBAction)search:(id)sender {
    // came from text field but not ready to do search
    if (![self isSearchButtonEnabled])
        return;

    VisualAckAppDelegate *appDelegate = [NSApp delegate];
    [[self window] orderOut:nil];
    NSString *searchTerm = [searchTermField_ stringValue];
    NSString *dir = [dirField_ stringValue];
    [appDelegate startSearch:searchTerm inDirectory:dir];
	// startSearch might have updated recent searches list, so
	// reload it to make the search visible
	[tableViewRecentSearches_ reloadData];
}


- (IBAction) chooseDir:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setAllowsMultipleSelection:YES];
    [openPanel setAllowedFileTypes:nil];
    [openPanel setDirectory:[dirField_ stringValue]];
    NSInteger res = [openPanel runModal];
    if (res != NSOKButton)
        return;
    NSString * dir = [openPanel directory];
    NSArray *files = [openPanel filenames];
    NSMutableString *s = [NSMutableString stringWithString:@""];
    for (NSString *file in files) {
        [s appendString:file];
        [s appendString:@";"];
    }
    [s deleteCharactersInRange:NSMakeRange([s length] - 1, 1)];
    [dirField_ setStringValue:s];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    NSArray *recentSearches = [[VisualAckAppDelegate shared] recentSearches];
	return [recentSearches count] / 2;
}

- (id)tableView:(NSTableView *)aTableView 
objectValueForTableColumn:(NSTableColumn *)aTableColumn
			row:(int)rowIndex {
    NSArray *recentSearches = [[VisualAckAppDelegate shared] recentSearches];
    NSUInteger count = [recentSearches count];
    // they are in reverse order
    assert(count >= rowIndex * 2);
    NSUInteger idx = count - ((rowIndex+1) * 2);
    // TODO: need to be displayed in a nicer way
    NSString *searchTerm = [recentSearches objectAtIndex:idx];
    NSString *dir = [recentSearches objectAtIndex:idx+1];
    NSString *s = [NSString stringWithFormat:@"%@ in %@", searchTerm, dir];
    return s;
}

- (IBAction)tableViewDoubleClick:(id)sender {
	NSInteger row = [tableViewRecentSearches_ selectedRow];
    NSArray *recentSearches = [[VisualAckAppDelegate shared] recentSearches];
    NSInteger searchesCount = [recentSearches count] / 2;
	if (row < 0 || row >= searchesCount) {
		return;
	}
	NSInteger idx = (searchesCount - 1 - row) * 2;
	NSString *searchTerm = [recentSearches objectAtIndex:idx];
	NSString *searchDir = [recentSearches objectAtIndex:idx+1];
	VisualAckAppDelegate *appDelegate = [NSApp delegate];
	[appDelegate startSearch:searchTerm inDirectory:searchDir];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	NSInteger row = [tableViewRecentSearches_ selectedRow];
    NSArray *recentSearches = [[VisualAckAppDelegate shared] recentSearches];
    NSInteger searchesCount = [recentSearches count] / 2;
	if (row < 0 || row >= searchesCount) {
		return;
	}
	NSInteger idx = (searchesCount - 1 - row) * 2;
	NSString *searchTerm = [recentSearches objectAtIndex:idx];
	NSString *searchDir = [recentSearches objectAtIndex:idx+1];
	[searchTermField_ setStringValue:searchTerm];
	[dirField_ setStringValue:searchDir];
}

@end
