#import <Cocoa/Cocoa.h>
#import "utassert.h"

//#import "FileSearchProtocol.h"
//#import "FileSearcher.h"

#import "FileLineIterator.h"

void testLineCountHelper(NSString *filePath, int expectedLineCount) {
    FileLineIterator *li = [FileLineIterator fileLineIteratorWithFileName:filePath];
    int currLineNo = 0;
    int newLineNo;
    NSString *nextLine;
    for (;;) {
	nextLine = [li getNextLine:&newLineNo];
	if (nil == nextLine)
	    break;
	utassert(newLineNo == currLineNo + 1);
	currLineNo = newLineNo;
    }
    utassert(currLineNo == expectedLineCount);
}

void testLineCount(NSString *dir, NSString *fileName, int expectedLineCount) {
    NSString *path = [dir stringByAppendingPathComponent:fileName];
    testLineCountHelper(path, expectedLineCount);
}
    
void testFileLineIterator(NSString *testsDir) {
    testLineCount(testsDir, @"empty-file.txt", 0);
    testLineCount(testsDir, @"one-line.txt", 1);
    testLineCount(testsDir, @"5-empty-lines-unix-newline.txt", 4);
    testLineCount(testsDir, @"6-lines-unix-newline.txt", 5);
    testLineCount(testsDir, @"6-lines-mac-newline.txt", 5);
    testLineCount(testsDir, @"6-lines-windows-newline.txt", 5);
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
    testFileLineIterator(testsDir);
    [pool drain];
    if (utassert_failed_count() > 0) {
	printf("\nFAILED %d out of %d tests\n", utassert_failed_count(), utassert_total_count());
    } else {
	printf("\nPassed all %d tests\n", utassert_total_count());
    }
    return utassert_failed_count();
}

