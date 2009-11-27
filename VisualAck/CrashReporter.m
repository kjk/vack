#import "CrashReporter.h"

@implementation CrashReporter

+ (NSArray*) findCrashReportsForName:(NSString*)appName {
    NSString * crashLogsFolder = [@"~/Library/Logs/CrashReporter/" stringByExpandingTildeInPath];
	NSString * crashLogPrefix = [NSString stringWithFormat: @"%@_",appName];

    NSMutableArray *crashDumpsFound = nil;
	NSString * currName = nil;
    NSDirectoryEnumerator* dirEnum = [[NSFileManager defaultManager] enumeratorAtPath: crashLogsFolder];
	while ((currName = [dirEnum nextObject]))
	{
		if ([currName hasPrefix: crashLogPrefix] && [currName hasSuffix: @".crash"])
		{
            if (!crashDumpsFound) {
                crashDumpsFound = [NSMutableArray arrayWithCapacity:8];
            }
            NSString *crashLogPath = [crashLogsFolder stringByAppendingPathComponent: currName];
            [crashDumpsFound addObject:crashLogPath];
		}
	}
	
    return crashDumpsFound;
}

+ (NSArray*) findCrashReports {
    NSString * appName = [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleExecutable"];
    return [CrashReporter findCrashReportsForName:appName];
}

@end
