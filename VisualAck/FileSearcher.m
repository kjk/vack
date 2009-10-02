#import "FileSearcher.h"

@implementation FileSearcher

- (id)initWithDirectory:(NSString*)path {
    if ((self = [super init])) {
	startDir_ = [path copy];
    }
    return self;
}

- (void)setDelegate:(id <FileSearchProtocol>)delegate {
    delegate_ = delegate;
}

- (id <FileSearchProtocol>)delegate {
    return delegate_;
}

- (void)startSearch {
    NSLog(@"startSearch");
    NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:startDir_];
    NSString *file;
    for (file in dirEnum) {
	NSLog(@"file: %@", file);
    }
    NSLog(@"endSearch");
}

@end
