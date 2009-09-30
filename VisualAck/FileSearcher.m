#import "FileSearcher.h"

@implementation FileSearcher

-(void)setDelegate:(id <FileSearchProtocol>)delegate {
    delegate_ = delegate;
}

-(id <FileSearchProtocol>)delegate {
    return delegate_;
}

- (void)startSearch {
    NSLog(@"startSearch");
}

@end
