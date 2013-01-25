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

static NSString *fileTypes[] = {
    @"actionscript", @"as", @"mxml", nil,
    @"ada", @"ada", @"adb", @"ads", nil,
    @"asm", @"asm", @"s", nil,
    @"batch", @"bat", @"cmd", nil,
//    @"binary      => q{Binary files, as defined by Perl's -B op (default: off)},
    @"cc", @"c", @"h", @"xs", nil,
    @"cfmx", @"cfc", @"cfm", @"cfml", nil,
    @"cpp", @"cpp", @"cc", @"cxx", @"m", @"hpp", @"hh", @"h", @"hxx", nil,
    @"csharp", @"cs", nil,
    @"css", @"css", nil,
    @"elisp", @"el", nil,
    @"erlang", @"erl", @"hrl", nil,
    @"fortran", @"f", @"f77", @"f90", @"f95", @"f03", @"for", @"ftn", @"fpp", nil,
	@"go", @"go", nil,
    @"haskell", @"hs", @"lhs", nil,
    @"hh", @"h", nil,
    @"html", @"htm", @"html", @"shtml", @"xhtml", nil,
    @"java", @"java", @"properties", nil,
    @"js", @"js", nil,
    @"jsp", @"jsp", @"jspx", @"jhtm", @"jhtml", nil,
    @"lisp", @"lisp", @"lsp", nil,
    @"lua", @"lua", nil,
//    @"make        => q{Makefiles},
    @"mason", @"mas", @"mhtml", @"mpl", @"mtxt", nil,
    @"objc", @"m", @"h", nil,
    @"objcpp", @"mm", @"h", nil,
    @"ocaml", @"ml", @"mli", nil,
    @"parrot" @"pir", @"pasm", @"pmc", @"ops", @"pod", @"pg", @"tg", nil,
    @"perl", @"pl", @"pm", @"pod", @"t", nil,
    @"php", @"php", @"phpt", @"php3", @"php4", @"php5", nil,
    @"plone", @"pt", @"cpt", @"metadata", @"cpy", @"py", nil,
    @"python", @"py", nil,
//    @"rake        => q{Rakefiles},
    @"ruby", @"rb", @"rhtml", @"rjs", @"rxml", @"erb", @"rake", nil,
    @"scala", @"scala", nil,
    @"scheme", @"scm", @"ss", nil,
    @"shell", @"sh", @"bash", @"csh", @"tcsh", @"ksh", @"zsh", nil,
//    @"skipped     => q{Files, but not directories, normally skipped by ack (default: off)},
    @"smalltalk", @"st", nil,
    @"sql", @"sql", @"ctl", nil,
    @"tcl", @"tcl", @"itcl", @"itk", nil,
    @"tex", @"tex", @"cls", @"sty", nil,
    @"text", @"txt", nil,
    @"tt", @"tt", @"tt2", @"ttml", nil,
    @"vb", @"bas", @"cls", @"frm", @"ctl", @"vb", @"resx", nil,
    @"vim", @"vim", nil,
    @"yaml", @"yaml", @"yml", nil,
    @"xml", @"xml", @"dtd", @"xslt", @"ent", @"xib", nil,
    nil
};

static BOOL shouldIgnoreDir(NSString* dir) {
    for (int i=0; dirsToIgnore[i]; i++) {
        NSString *dirToIgnore = dirsToIgnore[i];
        if (NSOrderedSame == [dir caseInsensitiveCompare:dirToIgnore]) {
            return YES;
        }
    }
    return NO;
}

static NSArray *getTypes(NSString* fileName) {
    int i = 0;
    NSMutableArray *types = [[NSMutableArray alloc] init];
    NSString* e;
    NSString* type;

    if (0 == [fileName caseInsensitiveCompare:@"makefile"]) {
        [types addObject:@"make"];
        [types addObject:@"text"];
        return types;
    }

    if (0 == [fileName caseInsensitiveCompare:@"rakefile"]) {
        [types addObject:@"rake"];
        [types addObject:@"ruby"];
        [types addObject:@"text"];
        return types;
    }
    
    NSString *ext = [fileName pathExtension];
    while (fileTypes[i]) {
        type = fileTypes[i++];
        while (fileTypes[i]) {
            e = fileTypes[i++];
            if (0 == [e caseInsensitiveCompare:ext]) {
                [types addObject:type];
            }
        }
        i++;
    }
    return types;
}

static BOOL isSearchable(NSString* fileName) {

    NSString *fileNameLowercase = [fileName lowercaseString];
    if ([fileNameLowercase hasSuffix:@"bak"]) {
        return NO;
    }
    if ([fileNameLowercase hasPrefix:@"~"]) {
        return NO;
    }
    if ([fileNameLowercase hasPrefix:@"#"] &&
        [fileNameLowercase hasSuffix:@"#"]) {
        return NO;
    }
    if ([fileNameLowercase hasPrefix:@"core."]) {
        return NO;
    }
    if ([fileNameLowercase hasSuffix:@".swp"] &&
        ([fileNameLowercase hasPrefix:@"."] ||
         ([fileNameLowercase hasPrefix:@"_"]))) {
            return NO;
    }
    
    return YES;
}

static BOOL isInteresting(NSString* fileName) {
    if ([fileName hasPrefix:@"."]) {
        return NO;
    }
    if (!isSearchable(fileName)) {
        return NO;
    }
    NSArray *arr = getTypes(fileName);
    if ([arr count] > 0) {
        return YES;
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

    dirsToIgnore_ = dict;
}

- (id)initWithSearchOptions:(search_options*)opts {
    self = [super init];
    if (!self)
        return nil;

    opts_ = opts;
    searchPattern_ = [NSString stringWithUTF8String:opts->search_term];
    if (opts->ignore_dirs || opts->no_ignore_dirs) {
        [self buildDirsToIgnoreDict:opts];
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
    if (dirsToIgnore_) {
        id val = [dirsToIgnore_ objectForKey:directory];
        return val != nil;
    } else {
        return shouldIgnoreDir(directory);
    }
}

- (BOOL)shouldSkipFile:(NSString*)fileName {
    return !isInteresting(fileName);
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
    fileSearchIter.ignoreCase = opts_->ignore_case;
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

#if 1
- (BOOL)searchDir:(NSString*)dir withParent:(NSString*)parentDir {
    // Need auto-release pool with tighter scope because inside we alloc
    // FileLineIterator which needs fd and we need to force closing those
    // file descriptors befre we accumulate too many
    BOOL result = YES;
	NSDictionary *fileAttrs;
	NSFileManager *fm = [[NSFileManager alloc] init];
    NSString *fullDirPath = dir;
    if (parentDir) {
        fullDirPath = [parentDir stringByAppendingPathComponent:dir];
    }
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
                [delegate_ didSkipFile:fullDirPath];
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
        } else if ([fileType isEqualToString:NSFileTypeSymbolicLink]) {
			// do nothing, we ignore symbolic links
		} else
		{
            NSLog(@"unhandled type %@ for file %@", fileType, fullPath);
        }
		
	}
Exit:
	return result;
}

- (BOOL)searchDir:(NSString*)dir {
    NSString *cwd = nil;
    if ([dir characterAtIndex:0] != '/') {
        // for non-absolute paths consider them relative to current directory
        cwd = [[NSFileManager defaultManager] currentDirectoryPath];
    }
	return [self searchDir:dir withParent:cwd];
}
#endif

#if 0
- (BOOL)searchDir:(NSString*)dir {
    // Need auto-release pool with tighter scope because inside we alloc
    // FileLineIterator which needs fd and we need to force closing those
    // file descriptors befre we accumulate too many
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    BOOL result = YES;

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
                    result = NO;
                    goto Exit;
				}
            }
        } else if ([fileType isEqualToString:NSFileTypeDirectory]) {
            if ([self shouldSkipDirectory:file]) {
                cont = [delegate_ didSkipDirectory:file];
				if (!cont) {
                    result = NO;
                    goto Exit;
				}
                [dirEnum skipDescendents];
            }
        } else {
            NSLog(@"unhandled type %@ for file %@", fileType, file);
        }
    }
Exit:
    [pool drain];
	return result;
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
			cont = [self searchDir:@"." withParent:dirOrFile];
        } else {
            if (isInteresting(dirOrFile)) {
                cont = [self searchFile:dirOrFile inDir:nil];
            } else {
                [delegate_ didSkipFile:dirOrFile];
                cont = YES;
            }
        }
		if (!cont) {
			goto Exit;
		}
    }
Exit:
    [delegate_ didFinishSearch];
}

@end
