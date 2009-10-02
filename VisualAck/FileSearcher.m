#import "FileSearcher.h"

@interface FileSearcher(Private)
- (BOOL)shouldSkipDirectory:(NSString*)directory;
@end

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

- (BOOL)shouldSkipDirectory:(NSString*)directory {
    // TODO: write me. Skip .git, .svn etc.
    return NO;
}

- (void)startSearch {
    NSLog(@"startSearch");
    NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:startDir_];
    NSString *file;
    for (file in dirEnum) {
	NSDictionary *fileAttrs = [dirEnum fileAttributes];
	NSString* fileType = [fileAttrs valueForKey:NSFileType];
	if ([fileType isEqualToString:NSFileTypeRegular]) {
	    NSLog(@"file     : %@", file);
	} else if ([fileType isEqualToString:NSFileTypeDirectory]) {
	    NSLog(@"directory: %@", file);
	    if ([self shouldSkipDirectory:file]) {
		[dirEnum skipDescendents];
	    }
	} else {
	    NSLog(@"unhandled type %@ for file %@", fileType, file);
	}
    }
    NSLog(@"endSearch");
}

@end
