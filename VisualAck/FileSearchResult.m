#import "FileSearchResult.h"

@implementation FileSearchResult

@synthesize filePath;
@synthesize line;
@synthesize lineOff;
@synthesize lineNo;
@synthesize lineLenBytes;
@synthesize matchesCount;

- (void)dealloc {
    [filePath release];
    [line release];
    [super dealloc];
}

- (NSRange*)matches {
    return matches_;
}

- (void)addMatch:(NSRange)match {
    if (matchesCount >= MAX_MATCHES_PER_LINE)
        return;
    matches_[matchesCount++] = match;
}

- (NSRange)matchAtIndex:(int)idx {
    return matches_[idx];
}

@end
