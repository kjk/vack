#import <Cocoa/Cocoa.h>

#import "FileSearchProtocol.h"
#import "FileSearcher.h"

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
 --help                This help
 --man                 Man page
 --version             Display version & copyright
 --thpppt              Bill the Cat
 
 Exit status is 0 if match, 1 if no match.
 
 This is version 1.88 of ack.
*/

typedef struct {
    int use_gui;
    int noenv; /* --noenv */
    int help; /* --help  */
    int version; /* --version */
    int thpppt; /* --thppt */
    int ignore_case; /* -i, --ignore-case */
    
} search_options;

static search_options g_default_search_options = {
    1, /* use_gui */
    0, /* noenv */
    0, /* help */
    0, /* version */
    0, /* thppt */
    0, /* ignore_case */
};

static inline int streq(const char *s1, const char *s2) {
    return 0 == strcmp(s1, s2);
}

void parse_cmd_line(search_options *opts, int argc, char *argv[]) 
{
    if (argc < 2)
	return;

    int curr_arg = 1;

    /* special case: if '-' is the first arg, it disables the ui and is the
       equivalent of ack */
    if (streq("-", argv[curr_arg])) {
	opts->use_gui = NO;
	++curr_arg;
    }

    for(;;) 
    {
	int args_left = argc - curr_arg;
	if (args_left <= 0)
	    break;

	char *arg = argv[curr_arg];
	if (streq(arg, "--noenv")) {
	    opts->noenv = 1;
	    ++curr_arg;
	} else if (streq(arg, "--help")) {
	    opts->help = 1;
	    ++curr_arg;
	} else if (streq(arg, "--version")) {
	    opts->version = 1;
	    ++curr_arg;
	} else if (streq(arg, "--thppt")) {
	    opts->thpppt = 1;
	    ++curr_arg;
	} else if (streq(arg, "-i") || (streq(arg, "--ignore-case"))) {
	    opts->ignore_case = 1;
	    ++curr_arg;
	} else {
	    
	}
    }
}

@interface SearchResults : NSObject <FileSearchProtocol>
{
}
@end

@implementation SearchResults
- (void) didSkipFile:(NSString*)filePath {
    NSLog(@"didSkipFile %@", filePath);
}

- (void) didSkipDirectory:(NSString*)dirPath {
    NSLog(@"didSkipDirectory %@", dirPath);
}

- (void) didFind:(FileSearchResult*)searchResult {
    NSLog(@"didFind");
}

- (void) didNotFind:(NSString*)filePath {
    NSLog(@"didNotFind in %@", filePath);
}
@end

int main(int argc, char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    search_options opts = g_default_search_options;
    parse_cmd_line(&opts, argc, argv);
    NSString *cwd = [[NSFileManager defaultManager] currentDirectoryPath];
    if (nil == cwd) {
	printf("Couldn't get current directory\n");
	return 1;
    }
    FileSearcher *fileSearcher = [[FileSearcher alloc] initWithDirectory:cwd];
    SearchResults *sr = [[SearchResults alloc] init];
    [fileSearcher setDelegate:sr];
    [fileSearcher startSearch];

    printf("Vack attack!\n");
    [fileSearcher release];
    [sr release];
    [pool drain];
}

