
#import "FileSearchIterator.h"

#import <assert.h>
#import "RegexKitLite.h"

@implementation FileSearchIterator

+ (FileSearchIterator*) fileSearchIteratorWithFileName:(NSString*)path searchPattern:(NSString*)searchPattern {
    return [[FileSearchIterator alloc] initWithFileName:path searchPattern:searchPattern];    
}

- (void)dealloc {
    [searchPattern_ release];
    [super dealloc];
}

- (id)initWithFileName:(NSString*)path searchPattern:(NSString*)searchPattern {
    self = [super initWithFileName:path];
    if (!self)
	return nil;
    searchPattern_ = [searchPattern copy];
    return self;
}

- (void) buildSearchResult {
    currSearchResult_.line = currLine_;
    currSearchResult_.lineNo = currLineNo_;
    currSearchResult_.lineOff = 0; // TODO: don't have this info yet
    currSearchResult_.filePath = path_;
    currSearchResult_.matchPos = currMatchPos_;
}

- (FileSearchResult*)getNextSearchResult {
    for (;;) {
        currLine_ = [self getNextLine:&currLineNo_];
        if (!currLine_)
            return nil;
        currMatchPos_ = [currLine_ rangeOfRegex:searchPattern_];
        if (currMatchPos_.location != NSNotFound) {
            [self buildSearchResult];
            return &currSearchResult_;
        }
    }
}

@end