
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

- (FileSearchResult*)getNextSearchResult {
    NSString *currLine;
    int lineNo;
    for (;;) {
	currLine = [self getNextLine:&lineNo];
	if (!currLine)
	    return nil;
	NSRange match = [currLine rangeOfRegex:searchPattern_];
	if (match.location == NSNotFound)
	    return nil;
	// TODO: return search result
    }
}

@end