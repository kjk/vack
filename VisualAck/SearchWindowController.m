#import "SearchWindowController.h"

#import "FileSearcher.h"
#import "FileSearchResult.h"
#import "VisualAckAppDelegate.h"

@interface SearchOperation : NSOperation {
    search_options searchOptions_;
    id dlg;
}

- (id)initWithSearchOptions:(search_options)searchOptions delegate:aDelegate;
@end

@implementation SearchOperation

- (id)initWithSearchOptions:(search_options)searchOptions delegate:delegate {
    if (![super init]) return nil;
    searchOptions_ = searchOptions;
    dlg = delegate;
    return self;
}

- (void)main {
    FileSearcher *fileSearcher = [[FileSearcher alloc] initWithSearchOptions:&searchOptions_];
    [fileSearcher setDelegate:dlg];
    [fileSearcher startSearch];
    [fileSearcher release];
    // took ownership of searchOptions, so must free them
	free_search_options(&searchOptions_);
}
@end

@interface SearchWindowController(Private)
- (BOOL)isSearchButtonEnabled;
- (void)updateSearchButtonStatus;
@end

@implementation SearchWindowController

- (void)awakeFromNib {
    NSWindow *window = [self window];
    [window setContentView:viewSearch_];
	[tableViewRecentSearches_ setDoubleAction:@selector(tableViewDoubleClick:)];

    searchResults_ = [[NSMutableArray arrayWithCapacity:100] retain];
    NSColor *filePathColor = [NSColor redColor];
    filePathStringAttrs_ = [NSDictionary dictionaryWithObject:filePathColor
                                                       forKey:NSForegroundColorAttributeName];
    [filePathStringAttrs_ retain];
    NSColor *matchColor = [NSColor blueColor];
    matchStringAttrs_ = [NSDictionary dictionaryWithObject:matchColor 
                                                    forKey:NSBackgroundColorAttributeName];
    [matchStringAttrs_ retain];    
}

- (void)dealloc {
    [searchResults_ release];
    [filePathStringAttrs_ release];
    [matchStringAttrs_ release];
    [super dealloc];
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
    [self startSearch:searchTerm inDirectory:dir];
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
    if (aTableView == tableViewRecentSearches_) {
        NSArray *recentSearches = [[VisualAckAppDelegate shared] recentSearches];
        return [recentSearches count] / 2;
    } else {
        assert(aTableView == tableView_);
        int count = [searchResults_ count];
        return count;
    }
}

- (id)tableView:(NSTableView *)aTableView 
    objectValueForTableColumn:(NSTableColumn *)aTableColumn
                          row:(int)rowIndex {
    if (aTableView == tableViewRecentSearches_) {
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
    } else {
        assert(aTableView == tableView_);
        return [searchResults_ objectAtIndex:rowIndex];
    }        
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
	[self startSearch:searchTerm inDirectory:searchDir];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    NSTableView *tableView = [aNotification object];
    if (tableView != tableViewRecentSearches_) {
        return;
    }
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

- (void)didSkipFile:(NSString*)filePath {
    NSLog(@"didSkipFile %@", filePath);
}

- (void)didSkipDirectory:(NSString*)dirPath {
    NSLog(@"didSkipDirectory %@", dirPath);
}

- (void)didSkipNonExistent:(NSString*)path {
    NSLog(@"didSkipNonExistent %@", path);    
}

- (void)didStartSearchInFile:(NSString*)filePath {
    resultsCount_ = 0;
    NSLog(@"didStartSearchInFile in %@", filePath);
}

- (void)didFinishSearchInFile:(NSString*)filePath {
    NSLog(@"didFinishSearchInFile in %@", filePath);
}

static void setAttributedStringRanges(NSMutableAttributedString *s, int rangesCount, NSRange *ranges, NSDictionary *attrs)
{
    for (int i=0; i < rangesCount; i++)
    {
        NSRange range = ranges[i];
        [s setAttributes:attrs range:range];
    }
}

- (void)didFindThreadSafe:(FileSearchResult*)searchResult {
    NSString *s;
    NSAttributedString *as;
    if (0 == resultsCount_) {
        s = searchResult.filePath;
        as = [[NSAttributedString alloc] initWithString:s
                                             attributes:filePathStringAttrs_];
        [searchResults_ addObject:as];
    }
    NSMutableAttributedString *mas = [[NSMutableAttributedString alloc] initWithString:searchResult.line];
    setAttributedStringRanges(mas, searchResult.matchesCount, searchResult.matches, matchStringAttrs_);
	s = [NSString stringWithFormat:@"%d: ", (int)searchResult.lineNo];
    as = [[NSAttributedString alloc] initWithString:s];
    [mas insertAttributedString:as atIndex:0];
	[searchResults_ addObject:mas];
	[tableView_ reloadData];
    ++resultsCount_;
}

- (void)didFind:(FileSearchResult*)searchResult {
    [self performSelectorOnMainThread:@selector(didFindThreadSafe:) withObject:searchResult waitUntilDone:YES];
    // TODO: check if the user cancelled search and abort if he did by returning YES
}

- (void)startSearch:(NSString*)searchTerm inDirectory:(NSString*)dir {
    [[VisualAckAppDelegate shared] rememberSearchFor:searchTerm inDirectory:dir];
	[tableViewRecentSearches_ reloadData];

    [[self window] setContentView:viewSearchResults_];
	search_options opts;
	init_search_options(&opts);
	opts.search_term = strdup([searchTerm UTF8String]);
	add_search_location(&opts, [dir UTF8String]);
    
    // takes ownership of opts, so no freeing them here
    SearchOperation *op = [[SearchOperation alloc] initWithSearchOptions:opts delegate:self];
    [[VisualAckAppDelegate shared] addOperation:op];
    [op release];
}

- (BOOL)windowShouldClose:(id)sender {
    NSLog(@"windowShouldClose");
    NSWindow *window = [self window];
    if ([window contentView] == viewSearchResults_) {
        [window setContentView:viewSearch_];
        return NO;
    }
    return YES;
}

@end
