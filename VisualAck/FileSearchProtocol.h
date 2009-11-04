#import <Cocoa/Cocoa.h>

#import "FileSearchResult.h"

@protocol FileSearchProtocol

- (void) didSkipFile:(NSString*)filePath;
- (void) didSkipDirectory:(NSString*)dirPath;
- (void) didStartSearchInFile:(NSString*)filePath;
- (void) didFinishSearchInFile:(NSString*)filePath;
- (void) didFind:(FileSearchResult*)searchResult;

@end
