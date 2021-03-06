#import <Cocoa/Cocoa.h>

#import "FileSearchProtocol.h"
#import "FileSearcher.h"
#import "PrefKeys.h"
#include <sys/stat.h>
#include <mach-o/dyld.h>
#include "ProgramVersion.h"

/*
 Usage: ack [OPTION]... PATTERN [FILE]
 
 Search for PATTERN in each source file in the tree from cwd on down.
 If [FILES] is specified, then only those files/directories are checked.
 ack may also search STDIN, but only if no FILE are specified, or if
 one of FILES is "-".
 
 Default switches may be specified in ACK_OPTIONS environment variable or
 an .ackrc file. If you want no dependency on the environment, turn it
 off with --noenv.
 
 Example: ack -i select
 
 Searching:
 --[no]smart-case      Ignore case distinctions in PATTERN,
 only if PATTERN contains no upper case
 Ignored if -i is specified
 -v, --invert-match    Invert match: select non-matching lines
 -w, --word-regexp     Force PATTERN to match only whole words
 -Q, --literal         Quote all metacharacters; PATTERN is literal
 
 Search output:
 --line=NUM            Only print line(s) NUM of each file
 -l, --files-with-matches
 Only print filenames containing matches
 -L, --files-without-match
 Only print filenames with no match
 -o                    Show only the part of a line matching PATTERN
 (turns off text highlighting)
 --passthru            Print all lines, whether matching or not
 --output=expr         Output the evaluation of expr for each line
 (turns off text highlighting)
 --match PATTERN       Specify PATTERN explicitly.
 -m, --max-count=NUM   Stop searching in each file after NUM matches
 -1                    Stop searching after one match of any kind
 -H, --with-filename   Print the filename for each match
 -h, --no-filename     Suppress the prefixing filename on output
 -c, --count           Show number of lines matching per file
 
 -A NUM, --after-context=NUM
 Print NUM lines of trailing context after matching
 lines.
 -B NUM, --before-context=NUM
 Print NUM lines of leading context before matching
 lines.
 -C [NUM], --context[=NUM]
 Print NUM lines (default 2) of output context.
 
 --print0              Print null byte as separator between filenames,
 only works with -f, -g, -l, -L or -c.
 
 File presentation:
 --pager=COMMAND       Pipes all ack output through COMMAND.
 Ignored if output is redirected.
 --nopager             Do not send output through a pager.  Cancels any
 setting in ~/.ackrc, ACK_PAGER or ACK_PAGER_COLOR.
 --[no]heading         Print a filename heading above each file's results.
 (default: on when used interactively)
 --[no]break           Print a break between results from different files.
 (default: on when used interactively)
 --group               Same as --heading --break
 --nogroup             Same as --noheading --nobreak
 --flush               Flush output immediately, even when ack is used
 non-interactively (when output goes to a pipe or
 file).
 
 File finding:
 -f                    Only print the files found, without searching.
 The PATTERN must not be specified.
 -g REGEX              Same as -f, but only print files matching REGEX.
 --sort-files          Sort the found files lexically.
 
 File inclusion/exclusion:
 -a, --all-types       All file types searched;
 Ignores CVS, .svn and other ignored directories
 -u, --unrestricted    All files and directories searched
 --[no]ignore-dir=name Add/Remove directory from the list of ignored dirs
 -n                    No descending into subdirectories
 -G REGEX              Only search files that match REGEX
 
 --perl                Include only Perl files.
 --type=perl           Include only Perl files.
 --noperl              Exclude Perl files.
 --type=noperl         Exclude Perl files.
 See "ack --help type" for supported filetypes.
 
 --type-set TYPE=.EXTENSION[,.EXT2[,...]]
 Files with the given EXTENSION(s) are recognized as
 being of type TYPE. This replaces an existing
 definition for type TYPE.
 --type-add TYPE=.EXTENSION[,.EXT2[,...]]
 Files with the given EXTENSION(s) are recognized as
 being of (the existing) type TYPE
 
 --[no]follow          Follow symlinks.  Default is off.
 
 Directories ignored by default:
 autom4te.cache, blib, _build, .bzr, .cdv, cover_db, CVS, _darcs, ~.dep,
 ~.dot, .git, .hg, ~.nib, .pc, ~.plst, RCS, SCCS, _sgbak and .svn
 
 Files not checked for type:
 /~$/           - Unix backup files
 /#.+#$/        - Emacs swap files
 /[._].*\.swp$/ - Vi(m) swap files
 /core\.\d+$/   - core dumps
 
 Miscellaneous:
 --noenv               Ignore environment variables and ~/.ackrc
 --man                 Man page
 --thpppt              Bill the Cat
 
 Exit status is 0 if match, 1 if no match.
*/

/* Implemented:
 --version             Display version & copyright
 --help                This help
 -i, --ignore-case     Ignore case distinctions in PATTERN

 --[no]color           Highlight the matching text (default: on unless
 output is redirected, or on Windows)
 --[no]colour          Same as --[no]color
*/

#define LOG_SEARCH 0

typedef enum {
    ANSI_COLOR_RESET = 0,
    ANSI_COLOR_FILE,
    ANSI_COLOR_MATCH
} AnsiColor;

// order must match AnsiColor enum
static NSString *ansiColors[] = {
    @"\x1b[0m",
    @"\x1b[1;32m",
    @"\x1b[30;43m",
};

static NSString *ansiColor(AnsiColor col) {
    return ansiColors[col];
}

/* returns NSString that has part of <s> in a given <range> wrapped in a given
   ansi <color> */
static NSString *wrapStringRangesInColor(NSString *s, int rangesCount, NSRange *ranges, NSString *color)
{
    int locOffset = 0;
    NSString *sWrapped = s;
    NSString *colorReset = ansiColor(ANSI_COLOR_RESET);
    for (int i=0; i < rangesCount; i++)
    {
        NSRange range = ranges[i];
        range.location += locOffset;
        NSUInteger len = [sWrapped length];
        NSUInteger rangeLastPos = range.location + range.length;
        assert(rangeLastPos <= len);
        NSString *before = @"";
        NSString *after = @"";
        if (range.location > 0) {
            before = [sWrapped substringToIndex:range.location];
        }
        NSString *toWrap = [sWrapped substringWithRange:range];
        if (len > rangeLastPos) {
            after = [sWrapped substringFromIndex:rangeLastPos];
        }
        sWrapped = [NSString stringWithFormat:@"%@%@%@%@%@", before, color, toWrap, 
                colorReset, after];
        locOffset = locOffset + [color length] + [colorReset length];
    }
    return sWrapped;
}
#if LOG_SEARCH
#define LogSearch printf
#else
#define LogSearch(...) {}
#endif

@interface SearchResults : NSObject <FileSearchProtocol>
{
    NSString *  currFilePath_;
    int         resultsCount_;
    search_options opts_;
}

- (void)setSearchOptions:(search_options*)opts;
@end

@implementation SearchResults

- (void)setSearchOptions:(search_options*)opts {
    // shallow copy, we don't need to free it
    opts_ = *opts;
}

- (BOOL)didSkipFile:(NSString*)filePath {
#pragma unused(filePath)
    LogSearch("didSkipFile %s\n", [filePath UTF8String]);
	return YES;
}

- (BOOL)didSkipDirectory:(NSString*)dirPath {
#pragma unused(dirPath)
    LogSearch("didSkipDirectory %s\n", [dirPath UTF8String]);
	return YES;
}

- (BOOL)didSkipNonExistent:(NSString*)path {
#pragma unused(path)
    LogSearch("didSkipNonExistent %s\n", [path UTF8String]);
	return YES;
}

- (BOOL)didFind:(FileSearchResult*)searchResult {
    if (0 == resultsCount_) {
        if (opts_.color) {
            NSString *fileColored = [NSString stringWithFormat:@"%@%@%@", ansiColor(ANSI_COLOR_FILE), currFilePath_, ansiColor(ANSI_COLOR_RESET)];
            printf("%s\n", [fileColored UTF8String]);
        } else {
            printf("%s\n", [currFilePath_ UTF8String]);
        }
    }
    if (opts_.color) {
        NSString *toPrint = wrapStringRangesInColor(searchResult.line, searchResult.matchesCount, searchResult.matches, ansiColor(ANSI_COLOR_MATCH));
        printf("%s\n", [toPrint UTF8String]);
    } else {
        printf("%s\n", [searchResult.line UTF8String]);
    }
    ++resultsCount_;
	return YES;
}

- (BOOL)didStartSearchInFile:(NSString*)filePath {
    assert(!currFilePath_);
    currFilePath_ = [filePath copy];
    resultsCount_ = 0;
	return YES;
}

- (BOOL)didFinishSearchInFile:(NSString*)filePath {
#pragma unused(filePath)
    currFilePath_ = nil;
	return YES;
}

- (void)didFinishSearch {
}

@end

static void print_version() {
    printf("vack %s\n", VACK_PROGRAM_VERSION);
}

static void print_help() {
    printf("Usage: vack [OPTION]... PATTERN [FILE]\n");
    printf("\n");
    printf("Example: vack -i foo\n");
    printf("\n");
    printf("Searching:\n");
    printf("  -i, --ignore-case     Ignore case distinctions in PATTERN\n");
    printf("File presentation:\n");
    printf("  --[no]color           Highlight the matching text (default: on unless\n");
    printf("                        output is redirected)\n");
    printf("  --[no]colour          Same as --[no]color\n");
    printf("\n");
    printf("Miscellaneous:\n");
    printf("  --help                This help\n");
    printf("  --version             Display version & copyright\n");
    printf("\n");
    printf("This is version %s of vack.\n", VACK_PROGRAM_VERSION);
}

static void incSearchCount(void)
{
    CFStringRef appId = CFSTR("info.kowalczyk.visualack");
    CFStringRef keyStr = (__bridge CFStringRef)PREF_SEARCH_COUNT;
    CFPropertyListRef val = CFPreferencesCopyAppValue(keyStr, appId);
    NSNumber *newVal;
    if (val == NULL) {
        newVal = [NSNumber numberWithInteger:1];
    } else {
        NSInteger n = 0;
        Boolean ok = CFNumberGetValue(val, kCFNumberNSIntegerType, &n);
        if (!ok || 0 == n) {
            // if we failed or have number has suspicious value (0), don't touch
            // property
            CFRelease(val);
            return;
        }
        newVal = [NSNumber numberWithInteger:n+1];
    }
    CFPreferencesSetAppValue(keyStr, (__bridge CFPropertyListRef)newVal, appId);
    if (val) CFRelease(val);
    CFPreferencesAppSynchronize(appId);
}

static int fileExists(const char *path)
{
	struct stat buf;
	int res;
	res = stat(path, &buf);
	if (-1 == res) {
		return FALSE;
	}
	if ((buf.st_mode & S_IFREG) != S_IFREG) {
		return FALSE;
	}
	return TRUE;
}

static void removeFromLastCharOf(char *s, char c) {
	char *lastPos = NULL;
	while (*s) {
		if (c == *s) {
			lastPos = s;
		}
		++s;
	}

	if (lastPos) {
		*lastPos = 0;
	}
}

static void basePathInPlace(char *s) {
	removeFromLastCharOf(s, '/');
}

static BOOL findVisualAckPath(char *visualAckPath, size_t visualAckPathLen)
{
	char path[1024];
	char *rp = NULL;
	uint32_t size = sizeof(path);
	BOOL found = YES;

	if (0 != _NSGetExecutablePath(path, &size)) {
		NSLog(@"_NSGetExecutablePath() failed, cannot launch gui\n");
		return NO;
	}
	rp = realpath(path, NULL);
	if (!rp) {
		NSLog(@"realpath('%s') failed, cannot lanunch gui\n", path);
		return NO;
	}
	
	/* when debugging vack can be in build/${VERSION}/vack while
	 VisualAck in build/${VERSION}/VisualAck.app/Contents/MacOS/VisualAck.
	 We want to try that first */
	strlcpy(visualAckPath, rp, visualAckPathLen);
	basePathInPlace(visualAckPath);
	strcat(visualAckPath, "/VisualAck.app/Contents/MacOS/VisualAck");
	
	/* vack is in Contents/Resources, VisualAck is in /Contents/MacOS/
	 so it's ../MacOS/VisualAck */
	if (!fileExists(visualAckPath)) {
		strlcpy(visualAckPath, rp, visualAckPathLen);
		basePathInPlace(visualAckPath);
		strlcat(visualAckPath, "/../MacOS/VisualAck", visualAckPathLen);
		if (!fileExists(visualAckPath)) {
			NSLog(@"'%s' doesn't exist\n", visualAckPath);
			NSLog(@"Couldn't find VisualAck executable relative to '%s'\n", rp);
			found = NO;
		}
	}
	free(rp);
	return found;
}

#define MAX_CMD_ARGS 32

static inline int streq(const char *s1, const char *s2) {
    return 0 == strcmp(s1, s2);
}

static void launchGui(int argc, char *argv[], search_options *opts)
{
	char visualAckPath[1024];
	CFStringRef args[MAX_CMD_ARGS];
	OSStatus err;
	FSRef fref;
	int realArgc = 0;
	int i;

	BOOL ok = findVisualAckPath(visualAckPath, sizeof(visualAckPath));
	if (!ok) {
		return;
	}
	for (i=1; i<argc; i++) {
		if (streq(argv[i], "-")) {
			continue;
		}
		if (realArgc >= MAX_CMD_ARGS) {
			break;
		}
		args[realArgc++] = CFStringCreateWithCString(NULL, argv[i], kCFStringEncodingUTF8);
	}

    // if search locations not given on cmd line, search current directory
    if ((opts->search_loc_count == 0) && (realArgc < MAX_CMD_ARGS)) {
        NSString *cwd = [[NSFileManager defaultManager] currentDirectoryPath];
        if (nil != cwd) {
			args[realArgc] = (__bridge CFStringRef)cwd;
            CFRetain(args[realArgc]);
            realArgc++;
        }
    }	

	err = FSPathMakeRef((unsigned char*)visualAckPath, &fref, NULL);
	if (err != noErr) {
        for (i=0; i<realArgc; i++) {
            CFRelease(args[i]);
        }
        return;
    }

	CFArrayRef argsArray = CFArrayCreate(NULL, (void*)args, realArgc, &kCFTypeArrayCallBacks);
	LSApplicationParameters params;
	params.application = &fref;
	params.version = 0;
	params.flags = kLSLaunchAsync;
	params.asyncLaunchRefCon = NULL;
	params.argv = argsArray;
	params.environment = NULL;
	params.initialEvent = NULL;
	LSOpenApplication(&params, NULL);
	CFRelease(argsArray);
	for (i=0; i<realArgc; i++) {
		CFRelease(args[i]);
	}
}

#if 0
static void launchGui(char *argv[])
{
	char visualAckPath[1024];
	BOOL ok = findVisualAckPath(visualAckPath, sizeof(visualAckPath));
	if (!ok) {
		return;
	}
	pid_t pid = fork();
	if (0 == pid) {
		// This is the child, replace it with VisualAck executable. Close stdout and
		// stderr so that we don't clutter the console (not sure if it's the right
		// thing to do)
		close(STDOUT_FILENO);
		close(STDERR_FILENO);
		execv(visualAckPath, argv);
	}
}
#endif

/* Exit status is 0 if match, 1 if no match. */
int main(int argc, char *argv[])
{
    int exit_status = 0;
    search_options opts;
    init_search_options(&opts);

    /* default setting for showing searches highlighted or not depends on whether
       stdout is a tty (use highlight) or something else (e.g. redirected to a file
       => don't use color highlight) */
    if (!isatty(1)) {
        opts.color = 0;
    }

    cmd_line_to_search_options(&opts, argc, argv);
    
    if (opts.version) {
        print_version();
        free_search_options(&opts);
        return exit_status;
        //goto Exit;
    }

    if (opts.help) {
        print_help();
        free_search_options(&opts);
        return exit_status;
        //goto Exit;
    }

    if (!opts.search_term) {
        print_help();
        free_search_options(&opts);
        return exit_status;
        //goto Exit;
    }

    if (opts.use_gui) {
        launchGui(argc, argv, &opts);
        free_search_options(&opts);
        return exit_status;
        //goto Exit;
    }

    // if search locations not given on cmd line, search current directory
    if (opts.search_loc_count == 0) {
        NSString *cwd = [[NSFileManager defaultManager] currentDirectoryPath];
        if (nil == cwd) {
            printf("Couldn't get current directory\n");
            return 1;
        }
        add_search_location(&opts, [cwd UTF8String]);
    }
    
    incSearchCount();
    FileSearcher *fileSearcher = [[FileSearcher alloc] initWithSearchOptions:&opts];
    SearchResults *sr = [[SearchResults alloc] init];
    [sr setSearchOptions:&opts];
    [fileSearcher setDelegate:sr];
    [fileSearcher doSearch];

//Exit:
    free_search_options(&opts);
    return exit_status;
}
