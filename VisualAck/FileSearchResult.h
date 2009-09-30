#import <Cocoa/Cocoa.h>


@interface FileSearchResult : NSObject {
    NSString *	filePath_;
    int		lineNo_;
}

- (void)initWithFile:(NSString*)filePath: (int)lineNo;

@end
