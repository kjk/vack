
#import "FileSearchIterator.h"

#import <assert.h>
#import "RegexKitLite.h"

@implementation FileSearchIterator

@synthesize ignoreCase = ignoreCase_;

+ (FileSearchIterator*)fileSearchIteratorWithFileName:(NSString*)path searchPattern:(NSString*)searchPattern {
    return [[FileSearchIterator alloc]
            initWithFileName:path 
            searchPattern:searchPattern];
}

- (id)initWithFileName:(NSString*)path searchPattern:(NSString*)searchPattern {
    self = [super initWithFileName:path];
    if (!self) return nil;
    searchPattern_ = [searchPattern copy];
    ignoreCase_ = 0;
    return self;
}

- (void)addSearchResult {
    if (nil == currSearchResult_) {
        currSearchResult_ = [[FileSearchResult alloc] init];

        currSearchResult_.line = currLine_;
        currSearchResult_.lineNo = currLineNo_;
        currSearchResult_.lineOff = 0; // TODO: don't have this info yet
        currSearchResult_.filePath = path_;
    }
    [currSearchResult_ addMatch:currMatchPos_];
}

- (BOOL)collectMatches {
    int lineLen = [currLine_ length];
    NSRange toSearchRange;
    toSearchRange.location = 0;
    toSearchRange.length = lineLen;
    // TODO: this could be done once and options kept as instance variable
    RKLRegexOptions options = RKLNoOptions;
    if (self.ignoreCase) {
        options |= RKLCaseless;
    }
    for (;;) {
        currMatchPos_ = [currLine_ rangeOfRegex:searchPattern_ 
                                        options:options 
                                        inRange:toSearchRange 
                                        capture:0 
                                          error:nil];
        if (currMatchPos_.location == NSNotFound)
            break;
        [self addSearchResult];
        toSearchRange.location = currMatchPos_.location + currMatchPos_.length;
        toSearchRange.length = lineLen - toSearchRange.location;
    }
    return currSearchResult_ != nil;
}

- (FileSearchResult*)getNextSearchResult {
    currSearchResult_ = nil;
    for (;;) {
        currLine_ = [self getNextLine:&currLineNo_];
        if (!currLine_)
            return nil;
        if ([self collectMatches]) {
            return currSearchResult_;
        }
    }
}

@end