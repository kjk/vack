#import <Cocoa/Cocoa.h>

#define FILE_BUF_SIZE 8*1024

@interface FileLineIterator : NSObject {
    NSString *	    path_;
    FILE *	    fp_;
    int		    currLineNo_;
    char	    buf_[FILE_BUF_SIZE];
    int		    posInBuf_;
    int		    charsInBuf_;
}

- (id)initWithFileName:(NSString*)path;
- (NSString*)getNextLine:(int*)lineNo;

@end
