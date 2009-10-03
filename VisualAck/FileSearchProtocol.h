#import <Cocoa/Cocoa.h>

@class FileSearchResult;

@protocol FileSearchProtocol

- (void) didSkipFile:(NSString*)filePath;
- (void) didSkipDirectory:(NSString*)dirPath;
- (void) didFind:(FileSearchResult*)searchResult;
- (void) didNotFind:(NSString*)filePath;

@end
