#import <Cocoa/Cocoa.h>

#import "FileSearchResult.h"

@protocol FileSearchProtocol

- (void) didSkipFile:(NSString*)filePath;
- (void) didSkipDirectory:(NSString*)dirPath;
- (void) didFind:(FileSearchResult*)searchResult;
- (void) didNotFind:(NSString*)filePath;

@end
