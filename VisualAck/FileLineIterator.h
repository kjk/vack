#import <Cocoa/Cocoa.h>

@interface FileLineIterator : NSObject {
    NSString *  path_;
    int         fd_;
    size_t      fileSize_;
    char *      fileStart_;
    char *      fileEnd_;
    char *      fileCurrPos_;
    int         currLineNo_;
    CFStringEncoding currentEncoding_;
}

+ (FileLineIterator*) fileLineIteratorWithFileName:(NSString*)path;
- (id)initWithFileName:(NSString*)path;
- (NSString*)getNextLine:(int*)lineNo;

@end
