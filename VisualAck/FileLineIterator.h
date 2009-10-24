#import <Cocoa/Cocoa.h>

#define FILE_BUF_SIZE 8*1024

@interface FileLineIterator : NSObject {
    NSString *	    path_;
    int		    fd_;
    size_t	    fileSize_;
    char *	    fileStart_;
    char *	    fileEnd_;
    char *	    fileCurrPos_;
    int		    currLineNo_;
}

+ (FileLineIterator*) fileLineIteratorWithFileName:(NSString*)path;
- (id)initWithFileName:(NSString*)path;
- (NSString*)getNextLine:(int*)lineNo;

@end
