
#import "FileSearchIterator.h"
#import <assert.h>

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
    return nil;
}

@end