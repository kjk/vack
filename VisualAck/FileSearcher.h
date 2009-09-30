#import <Cocoa/Cocoa.h>

#import "FileSearchProtocol.h"

@interface FileSearcher : NSObject {
    id <FileSearchProtocol>  delegate_;
}

-(void)setDelegate:(id <FileSearchProtocol>)delegate;
-(id <FileSearchProtocol>)delegate;
- (void)startSearch;

@end
