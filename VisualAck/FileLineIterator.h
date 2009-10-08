#import <Cocoa/Cocoa.h>


@interface FileLineIterator : NSObject {
    NSString *	    path_;
    FILE *	    fp_;
    int		    currLineNo_;
}

- (id)initWithFileName:(NSString*)path;
- (NSString*)getNextLine:(int*)lineNo;

@end
