#import "SearchWindowController.h"

@implementation SearchWindowController

- (void) didSkipFile:(NSString*)filePath {
    NSLog(@"didSkipFile %@", filePath);
}

- (void) didSkipDirectory:(NSString*)dirPath {
    NSLog(@"didSkipDirectory %@", dirPath);
}

- (void) didFind:(FileSearchResult*)searchResult {
    NSLog(@"didFind");
}

- (void) didStartSearchInFile:(NSString*)filePath {
    NSLog(@"didStartSearchInFile in %@", filePath);
}

- (void) didFinishSearchInFile:(NSString*)filePath {
    NSLog(@"didFinishSearchInFile in %@", filePath);
}

@end
