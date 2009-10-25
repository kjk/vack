#import <Cocoa/Cocoa.h>
#import "utassert.h"

//#import "FileSearchProtocol.h"
//#import "FileSearcher.h"

#import "FileLineIterator.h"

void testLinesHelper(NSString *filePath, NSString **content) {
    FileLineIterator *li = [FileLineIterator fileLineIteratorWithFileName:filePath];
    int currLineNo = 0;
    int newLineNo;
    NSString *currLine;
    NSString *expectedLine;
    for (;;) {
	expectedLine = content[currLineNo];
	currLine = [li getNextLine:&newLineNo];
	if (nil == currLine) {
	    utassert(nil == expectedLine);
	    return;
	}
	utassert(newLineNo == currLineNo + 1);
	utassert([expectedLine isEqualToString:currLine]);
	currLineNo = newLineNo;
    }
}

void testLines(NSString *dir, NSString *fileName, NSString **content) {
    NSString *path = [dir stringByAppendingPathComponent:fileName];
    testLinesHelper(path, content);
}

void testFileLineIteratorContent(NSString *testsDir) {
    NSString *emptyContent[1] = { nil };
    NSString *oneLineContent[2] = { @"t", nil };
    NSString *threeLineContent[4] = { @"line1", @"", @"line3", nil };
    NSString *fourEmptyLinesContent[5] = { @"", @"", @"", @"", nil };
    testLines(testsDir, @"empty-file.txt", emptyContent);
    testLines(testsDir, @"one-line.txt", oneLineContent);
    testLines(testsDir, @"3-lines-unix-newline.txt", threeLineContent);
    testLines(testsDir, @"3-lines-mac-newline.txt", threeLineContent);
    testLines(testsDir, @"3-lines-windows-newline.txt", threeLineContent);
    testLines(testsDir, @"4-empty-lines-unix-newline.txt", fourEmptyLinesContent);
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
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSString *testsDir = [NSString stringWithUTF8String:dirStr];
    testsDir = [testsDir stringByAppendingPathComponent:@"test-files"];

    if (!dirExistsAtPath(testsDir)) {
	printf("Directory %s is not a valid tests directory\n", dirStr);
	return -1;
    }
    testFileLineIteratorContent(testsDir);
    [pool drain];
    if (utassert_failed_count() > 0) {
	printf("\nFAILED %d out of %d tests\n", utassert_failed_count(), utassert_total_count());
    } else {
	printf("\nPassed all %d tests\n", utassert_total_count());
    }
    return utassert_failed_count();
}

