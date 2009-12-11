#import "MainWindowController.h"

#import "FileSearcher.h"
#import "FileSearchResult.h"
#import "PrefKeys.h"
#import "VisualAckAppDelegate.h"

#define MAX_RECENT_SEARCHES 8

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

@interface MainWindowController(Private)
- (BOOL)isSearchButtonEnabled;
- (void)updateSearchButtonStatus;
- (void)loadRecentSearches;
- (void)rememberSearchFor:(NSString*)searchTerm inDirectory:(NSString*)dir;
@end

@implementation MainWindowController

- (void)awakeFromNib {
    [self loadRecentSearches];
    NSWindow *window = [self window];
    [window setContentView:viewSearch_];
	[tableViewRecentSearches_ setDoubleAction:@selector(tableViewDoubleClick:)];

    searchResults_ = [[NSMutableArray arrayWithCapacity:100] retain];
    // 0x47A72F - green
    NSColor *filePathColor = [NSColor colorWithCalibratedRed:0.2784 green:0.6549 blue:0.1843 alpha:1.0];
    filePathStringAttrs_ = [[NSDictionary dictionaryWithObject:filePathColor
                                                        forKey:NSForegroundColorAttributeName] retain];
    // 898420 - yellowish
    NSColor *matchColor = [NSColor colorWithCalibratedRed:0.5372 green:0.5176 blue:0.1254 alpha:1.0];
    matchStringAttrs_ = [[NSDictionary dictionaryWithObject:matchColor
                                                     forKey:NSBackgroundColorAttributeName] retain];
    NSColor *lineNumberColor = [NSColor grayColor];
    lineNumberStringAttrs_ = [[NSDictionary dictionaryWithObject:lineNumberColor
                                                         forKey:NSForegroundColorAttributeName] retain];
    [dirField_ setStringValue:[@"~" stringByExpandingTildeInPath]];
    [self updateSearchButtonStatus];
}

- (void)dealloc {
    [searchResults_ release];
    [filePathStringAttrs_ release];
    [matchStringAttrs_ release];
    [recentSearches_ release];
    [lineNumberStringAttrs_ release];
    [super dealloc];
}

- (IBAction)showWindow:(id)sender {
    [[self window] makeKeyAndOrderFront:sender];
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
        return [recentSearches_ count] / 2;
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
        NSUInteger count = [recentSearches_ count];
        // they are in reverse order
        assert(count >= rowIndex * 2);
        NSUInteger idx = count - ((rowIndex+1) * 2);
        // TODO: need to be displayed in a nicer way
        NSString *searchTerm = [recentSearches_ objectAtIndex:idx];
        NSString *dir = [recentSearches_ objectAtIndex:idx+1];
        NSString *s = [NSString stringWithFormat:@"%@ in %@", searchTerm, dir];
        return s;
    } else {
        assert(aTableView == tableView_);
        return [searchResults_ objectAtIndex:rowIndex];
    }        
}

- (IBAction)tableViewDoubleClick:(id)sender {
	NSInteger row = [tableViewRecentSearches_ selectedRow];
    NSInteger searchesCount = [recentSearches_ count] / 2;
	if (row < 0 || row >= searchesCount) {
		return;
	}
	NSInteger idx = (searchesCount - 1 - row) * 2;
	NSString *searchTerm = [recentSearches_ objectAtIndex:idx];
	NSString *searchDir = [recentSearches_ objectAtIndex:idx+1];
	[self startSearch:searchTerm inDirectory:searchDir];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    NSTableView *tableView = [aNotification object];
    if (tableView != tableViewRecentSearches_) {
        return;
    }
	NSInteger row = [tableViewRecentSearches_ selectedRow];
    NSInteger searchesCount = [recentSearches_ count] / 2;
	if (row < 0 || row >= searchesCount) {
		return;
	}
	NSInteger idx = (searchesCount - 1 - row) * 2;
	NSString *searchTerm = [recentSearches_ objectAtIndex:idx];
	NSString *searchDir = [recentSearches_ objectAtIndex:idx+1];
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
    [searchResults_ removeAllObjects];
    [self rememberSearchFor:searchTerm inDirectory:dir];
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

- (void)incSearchCount {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSInteger count = [prefs integerForKey:PREF_SEARCH_COUNT];
    ++count;
    [prefs setInteger:count forKey:PREF_SEARCH_COUNT];    
}


- (NSInteger)recentSearchIndex:(NSString*)searchTerm inDirectory:(NSString*)dir {
    NSInteger n = [recentSearches_ count] / 2;
    NSString *searchTermTable;
    NSString *dirTable;
    for (NSInteger i = 0; i < n; i++) {
        searchTermTable = [recentSearches_ objectAtIndex:i*2];
        // TODO: consider case insensitive compare
        if (![searchTerm isEqualToString:searchTermTable]) {
            continue;
        }
        dirTable = [recentSearches_ objectAtIndex:i*2 + 1];
        if (![dir isEqualToString:dirTable]) {
            continue;
        }
        return i;
    }
    return NSNotFound;
}

- (void)rememberSearchFor:(NSString*)searchTerm inDirectory:(NSString*)dir {
    NSInteger searchPos = [self recentSearchIndex:searchTerm inDirectory:dir];
    if (NSNotFound != searchPos) {
        [recentSearches_ removeObjectAtIndex:searchPos*2];
        [recentSearches_ removeObjectAtIndex:searchPos*2];
    }
    if (([recentSearches_ count] / 2) >= MAX_RECENT_SEARCHES) {
        [recentSearches_ removeObjectAtIndex:0];
        [recentSearches_ removeObjectAtIndex:0];
    }
    [recentSearches_ addObject:searchTerm];
    [recentSearches_ addObject:dir];
    [[NSUserDefaults standardUserDefaults] setObject:recentSearches_ forKey:PREF_RECENT_SEARCHES];
    [self incSearchCount];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSInteger)searchCount {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    return [prefs integerForKey:PREF_SEARCH_COUNT];
}

- (void)loadRecentSearches {
    assert(nil == recentSearches_);
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    if ( [prefs arrayForKey:PREF_RECENT_SEARCHES] != nil ) {
        recentSearches_ = [[NSMutableArray alloc] initWithArray:[prefs arrayForKey:PREF_RECENT_SEARCHES]];
        return;
    }
    recentSearches_ = [[NSMutableArray alloc] initWithCapacity:MAX_RECENT_SEARCHES * 2];
}

@end
