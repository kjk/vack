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

- (id)initWithSearchOptions:(search_options*)opts {
    self = [super init];
    if (!self)
        return nil;

    opts_ = opts;
    searchPattern_ = [[NSString stringWithUTF8String:opts->search_term] retain];
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

- (BOOL)searchFile:(NSString*)fileName inDir:(NSString*)dir {   
    NSString *filePath;
	BOOL cont;
    if (dir) {
        filePath = [dir stringByAppendingPathComponent:fileName];
    } else {
        filePath = fileName;
    }
    FileSearchIterator *fileSearchIter = [FileSearchIterator fileSearchIteratorWithFileName:filePath searchPattern:searchPattern_];    
    [delegate_ didStartSearchInFile:filePath];
    FileSearchResult *searchResult;
    for (;;) {
        searchResult = [fileSearchIter getNextSearchResult];
        if (!searchResult)
            break;
        cont = [delegate_ didFind:searchResult];
		if (!cont) {
			return NO;
		}
    }
    return [delegate_ didFinishSearchInFile:filePath];
}

- (BOOL)searchDir:(NSString*)dir withParent:(NSString*)parentDir {
    // Need auto-release pool with tighter scope because inside we alloc
    // FileLineIterator which needs fd and we need to force closing those
    // file descriptors befre we accumulate too many
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    BOOL result = YES;
	NSDictionary *fileAttrs;
    assert(parentDir);
	NSFileManager *fm = [[[NSFileManager alloc] init] autorelease];
    NSString *fullDirPath = [parentDir stringByAppendingPathComponent:dir];
	NSArray *entries = [fm contentsOfDirectoryAtPath:fullDirPath error:nil];
	if (!entries) {
		NSLog(@"Couldn't enumerate directory %@", fullDirPath);
        goto Exit;
	}
	BOOL cont;
	for (NSString *file in entries) {
        NSString *fullPath = [fullDirPath stringByAppendingPathComponent:file];
		NSError *err;
		fileAttrs = [fm attributesOfItemAtPath:fullPath error:&err];
		if (!fileAttrs) {
			NSLog(@"%@ NOT FOUND\n", fullPath);
			//NSLog(@"err=%@", err);
			continue;
		}
        NSString* fileType = [fileAttrs valueForKey:NSFileType];
        if ([fileType isEqualToString:NSFileTypeRegular]) {
            //NSLog(@"%@", fullPath);
            if ([self shouldSkipFile:file]) {
            } else {
                cont = [self searchFile:file inDir:fullDirPath];
				if (!cont) {
                    result = NO;
                    goto Exit;
				}
            }
        } else if ([fileType isEqualToString:NSFileTypeDirectory]) {
            //NSLog(@"%@", fullPath);
            if ([self shouldSkipDirectory:file]) {
                cont = [delegate_ didSkipDirectory:fullDirPath];
				if (!cont) {
                    result = NO;
                    goto Exit;
				}
            } else {
				cont = [self searchDir:file withParent:fullDirPath];
				if (!cont) {
                    result = NO;
                    goto Exit;
				}
			}
        } else {
            NSLog(@"unhandled type %@ for file %@", fileType, fullPath);
        }
		
	}
Exit:
    [pool drain];
	return result;
}

- (BOOL)searchDir:(NSString*)dir {
    NSString *cwd = [[NSFileManager defaultManager] currentDirectoryPath];
	return [self searchDir:dir withParent:cwd];
}

#if 0
- (BOOL)searchDir:(NSString*)dir {
    NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager]
                                      enumeratorAtPath:dir];
    NSString *file;
	BOOL cont;
    for (file in dirEnum) {
		//printf("file: %s\n", [file UTF8String]);
        NSDictionary *fileAttrs = [dirEnum fileAttributes];
        NSString* fileType = [fileAttrs valueForKey:NSFileType];
        if ([fileType isEqualToString:NSFileTypeRegular]) {
            if ([self shouldSkipFile:file]) {
            } else {
                cont = [self searchFile:file inDir:dir];
				if (!cont) {
					return NO;
				}
            }
        } else if ([fileType isEqualToString:NSFileTypeDirectory]) {
            if ([self shouldSkipDirectory:file]) {
                cont = [delegate_ didSkipDirectory:file];
				if (!cont) {
					return NO;
				}
                [dirEnum skipDescendents];
            }
        } else {
            NSLog(@"unhandled type %@ for file %@", fileType, file);
        }
    }
	return YES;
}
#endif

- (void)doSearch {
    int i;
    NSFileManager *fm = [NSFileManager defaultManager];
	BOOL cont;
    for (i = 0; i < opts_->search_loc_count; i++) {
        char *s = opts_->search_loc[i];
        NSString *dirOrFile = [NSString stringWithUTF8String:s];
        BOOL isDir = NO;
        if (![fm fileExistsAtPath:dirOrFile isDirectory:&isDir]) {
            cont = [delegate_ didSkipNonExistent:dirOrFile];
			if (!cont) {
				goto Exit;
			}
            continue;
        }
        if (isDir) {
			cont = [self searchDir:dirOrFile];
        } else {
            cont = [self searchFile:dirOrFile inDir:nil];
        }
		if (!cont) {
			goto Exit;
		}
    }
Exit:
    [delegate_ didFinishSearch];
}

@end
