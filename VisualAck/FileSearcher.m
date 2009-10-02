#import "FileSearcher.h"

// This list is based on ack
static NSString *dirsToIgnore[] = {
    // putting those at the top based on theory they are most likely
    // to be encountered
    @".svn",
    @"CVS",
    @".bzr",
    @".git",
    @"_build",

    @".cdv",
    @"~.dep",
    @"~.dot",
    @"~.nib",
    @"~.plst",
    @".hg",
    @".pc",
    @"blib",
    @"RCS",
    @"SCCS",
    @"_darcs",
    @"_sgbak",
    @"autom4te.cache",
    @"cover_db",
    nil
};

// TODO: this should also take --[no]ignore-dir=name into account
// Probably should use hash, filled with default values if no --[no]ignore-dir
// args and apropriately changed
static BOOL shouldIgnoreDir(NSString *dir) {
    for (int i=0; dirsToIgnore[i]; i++) {
        NSString *dirToIgnore = dirsToIgnore[i];
        if (NSOrderedSame == [dir caseInsensitiveCompare:dirToIgnore]) {
            return YES;
        }
    }
    return NO;
}

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
    return shouldIgnoreDir(directory);
}

- (void)startSearch {
    NSLog(@"startSearch");
    NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager]
                                      enumeratorAtPath:startDir_];
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
