#import "FileSearchResult.h"

@implementation FileSearchResult

- (void)initWithFile:(NSString*)filePath: (int)lineNo {
    filePath_ = [filePath copy];
    lineNo_ = lineNo;
}

@end
