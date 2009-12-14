#import <Cocoa/Cocoa.h>

#import "FileSearchProtocol.h"
#import "FileSearcher.h"
#import "PrefKeys.h"
#include <sys/stat.h>
#include <mach-o/dyld.h>

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
 -i, --ignore-case     Ignore case distinctions in PATTERN
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
 --[no]color           Highlight the matching text (default: on unless
 output is redirected, or on Windows)
 --[no]colour          Same as --[no]color
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
 
*/

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

@interface SearchResults : NSObject <FileSearchProtocol>
{
    NSString *  currFilePath_;
    int         resultsCount_;
}
@end

@implementation SearchResults
- (void)dealloc {
    assert(!currFilePath_);
    [super dealloc];
}

- (BOOL)didSkipFile:(NSString*)filePath {
    printf("didSkipFile %s\n", [filePath UTF8String]);
	return YES;
}

- (BOOL)didSkipDirectory:(NSString*)dirPath {
    printf("didSkipDirectory %s\n", [dirPath UTF8String]);
	return YES;
}

- (BOOL)didSkipNonExistent:(NSString*)path {
    printf("didSkipNonExistent %s\n", [path UTF8String]);
	return YES;
}

- (BOOL)didFind:(FileSearchResult*)searchResult {
    if (0 == resultsCount_) {
        // TODO: if not color, don't color
        NSString *fileColored = [NSString stringWithFormat:@"%@%@%@", ansiColor(ANSI_COLOR_FILE), currFilePath_, ansiColor(ANSI_COLOR_RESET)];
        printf("%s\n", [fileColored UTF8String]);
    }
    // TODO: if not color, don't color
    NSString *toPrint = wrapStringRangesInColor(searchResult.line, searchResult.matchesCount, searchResult.matches, ansiColor(ANSI_COLOR_MATCH));
    printf("%s\n", [toPrint UTF8String]);
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
    [currFilePath_ release];
    currFilePath_ = nil;
	return YES;
}

- (void)didFinishSearch {
}

@end

#define VACK_VER "0.01"

static void print_version() {
    printf("vack %s\n", VACK_VER);
}

static void print_help() {
    printf("vack %s\n", VACK_VER);
    printf("\nThis is help. Write me.\n");
}

static void incSearchCount(void)
{
    CFStringRef appId = CFSTR("info.kowalczyk.visualack");
    CFStringRef keyStr = (CFStringRef)PREF_SEARCH_COUNT;
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
    CFPreferencesSetAppValue(keyStr, (CFPropertyListRef)newVal, appId);
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

static void launchGui(char *argv[])
{
	char path[1024];
	char *rp;
	char visualAckPath[1024];

	uint32_t size = sizeof(path);
	if (0 != _NSGetExecutablePath(path, &size)) {
		printf("_NSGetExecutablePath() failed, cannot launch gui\n");
		return;
	}
	rp = realpath(path, NULL);
	if (!rp) {
		printf("realpath('%s') failed, cannot lanunch gui\n", path);
		return;
	}

	/* vack is in Contents/Resources, VisualAck is in /Contents/MacOS/
	   so it's ../MacOS/VisualAck */
	strlcpy(visualAckPath, rp, sizeof(visualAckPath));
	basePathInPlace(visualAckPath);
	strlcat(visualAckPath, "/../MacOS/VisualAck", sizeof(visualAckPath));

	/* when debugging vack can be in build/${VERSION}/vack while
	   VisualAck in build/${VERSION}/VisualAck.app/Contents/MacOS/VisualAck */
	if (!fileExists(visualAckPath)) {
		//printf("'%s' doesn't exist\n", visualAckPath);
		strlcpy(visualAckPath, rp, sizeof(visualAckPath));
		basePathInPlace(visualAckPath);
		strcat(visualAckPath, "/VisualAck.app/Contents/MacOS/VisualAck");
		if (!fileExists(visualAckPath)) {
			printf("'%s' doesn't exist\n", visualAckPath);
			printf("Couldn't find VisualAck executable relative to '%s'\n", rp);
			free(rp);
			return;
		}
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

/* Exit status is 0 if match, 1 if no match. */
int main(int argc, char *argv[])
{
    int exit_status = 0;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    search_options opts;
    init_search_options(&opts);
    cmd_line_to_search_options(&opts, argc, argv);
    
    if (opts.version) {
        print_version();
        goto Exit;
    }

    if (opts.help) {
        print_help();
        goto Exit;
    }

    if (!opts.search_term) {
        print_help();
        goto Exit;
    }

	if (opts.use_gui) {
		launchGui(argv);
		goto Exit;
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
    [fileSearcher setDelegate:sr];
    [fileSearcher doSearch];

    [fileSearcher release];
    [sr release];
Exit:
    [pool drain];
    free_search_options(&opts);
    return exit_status;
}

