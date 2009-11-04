#import "FileSearcher.h"
#import "FileSearchIterator.h"

// This list is based on ack
static NSString *dirsToIgnore[] = {
    // putting those at the top based on theory they are most likely
    // to be encountered
    @".svn",
    @"CVS",
    @".bzr",
    @".git",
    @"_build",
    @"build", // TODO: not present in ack (name of xcode's build directory)

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
- (void)buildDirsToIgnoreDict:(search_options*)opts;
@end

@implementation FileSearcher

static NSString *nonNilValue = @"dummyString";

// TODO: not sure what is the encoding of opts->ignore_dirs and 
// opts->no_ignore_dirs. It might be the charset (LC?) of shell
- (void)buildDirsToIgnoreDict:(search_options*)opts {
    int i;
    char **dirs;

    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:128];
    for (i=0; dirsToIgnore[i]; i++) {
        [dict setObject:nonNilValue forKey:dirsToIgnore[i]];
    }
    
    if (opts->ignore_dirs) {
        dirs = opts->ignore_dirs;
        for (i=0; dirs[i]; i++) {
            char *dirCStr = dirs[i];
            NSString *dir = [NSString stringWithUTF8String:dirCStr];
            [dict setObject:nonNilValue forKey:dir];	    
        }
    }
    
    if (opts->no_ignore_dirs) {
        dirs = opts->no_ignore_dirs;
        for (i=0; dirs[i]; i++) {
            char *dirCStr = dirs[i];
            NSString *dir = [NSString stringWithUTF8String:dirCStr];
            [dict removeObjectForKey:dir];
        }
    }

    dirsToIgnore_ = [dict retain];
}

- (id)initWithDirectory:(NSString*)path searchOptions:(search_options*)opts {
    self = [super init];
    if (!self)
        return nil;

    startDir_ = [path copy];
    searchPattern_ = [NSString stringWithUTF8String:opts->search_term];
    if (opts->ignore_dirs || opts->no_ignore_dirs) {
        [self buildDirsToIgnoreDict:opts];
    }
    return self;
}

- (void)dealloc {
    [dirsToIgnore_ release];
    [searchPattern_ release];
    [super dealloc];
}

- (void)setDelegate:(id <FileSearchProtocol>)delegate {
    delegate_ = delegate;
}

- (id <FileSearchProtocol>)delegate {
    return delegate_;
}

- (BOOL)shouldSkipDirectory:(NSString*)directory {
    if (dirsToIgnore_) {
        id val = [dirsToIgnore_ objectForKey:directory];
        return val != nil;
    } else {
        return shouldIgnoreDir(directory);
    }
}

- (BOOL)shouldSkipFile:(NSString*)fileName {
    return NO;
}

- (void)searchInFile:(NSString*)fileName {
    NSString *filePath = [startDir_ stringByAppendingPathComponent:fileName];
    FileSearchIterator *fileSearchIter = [FileSearchIterator fileSearchIteratorWithFileName:filePath searchPattern:searchPattern_];    
    [delegate_ didStartSearchInFile:filePath];
    FileSearchResult *searchResult;
    for (;;) {
        searchResult = [fileSearchIter getNextSearchResult];
        if (!searchResult)
            break;
        [delegate_ didFind:searchResult];
    }
    [delegate_ didFinishSearchInFile:filePath];
}

- (void)startSearch {
    NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager]
                                      enumeratorAtPath:startDir_];
    NSString *file;
    for (file in dirEnum) {
        NSDictionary *fileAttrs = [dirEnum fileAttributes];
        NSString* fileType = [fileAttrs valueForKey:NSFileType];
        if ([fileType isEqualToString:NSFileTypeRegular]) {
            if ([self shouldSkipFile:file]) {
            } else {
                [self searchInFile:file];
            }
        } else if ([fileType isEqualToString:NSFileTypeDirectory]) {
            if ([self shouldSkipDirectory:file]) {
                [delegate_ didSkipDirectory:file];
                [dirEnum skipDescendents];
            }
        } else {
            NSLog(@"unhandled type %@ for file %@", fileType, file);
        }
    }
}

@end
