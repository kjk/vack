#import <Cocoa/Cocoa.h>
#import "utassert.h"

//#import "FileSearchProtocol.h"
//#import "FileSearcher.h"

#import "FileLineIterator.h"
#import "FileSearchIterator.h"

void testLinesHelper(NSString *filePath, NSArray *content) {
    FileLineIterator *li = [FileLineIterator fileLineIteratorWithFileName:filePath];
    NSUInteger currLineNo = 0;
    int newLineNo;
    NSString *currLine;
    NSString *expectedLine;
    for (;;) {
        currLine = [li getNextLine:&newLineNo];
        if (nil == currLine) {
            utassert(currLineNo == [content count]);
            return;
        }
        expectedLine = [content objectAtIndex:currLineNo];
        utassert(newLineNo == currLineNo + 1);
        utassert([expectedLine isEqualToString:currLine]);
        currLineNo = newLineNo;
    }
}

void testLines(NSString *dir, NSString *fileName, NSArray *content) {
    NSString *path = [dir stringByAppendingPathComponent:fileName];
    testLinesHelper(path, content);
}

void testFileLineIteratorContent(NSString *testsDir) {
    NSArray *emptyContent = @[];
    NSArray *oneLineContent = @[ @"t" ];
    NSArray *threeLineContent = @[ @"line1", @"", @"line3" ];
    NSArray *fourEmptyLinesContent = @[ @"", @"", @"", @"" ];
    testLines(testsDir, @"empty-file.txt", emptyContent);
    testLines(testsDir, @"one-line.txt", oneLineContent);
    testLines(testsDir, @"3-lines-unix-newline.txt", threeLineContent);
    testLines(testsDir, @"3-lines-mac-newline.txt", threeLineContent);
    testLines(testsDir, @"3-lines-windows-newline.txt", threeLineContent);
    testLines(testsDir, @"4-empty-lines-unix-newline.txt", fourEmptyLinesContent);
}

typedef struct {
    const char *	line;
    int		lineNo;
    NSRange	matchPos;
} FileSearchResultExpected;

static BOOL NSRangeEqual(NSRange r1, NSRange r2) {
    if (r1.location != r2.location)
        return NO;
    return r1.length == r2.length;
}

void testMatchesHelper(NSString *path, NSString *searchPattern, FileSearchResultExpected *expectedResults)
{
    FileSearchIterator *si = [FileSearchIterator fileSearchIteratorWithFileName:path searchPattern:searchPattern];
    FileSearchResult *currResult;
    FileSearchResultExpected *expectedResult;
    int currResultNo = 0;
    for (;;) {
        expectedResult = &(expectedResults[currResultNo++]);
        currResult = [si getNextSearchResult];
        if (nil == currResult) {
            utassert(nil == expectedResult->line);
            return;
        }
        utassert([path isEqualToString:currResult.filePath]);
        NSString *expectedLine = [NSString stringWithUTF8String:expectedResult->line];
        utassert([expectedLine isEqualToString:currResult.line]);
        utassert(expectedResult->lineNo == currResult.lineNo);
        NSRange m = [currResult matchAtIndex:0];
        utassert(NSRangeEqual(expectedResult->matchPos, m));
    }
}

void testMatches(NSString *dir, NSString *fileName, NSString *searchPattern, FileSearchResultExpected *expectedResults)
{
    NSString *path = [dir stringByAppendingPathComponent:fileName];
    testMatchesHelper(path, searchPattern, expectedResults);
}

void testFileSearchIterator(NSString *testsDir) {
    FileSearchResultExpected threeLineResults[] = {
        { "line1", 1, { 0, 4 } },
        { "line3", 3, { 0, 4 } },
        { NULL, 0, { 0, 0 }}
    };
    FileSearchResultExpected noResults[] = {
        { NULL, 0, { 0, 0 }}
    };

    testMatches(testsDir, @"3-lines-unix-newline.txt", @"line", threeLineResults);
    testMatches(testsDir, @"3-lines-mac-newline.txt", @"line", threeLineResults);
    testMatches(testsDir, @"3-lines-windows-newline.txt", @"line", threeLineResults);
    testMatches(testsDir, @"3-lines-unix-newline.txt", @"line2", noResults);
}

void usage() {
    printf("Usage: utvack directory-with-test-files\n");
}

BOOL dirExistsAtPath(NSString *path) {
    BOOL isDir = NO;
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL dirExists = [fm fileExistsAtPath:path isDirectory:&isDir];
    return dirExists && isDir;
}

int main(int argc, char *argv[])
{
    if (argc != 2) {
        usage();
        return -1;
    }
    char *dirStr = argv[1];
    
    NSString *testsDir = [NSString stringWithUTF8String:dirStr];
    testsDir = [testsDir stringByAppendingPathComponent:@"test-files"];

    if (!dirExistsAtPath(testsDir)) {
        printf("Directory %s is not a valid tests directory\n", dirStr);
        return -1;
    }
    testFileLineIteratorContent(testsDir);
    testFileSearchIterator(testsDir);
    if (utassert_failed_count() > 0) {
        printf("\nFAILED %d out of %d tests\n", utassert_failed_count(), utassert_total_count());
    } else {
        printf("\nPassed all %d tests\n", utassert_total_count());
    }
    return utassert_failed_count();
}

