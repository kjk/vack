#import <Cocoa/Cocoa.h>

typedef struct {
    // filePath and line are just references, use immediately, don't release.
    // make a copy if need to keep around
    NSString *      filePath;
    NSString *      line;
    UInt64          lineOff;
    UInt64          lineNo;
    UInt32          lineLenBytes;
    NSRange         matchPos;
} FileSearchResult;
