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
    testLineCount(testsDir, @"empty-file.txt", 0); // empty file has no lines
    testLineCount(testsDir, @"lines04.txt", 1);  // unix newlines
    testLineCount(testsDir, @"lines00.txt", 6);  // unix newlines
    testLineCount(testsDir, @"lines01.txt", 5);  // all empty lines
    testLineCount(testsDir, @"lines02.txt", 5);  // mac newlines
    testLineCount(testsDir, @"lines03.txt", 5);  // windows newlines
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
    if (g_utassert_failed > 0) {
	printf("\nFAILED %d out of %d tests\n", g_utassert_failed, g_utassert_total);
    } else {
	printf("\nPassed all %d tests\n", g_utassert_total);
    }
    return g_utassert_failed;
}

