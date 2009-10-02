#import "SearchWindowController.h"

@implementation SearchWindowController

- (void) didSkipFile:(NSString*)filePath {
    NSLog(@"didSkipFile %@", filePath);
}

- (void) didSkipDir:(NSString*)dirPath {
    NSLog(@"didSkipDir %@", dirPath);
}

- (void) didFind:(FileSearchResult*)searchResult {
    NSLog(@"didFind");
}

@end