#import <Cocoa/Cocoa.h>
#import "FileLineIterator.h"
#import "FileSearchResult.h"

@interface FileSearchIterator : FileLineIterator {
    NSString *          searchPattern_;
    NSString *          currLine_;
    FileSearchResult *  currSearchResult_;
    NSRange             currMatchPos_;
    int                 ignoreCase_;
}

+ (FileSearchIterator*) fileSearchIteratorWithFileName:(NSString*)path searchPattern:(NSString*)searchPattern;
- (id)initWithFileName:(NSString*)path searchPattern:(NSString*)searchPattern;
- (FileSearchResult*)getNextSearchResult;

@property (assign) int ignoreCase;

@end
