#import "SearchResultsWindowController.h"

#import "FileSearcher.h"
#import "FileSearchResult.h"

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

- (void)didFind:(FileSearchResult*)searchResult {
	NSString *s = [NSString stringWithFormat:@"%d: %@", (int)searchResult->lineNo, searchResult->line];
	[searchResults_ addObject:s];
	[tableView_ reloadData];
}

- (void)startSearch:(NSString*)searchTerm inDirectory:(NSString*)dir {
    NSWindow *window = [self window];
    [window makeKeyAndOrderFront:self];

	search_options opts;
	init_search_options(&opts);
	opts.search_term = strdup([searchTerm UTF8String]);
	add_search_location(&opts, [dir UTF8String]);

	// TODO: this should go on a thread
	FileSearcher *fileSearcher = [[FileSearcher alloc] initWithSearchOptions:&opts];
    [fileSearcher setDelegate:self];
    [fileSearcher startSearch];
    [fileSearcher release];
	free_search_options(&opts);
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
