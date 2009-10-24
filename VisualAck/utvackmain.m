#import <Cocoa/Cocoa.h>
#import "utassert.h"

//#import "FileSearchProtocol.h"
//#import "FileSearcher.h"

#import "FileLineIterator.h"

void testFileLineIterator() {
    
}

void usage() {
    printf("Usage: utvack directory-with-test-files\n");
}

int main(int argc, char *argv[])
{
    if (argc != 2) {
	usage();
	return -1;
    }
    char *dirStr = argv[1];
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSString *dir = [NSString stringWithUTF8String:dirStr];
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL dirExists = [fm fileExistsAtPath:dir isDirectory:&isDir];
    if (!isDir)
	dirExists = NO;

    if (!dirExists) {
	printf("Directory %s doesn't exist\n", dirStr);
	return -1;
    }
    testFileLineIterator();
    [pool drain];
    if (g_utassert_failed > 0) {
	printf("\nPassed all %d tests\n", g_utassert_total);
    } else {
	printf("\nFAILED %d out of %d tests\n", g_utassert_failed, g_utassert_total);
    }
    return g_utassert_failed;
}

