#import "SearchResultsWindowController.h"

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

@implementation SearchResultsWindowController

- (void)awakeFromNib {
	searchResults_ = [[NSMutableArray arrayWithCapacity:100] retain];
    NSColor *filePathColor = [NSColor redColor];
    filePathStringAttrs_ = [NSDictionary dictionaryWithObject:filePathColor
                                                       forKey:NSForegroundColorAttributeName];
    [filePathStringAttrs_ retain];
    NSColor *matchColor = [NSColor blueColor];
    matchStringAttrs_ = [NSDictionary dictionaryWithObject:matchColor 
                                                          forKey:NSBackgroundColorAttributeName];
    [matchStringAttrs_ retain];
	NSLog(@"SearchResultsWindowController awakeFromNib from %p", (void*)self);
}

- (void)dealloc {
	[searchResults_ release];
    [filePathStringAttrs_ release];
    [matchStringAttrs_ release];
	[super dealloc];
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

- (void)windowWillClose:(NSNotification *)notification {
    assert([self window] == [notification object]);
    [[VisualAckAppDelegate shared] showSearchWindow:self];
}

- (void)startSearch:(NSString*)searchTerm inDirectory:(NSString*)dir {
    NSWindow *window = [self window];
    [window makeKeyAndOrderFront:self];

	search_options opts;
	init_search_options(&opts);
	opts.search_term = strdup([searchTerm UTF8String]);
	add_search_location(&opts, [dir UTF8String]);

    // takes ownership of opts, so no freeing them here
    SearchOperation *op = [[SearchOperation alloc] initWithSearchOptions:opts delegate:self];
    [[VisualAckAppDelegate shared] addOperation:op];
    [op release];
}

- (BOOL)tableView:(NSTableView*)aTableView isGroupRow:(NSInteger)row {
    return YES;
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	int count = [searchResults_ count];
	return count;
}

- (id)tableView:(NSTableView *)aTableView 
objectValueForTableColumn:(NSTableColumn *)aTableColumn
			row:(int)rowIndex {
	return [searchResults_ objectAtIndex:rowIndex];
}

@end
