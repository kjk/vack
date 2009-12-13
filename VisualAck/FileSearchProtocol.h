#import <Cocoa/Cocoa.h>

#import "FileSearchResult.h"

@protocol FileSearchProtocol

- (BOOL)didSkipFile:(NSString*)filePath;
- (BOOL)didSkipDirectory:(NSString*)dirPath;
- (BOOL)didSkipNonExistent:(NSString*)path;
- (BOOL)didStartSearchInFile:(NSString*)filePath;
- (BOOL)didFinishSearchInFile:(NSString*)filePath;
- (BOOL)didFind:(FileSearchResult*)searchResult;
- (void)didFinishSearch;
@end
