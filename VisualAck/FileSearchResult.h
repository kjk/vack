#import <Cocoa/Cocoa.h>

#define MAX_MATCHES_PER_LINE 32

typedef struct {
    // filePath and line are just references, use immediately, don't release.
    // make a copy if need to keep around
    NSString *      filePath;
    NSString *      line;
    UInt64          lineOff;
    UInt64          lineNo;
    UInt32          lineLenBytes;
    int             matchesCount;
    NSRange         matches[MAX_MATCHES_PER_LINE];
} FileSearchResult;
