#import <Cocoa/Cocoa.h>
#import "FileLineIterator.h"

@class FileSearchResult;

@interface FileSearchIterator : FileLineIterator {
    NSString *	    searchPattern_;
}

+ (FileSearchIterator*) fileSearchIteratorWithFileName:(NSString*)path searchPattern:(NSString*)searchPattern;

- (id)initWithFileName:(NSString*)path searchPattern:(NSString*)searchPattern;

- (FileSearchResult*)getNextSearchResult;

@end
