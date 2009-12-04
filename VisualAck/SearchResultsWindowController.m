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
	NSLog(@"SearchResultsWindowController awakeFromNib from %p", (void*)self);
}

- (void)dealloc {
	[searchResults_ release];
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
    NSLog(@"didStartSearchInFile in %@", filePath);
}

- (void)didFinishSearchInFile:(NSString*)filePath {
    NSLog(@"didFinishSearchInFile in %@", filePath);
}

- (void)didFindThreadSafe:(FileSearchResult*)searchResult {
	NSString *s = [NSString stringWithFormat:@"%d: %@", (int)searchResult.lineNo, searchResult.line];
	[searchResults_ addObject:s];
	[tableView_ reloadData];
}

- (void)didFind:(FileSearchResult*)searchResult {
    [self performSelectorOnMainThread:@selector(didFindThreadSafe:) withObject:searchResult waitUntilDone:YES];
    // TODO: check if the user cancelled search and abort if he did by returning YES
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
