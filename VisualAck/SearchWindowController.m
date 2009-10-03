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

- (void) didNotFind:(NSString*)filePath {
    NSLog(@"didNotFind %@", filePath);
}

@end
