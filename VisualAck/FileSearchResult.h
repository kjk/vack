#import <Cocoa/Cocoa.h>

#define MAX_MATCHES_PER_LINE 16

@interface FileSearchResult : NSObject {
    // filePath and line are just references, use immediately, don't release.
    // make a copy if need to keep around
    NSString *      filePath;
    NSString *      line;
    UInt64          lineOff;
    UInt64          lineNo;
    UInt32          lineLenBytes;
    int             matchesCount;
    NSRange         matches_[MAX_MATCHES_PER_LINE];
}

- (void)addMatch:(NSRange)match;
- (NSRange)matchAtIndex:(int)idx;
- (NSRange*)matches;

@property (copy) NSString *filePath;
@property (copy) NSString *line;
@property (assign) UInt64 lineOff;
@property (assign) UInt64 lineNo;
@property (assign) UInt32 lineLenBytes;
@property (assign) int matchesCount;

@end
