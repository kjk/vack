#import "MainWindowController.h"

#import "FileSearcher.h"
#import "FileSearchResult.h"
#import "MAAttachedWindow.h"
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
    [fileSearcher doSearch];
    // took ownership of searchOptions, so must free them
	free_search_options(&searchOptions_);
}
@end

@interface SearchResultsFile : NSObject {
	NSString *			fileName_;
	NSMutableArray *	children_;
}

- (id)initWithFileName:(NSString*)fileName;
- (void)addResult:(id)child;
- (NSArray*)children;
- (NSInteger)childrenCount;
- (NSString*)fileName;
@end

@implementation SearchResultsFile

- (id)initWithFileName:(NSString*)fileName {
	if (![super init]) return nil;
	fileName_ = [fileName copy];
	children_ = [[NSMutableArray alloc] initWithCapacity:16];
	return self;
}

- (void)addResult:(id)child {
	[children_ addObject:child];
}

- (NSArray*)children {
	return children_;
}

- (NSInteger)childrenCount {
	return [children_ count];
}

- (NSString*)fileName {
	return [NSString stringWithFormat:@"  %@", fileName_];
}
@end

@interface MainWindowController(Private)
- (BOOL)isSearchButtonEnabled;
- (BOOL)isSearchButtonEnabled2;
- (void)updateSearchButtonStatus;
- (void)loadRecentSearches;
- (void)rememberSearchFor:(NSString*)searchTerm inDirectory:(NSString*)dir;
- (void)updateSearchStatus;
@end

@implementation MainWindowController

- (void)awakeFromNib {
    [self loadRecentSearches];
    NSWindow *window = [self window];
    [window setContentView:viewSearch_];
	[tableViewRecentSearches_ setDoubleAction:@selector(tableViewDoubleClick:)];

    searchResults_ = [NSMutableArray arrayWithCapacity:64];

	NSFont *font = [NSFont systemFontOfSize:10.0];
    NSFont *fontBold = [NSFont boldSystemFontOfSize:0.0];
	//NSFont *fontSmall = [NSFont systemFontOfSize:9.0];

    // 0x47A72F - green
    NSColor *filePathColor = [NSColor colorWithCalibratedRed:0.2784 green:0.6549 blue:0.1843 alpha:1.0];
    filePathStringAttrs_ = [NSDictionary dictionaryWithObject:filePathColor
                                                        forKey:NSForegroundColorAttributeName];
    // 898420 - yellowish
    //NSColor *matchColor = [NSColor colorWithCalibratedRed:0.5372 green:0.5176 blue:0.1254 alpha:1.0];

    // #AACCFB - light blue selection like in safari or xcode
    NSColor *matchColor = [NSColor colorWithCalibratedRed:0.6679 green:0.8 blue:0.9843 alpha:1.0];
    matchStringAttrs_ = [NSDictionary dictionaryWithObjectsAndKeys:matchColor,
                          NSBackgroundColorAttributeName, fontBold, NSFontAttributeName, nil];

    NSColor *lineNumberColor = [NSColor grayColor];
    lineNumberStringAttrs_ = [NSDictionary dictionaryWithObjectsAndKeys:lineNumberColor,
                               NSForegroundColorAttributeName, font, NSFontAttributeName, nil];

	dirStringAttrs_ = [NSDictionary dictionaryWithObjectsAndKeys:lineNumberColor,
						NSForegroundColorAttributeName, font, NSFontAttributeName, nil];
    [dirField_ setStringValue:[@"~" stringByExpandingTildeInPath]];
    [self updateSearchButtonStatus];
	//NSLog(@"indentationLevel: %.2f", [searchResultsView_ indentationPerLevel]);
	//NSLog(@"indentationMarkerFollowsCell: %d", (int)[searchResultsView_ indentationMarkerFollowsCell]);
	[searchResultsView_ setIndentationMarkerFollowsCell:NO];
	[searchResultsView_ setIndentationPerLevel:2.0];

    NSDictionary *urlAttr = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSColor grayColor], NSForegroundColorAttributeName,
									[NSFont systemFontOfSize:9.0], NSFontAttributeName, nil];

    NSAttributedString *url = [[NSAttributedString alloc] 
                               initWithString:@"http://blog.kowalczyk.info/software/vack"
								   attributes:urlAttr];

	[websiteUrl_ setAttributedTitle:url];
	[websiteUrl_ setShowsBorderOnlyWhileMouseInside:YES];

#if 0
    NSTableColumn *tableColumn = [[tableViewRecentSearches_  tableColumns] objectAtIndex:0];
    NSDictionary *titleStringAttr = [NSDictionary dictionaryWithObjectsAndKeys:
                                     NSFontAttributeName, [NSFont systemFontOfSize:28.0], nil];
    
    NSAttributedString *title = [[NSAttributedString alloc] initWithString:@"Recent searches:"
                                                                attributes:titleStringAttr];

    [[tableColumn headerCell] setTitle:title];
#endif
}

- (void)switchToFinishSearchingState {
    [searchButton_ setHidden:NO];
    [stopButton_ setHidden:YES];
    [searchTermField2_ setEnabled:YES];
    [dirField2_ setEnabled:YES];
    [[self window] makeFirstResponder:searchTermField2_];
}

- (void)switchToSearchInProgressState {
    [searchButton_ setHidden:YES];
    [stopButton_ setHidden:NO];
    [searchTermField2_ setEnabled:NO];
    [dirField2_ setEnabled:NO];
}

- (IBAction)showWindow:(id)sender {
    [self switchToMainView];
    [[self window] makeKeyAndOrderFront:sender];
}

- (BOOL)isSearchButtonEnabled {
    BOOL enabled = YES;
    if ([[searchTermField_ stringValue] length] == 0) {
        enabled = NO;
    }

    // TODO: handle multiple directories separated by ';'
    NSString *dir = [dirField_ stringValue];
    if ([dir length] ==0) {
        enabled = NO;
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:dir]) {
        [errorField_ setStringValue:[NSString stringWithFormat:@"'%@' is not a directory or file", dir]];
        [errorField_ setHidden:NO];
        enabled = NO;
    } else {
        [errorField_ setHidden:YES];
    }
    return enabled;
}

- (BOOL)isSearchButton2Enabled {
    BOOL enabled = YES;
    if ([[searchTermField2_ stringValue] length] == 0) {
        enabled = NO;
    }
    
    // TODO: handle multiple directories separated by ';'
    NSString *dir = [dirField2_ stringValue];
    if ([dir length] ==0) {
        enabled = NO;
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:dir]) {
		NSDisableScreenUpdates(); // otherwise we get flickering
		if (dirDoesntExistWindow_) {
			// need to re-crecreate the window to make sure it'll be of the right
			// size to match the dynamic text. Wish there was a simpler way by just
			// resizing the window.
			[[dirField2_ window] removeChildWindow:dirDoesntExistWindow_];
			[dirDoesntExistWindow_ orderOut:self];
			dirDoesntExistWindow_ = nil;
		}

		NSPoint p = NSMakePoint(NSMidX([dirField2_ frame]),
								NSMidY([dirField2_ frame]));

		[dirDoesntExistLabel_ setStringValue:[NSString stringWithFormat:@"'%@' is not a directory or file", dir]];
		[dirDoesntExistLabel_ sizeToFit];
		NSSize newViewSize = dirDoesntExistView_.bounds.size;
		newViewSize.width = dirDoesntExistLabel_.bounds.size.width + 32.0;
		[dirDoesntExistView_ setFrameSize:newViewSize];
		dirDoesntExistWindow_ = [[MAAttachedWindow alloc]
								 initWithView:dirDoesntExistView_
								 attachedToPoint:(NSPoint)p 
								 inWindow:[dirField2_ window] 
								 onSide:MAPositionBottom
								 atDistance:2.0];
		[[dirField2_ window] addChildWindow:dirDoesntExistWindow_ ordered:NSWindowAbove];
		NSEnableScreenUpdates();
		enabled = NO;
    } else {
		if (dirDoesntExistWindow_) {
			[[dirField2_ window] removeChildWindow:dirDoesntExistWindow_];
			[dirDoesntExistWindow_ orderOut:self];
			dirDoesntExistWindow_ = nil;
		}
    }
    return enabled;
}

- (void)updateSearchButtonStatus {
    [buttonSearch_ setEnabled:[self isSearchButtonEnabled]];
}

- (void)updateSearchButton2Status {
    [searchButton_ setEnabled:[self isSearchButton2Enabled]];
}

- (void)controlTextDidChange:(NSNotification*)aNotification {
    NSTextField *textField = [aNotification object];
    if (textField == searchTermField_ || textField == dirField_) {
        [self updateSearchButtonStatus];
    } else if (textField == searchTermField2_ || textField == dirField2_) {
        [self updateSearchButton2Status];
    } else {
        assert(0);
    }
}

// Sent by "Search" button in main view or pressing enter in search field
- (IBAction)search:(id)sender {
    if (![self isSearchButtonEnabled])
        return;

    NSString *searchTerm = [searchTermField_ stringValue];
    NSString *dir = [dirField_ stringValue];
    [self startSearch:searchTerm inDirectory:dir];
}

// Sent by "Search" button in results view or pressing enter in search field
- (IBAction)search2:(id)sender {
    if (![self isSearchButton2Enabled])
        return;

    NSString *searchTerm = [searchTermField2_ stringValue];
    NSString *dir = [dirField2_ stringValue];
    [self startSearch:searchTerm inDirectory:dir];    
}

- (IBAction)chooseDir:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setAllowsMultipleSelection:YES];
    [openPanel setAllowedFileTypes:nil];
    NSURL *url = [NSURL URLWithString:[dirField_ stringValue]];
    [openPanel setDirectoryURL:url];
    NSInteger res = [openPanel runModal];
    if (res != NSOKButton)
        return;
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
	assert(aTableView == tableViewRecentSearches_);
    return [recentSearches_ count] / 2;
}

- (id)tableView:(NSTableView *)aTableView 
    objectValueForTableColumn:(NSTableColumn *)aTableColumn
                          row:(int)rowIndex {
	assert(aTableView == tableViewRecentSearches_);
	NSUInteger count = [recentSearches_ count];
	// they are in reverse order
	assert(count >= rowIndex * 2);
	NSUInteger idx = count - ((rowIndex+1) * 2);
	NSString *searchTerm = [recentSearches_ objectAtIndex:idx];
	NSString *dir = [recentSearches_ objectAtIndex:idx+1];
	//NSRange searchTermRange = NSMakeRange(0, [searchTerm length]);
	NSString *s = [NSString stringWithFormat:@" %@\n %@", searchTerm, dir];
	NSMutableAttributedString *as = [[NSMutableAttributedString alloc] initWithString:s];
	NSRange dirRange = NSMakeRange([searchTerm length]+3, [dir length]);
	[as setAttributes:dirStringAttrs_ range:dirRange];
	return as;
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
	assert(tableView == tableViewRecentSearches_);
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
	[self updateSearchButtonStatus];
}

- (NSInteger)outlineView:(NSOutlineView*)outlineView numberOfChildrenOfItem:(id)item {
	assert(outlineView == searchResultsView_);
	if (nil == item) {
		return [searchResults_ count];
	}
	if ([item isKindOfClass:[SearchResultsFile class]]) {
		return [item childrenCount];
	}
	return 0;
}

- (BOOL)outlineView:(NSOutlineView*)outlineView isItemExpandable:(id)item {
	assert(outlineView == searchResultsView_);
	return [item isKindOfClass:[SearchResultsFile class]];
}

- (id)outlineView:(NSOutlineView*)outlineView child:(NSInteger)index ofItem:(id)item {
	assert(outlineView == searchResultsView_);
	if (nil == item) {
		return [searchResults_ objectAtIndex:index];
	}
	assert([item isKindOfClass:[SearchResultsFile class]]);
	SearchResultsFile* srf = (SearchResultsFile*)item;
	return [[srf children] objectAtIndex:index];
	
}

- (id)outlineView:(NSOutlineView*)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	assert(outlineView == searchResultsView_);
	if ([item isKindOfClass:[SearchResultsFile class]]) {
		return [[NSAttributedString alloc] initWithString:[item fileName]
											   attributes:filePathStringAttrs_];
	}
	assert([item isKindOfClass:[NSAttributedString class]]);
	return item;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
	assert(outlineView == searchResultsView_);
	return ![item isKindOfClass:[SearchResultsFile class]];
}

- (void)didSkipFileThreadSafe:(NSString*)filePath {
    //NSLog(@"didSkipFileThreadSafe %@", filePath);
    ++skippedFiles_;
    [self updateSearchStatus];
}

- (BOOL)didSkipFile:(NSString*)filePath {
    [self performSelectorOnMainThread:@selector(didSkipFileThreadSafe:)
                           withObject:filePath waitUntilDone:YES];
	return !forceSearchEnd_;
}

- (void)didSkipDirectoryThreadSafe:(NSString*)dirPath {
    ++skippedDirs_;
    [self updateSearchStatus];
    NSLog(@"didSkipDirectory %@", dirPath);
}

- (BOOL)didSkipDirectory:(NSString*)dirPath {
    NSLog(@"didSkipDirectory %@", dirPath);
    [self performSelectorOnMainThread:@selector(didSkipDirectoryThreadSafe:)
                           withObject:dirPath waitUntilDone:YES];
	return !forceSearchEnd_;
}

- (BOOL)didSkipNonExistent:(NSString*)path {
    NSLog(@"didSkipNonExistent %@", path);    
	return !forceSearchEnd_;
}

- (void)didStartSearchInFileThreadSafe:(NSString*)filePath {
    NSLog(@"didStartSearchInFile in %@", filePath);
    resultsInCurrentFile_ = 0;
    ++searchedFiles_;
    [self updateSearchStatus];
}

- (BOOL)didStartSearchInFile:(NSString*)filePath {
    [self performSelectorOnMainThread:@selector(didStartSearchInFileThreadSafe:)
                           withObject:filePath waitUntilDone:YES];
	return !forceSearchEnd_;
}

- (BOOL)didFinishSearchInFile:(NSString*)filePath {
    NSLog(@"didFinishSearchInFile in %@", filePath);
	return !forceSearchEnd_;
}

- (void)didFinishSearchThreadSafe:(id)ignore {
    [searchProgressIndicator_ stopAnimation:self];
    if (0 == [searchResults_ count]) {
        [textNoResultsFound_ setHidden:NO];
    }
    [self switchToFinishSearchingState];
}

- (void)didFinishSearch {
    [self performSelectorOnMainThread:@selector(didFinishSearchThreadSafe:)
                           withObject:nil waitUntilDone:YES];    
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
	SearchResultsFile *srf = nil;
    if (0 == resultsInCurrentFile_) {
		srf = [[SearchResultsFile alloc] initWithFileName:searchResult.filePath];
        [searchResults_ addObject:srf];
    } else {
		srf = [searchResults_ objectAtIndex:[searchResults_ count]-1];
	}
    NSMutableAttributedString *mas = [[NSMutableAttributedString alloc] initWithString:searchResult.line];
    setAttributedStringRanges(mas, searchResult.matchesCount, searchResult.matches, matchStringAttrs_);
	s = [NSString stringWithFormat:@"%d: ", (int)searchResult.lineNo];
    as = [[NSAttributedString alloc] initWithString:s attributes:lineNumberStringAttrs_];
    
    [mas insertAttributedString:as atIndex:0];
	[srf addResult:mas];
	[searchResultsView_ reloadData];
	if (0 == resultsInCurrentFile_) {
		[searchResultsView_ expandItem:srf];
	}
    ++resultsInCurrentFile_;
}

- (BOOL)didFind:(FileSearchResult*)searchResult {
    [self performSelectorOnMainThread:@selector(didFindThreadSafe:) withObject:searchResult waitUntilDone:YES];
	return !forceSearchEnd_;
}

// TODO: make it a stand-alone function or NSString category function
- (NSString*)pluralizedString:(NSString*)s withNumber:(int)num {
	if (1 == num) {
		return [NSString stringWithFormat:@"%d %@", num, s];
	} else {
		return [NSString stringWithFormat:@"%d %@s", num, s];
	}
}

- (void)updateSearchStatus {
    NSString *s = [NSString stringWithFormat:@"Searched %@. Skipped %@, %@.",
				   [self pluralizedString:@"file" withNumber:searchedFiles_],
				   [self pluralizedString:@"dir" withNumber:skippedDirs_],
				   [self pluralizedString:@"file" withNumber:skippedFiles_]];
    [textFieldStatus_ setStringValue:s];
}

- (BOOL)isFontBold {
    return YES;
}

- (void)switchToSearchResultsView {
	forceSearchEnd_ = NO;
    [textNoResultsFound_ setHidden:YES];
    [searchResults_ removeAllObjects];
    searchedFiles_ = 0;
    skippedDirs_ = 0;
    skippedFiles_ = 0;
	[tableViewRecentSearches_ reloadData];
    [[self window] setContentView:viewSearchResults_];
    [self updateSearchStatus];
}

- (void)switchToMainView {
    forceSearchEnd_ = YES;
    [[self window] setContentView:viewSearch_];
    [searchTermField_ setStringValue:@""];
    [dirField_ setStringValue:[@"~" stringByExpandingTildeInPath]];
    [[self window] makeFirstResponder:searchTermField_];
    [self updateSearchButtonStatus];
}

- (void)startSearch:(NSString*)searchTerm inDirectory:(NSString*)dir {
    [self switchToSearchInProgressState];
    [searchTermField2_ setStringValue:searchTerm];
    [dirField2_ setStringValue:dir];
    [self switchToSearchResultsView];
    [self rememberSearchFor:searchTerm inDirectory:dir];

	search_options opts;
	init_search_options(&opts);
	opts.search_term = strdup([searchTerm UTF8String]);
	add_search_location(&opts, [dir UTF8String]);
    
    // takes ownership of opts, so no freeing them here
    SearchOperation *op = [[SearchOperation alloc] initWithSearchOptions:opts delegate:self];
    [[VisualAckAppDelegate shared] addOperation:op];
    [searchProgressIndicator_ startAnimation:self];
}

- (void)startSearchForSearchOptions:(search_options)searchOptions {
    [self switchToSearchInProgressState];

	NSString *searchTerm = nil;
	NSString *dir = nil;
	if (searchOptions.search_term) {
		searchTerm = [NSString stringWithUTF8String:searchOptions.search_term];
		if (searchTerm) {
			[searchTermField2_ setStringValue:searchTerm];
		}
	}

	if ((searchOptions.search_loc_count > 0) && searchOptions.search_loc[0]) {
		dir = [NSString stringWithUTF8String:searchOptions.search_loc[0]];
	}
	if (dir) {
		[dirField2_ setStringValue:dir];
	}
    [self switchToSearchResultsView];

	if (searchTerm && dir) {
		[self rememberSearchFor:searchTerm inDirectory:dir];
	}

    SearchOperation *op = [[SearchOperation alloc] initWithSearchOptions:searchOptions delegate:self];
    [[VisualAckAppDelegate shared] addOperation:op];
    [searchProgressIndicator_ startAnimation:self];
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

- (IBAction)launchWebsite:(id)sender {
    [[NSWorkspace sharedWorkspace]
	 openURL:[NSURL URLWithString:@"http://blog.kowalczyk.info/software/vack/"]];
}

- (IBAction)stopSearch:(id)sender {
    forceSearchEnd_ = YES;
    [self switchToFinishSearchingState];
}

@end
