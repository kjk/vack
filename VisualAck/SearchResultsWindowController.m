#import "SearchResultsWindowController.h"

@implementation SearchResultsWindowController

- (void) didSkipFile:(NSString*)filePath {
    NSLog(@"didSkipFile %@", filePath);
}

- (void) didSkipDirectory:(NSString*)dirPath {
    NSLog(@"didSkipDirectory %@", dirPath);
}

- (void) didSkipNonExistent:(NSString*)path {
    NSLog(@"didSkipNonExistent %@", path);    
}

- (void) didStartSearchInFile:(NSString*)filePath {
    NSLog(@"didStartSearchInFile in %@", filePath);
}

- (void) didFinishSearchInFile:(NSString*)filePath {
    NSLog(@"didFinishSearchInFile in %@", filePath);
}

- (void) didFind:(FileSearchResult*)searchResult {
    NSLog(@"didFind");
}

@end
