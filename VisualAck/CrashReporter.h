#import <Cocoa/Cocoa.h>

@interface CrashReporter : NSObject {
}

+ (NSArray*) findCrashReportsForName:(NSString*)appName;
+ (NSArray*) findCrashReports;
@end
