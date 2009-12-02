#import "CrashReporter.h"
#import "Http.h"
#import "PrefKeys.h"
#import "SearchWindowController.h"
#import <Sparkle/Sparkle.h>
#import "VisualAckAppDelegate.h"

#define VACK_BIN_LINK "/usr/local/bin/vack"
#define VACK_BIN_LINK_STR @"/usr/local/bin/vack"

@implementation VisualAckAppDelegate

@synthesize searchWindowController;

- (void)onHttpDoneOrError:(Http*)aHttp {
    NSString *filePath = [aHttp filePath];
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:NULL];
    [aHttp release];
}

static NSString *REPORT_SUBMIT_URL = @"http://blog.kowalczyk.info/app/crashsubmit?appname=VisualAck";
//static NSString *REPORT_SUBMIT_URL = @"http://127.0.0.1:9340/app/crashsubmit?appname=VisualAck";

- (void) submitAndDeleteCrashReport:(NSString *)crashReportPath {
    NSError *error = nil;
    NSStringEncoding encoding;
    NSString *s = [NSString stringWithContentsOfFile:crashReportPath usedEncoding:&encoding error:&error];
    if (error)
        return;
    const char *utf8 = [s UTF8String];
    unsigned len = strlen(utf8);
    NSData *data = [NSData dataWithBytes:(const void*)utf8 length:len];
    NSURL *url = [NSURL URLWithString:REPORT_SUBMIT_URL];
    [[Http alloc] initAndUploadWithURL:url
                                  data:data
                              filePath:crashReportPath
                              delegate:self
                          doneSelector:@selector(onHttpDoneOrError:)
                         errorSelector:@selector(onHttpDoneOrError:)];
}

- (void)incSearchCount {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSInteger count = [prefs integerForKey:PREF_SEARCH_COUNT];
    ++count;
    [prefs setInteger:count forKey:PREF_SEARCH_COUNT];    
}

- (NSInteger)searchCount {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    return [prefs integerForKey:PREF_SEARCH_COUNT];
}

- (NSString*)uniqueId {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *uuid = [prefs objectForKey:PREF_UNIQUE_ID];
    if (!uuid) {
        CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
        CFStringRef sref = CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
        CFRelease(uuidRef);
        uuid = (NSString*)sref;
        [uuid autorelease];
        [prefs setObject:uuid forKey:PREF_UNIQUE_ID];
    }
    return uuid;
}

// delegate for Sparkle's SUUpdater
- (NSArray *)feedParametersForUpdater:(SUUpdater *)updater
                 sendingSystemProfile:(BOOL)sendingProfile {
    NSString *uniqueId = [self uniqueId];
    NSInteger count = [self searchCount];
    NSNumber *countNum = [NSNumber numberWithInteger:count];
    NSDictionary *uniqueIdDict = [NSDictionary dictionaryWithObjectsAndKeys: 
                          @"uniqueId", @"key",
						  uniqueId, @"value",
                          @"uniqueId", @"displayKey",
						  uniqueId, @"displayValue",
                          nil];
    NSDictionary *countDict = [NSDictionary dictionaryWithObjectsAndKeys: 
                                  @"searchCount", @"key",
                                  countNum, @"value",
                                  @"searchCount", @"displayKey",
                                  countNum, @"displayValue",
                                  nil];
    NSArray *arr = [NSArray arrayWithObjects:uniqueIdDict, countDict, nil];
    return arr;
}

- (NSString*) vackPath {
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    return [resourcePath stringByAppendingPathComponent:@"vack"];
}

- (void)createLinkToVack {
    OSStatus status;
    AuthorizationRef authorizationRef;

    // AuthorizationCreate and pass NULL as the initial
    // AuthorizationRights set so that the AuthorizationRef gets created
    // successfully, and then later call AuthorizationCopyRights to
    // determine or extend the allowable rights.
    // http://developer.apple.com/qa/qa2001/qa1172.html
    status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment,
                                 kAuthorizationFlagDefaults, &authorizationRef);

    if (status != errAuthorizationSuccess) {
        //NSLog(@"Error Creating Initial Authorization: %d", status);
        return;
    }
    
    // kAuthorizationRightExecute == "system.privilege.admin"
    AuthorizationItem right = { kAuthorizationRightExecute, 0, NULL, 0 };
    AuthorizationRights rights = {1, &right};
    AuthorizationFlags flags = kAuthorizationFlagDefaults |
            kAuthorizationFlagInteractionAllowed |
            kAuthorizationFlagPreAuthorize |
            kAuthorizationFlagExtendRights;

    // Call AuthorizationCopyRights to determine or extend the allowable rights.
    status = AuthorizationCopyRights(authorizationRef, &rights, NULL, flags, NULL);

    if (status != errAuthorizationSuccess) {
        //NSLog(@"Copy Rights Unsuccessful: %d", status);
        return;
    }

    //NSLog(@"\n\n** %@ **\n\n", @"This command should work.");
    char *cmd = "/bin/ln";
    char *args[] = {
        "-s",
        NULL,
        VACK_BIN_LINK,
        NULL
    };
    FILE *pipe = NULL;

    args[1] = (char*)[[self vackPath] UTF8String];

    status = AuthorizationExecuteWithPrivileges(authorizationRef, cmd,
                                                kAuthorizationFlagDefaults, args, &pipe);
    if (status != errAuthorizationSuccess) {
        //NSLog(@"Error: %d", status);
        return;
    }

    // The only way to guarantee that a credential acquired when you
    // request a right is not shared with other authorization instances is
    // to destroy the credential.  To do so, call the AuthorizationFree
    // function with the flag kAuthorizationFlagDestroyRights.
    // http://developer.apple.com/documentation/Security/Conceptual/authorization_concepts/02authconcepts/chapter_2_section_7.html
    status = AuthorizationFree(authorizationRef, kAuthorizationFlagDestroyRights);
}

- (BOOL) isVackLinkPresentAndCurrent {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSString *realPath = [fileManager destinationOfSymbolicLinkAtPath:VACK_BIN_LINK_STR error:&error];
    if (error || !realPath)
        return NO;
    return [realPath isEqualToString:[self vackPath]];
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    // find crash reports generated for our app and upload them to a website
    NSArray *crashReports = [CrashReporter findCrashReports];
    if (crashReports) {
        for (NSUInteger i = 0; i < [crashReports count]; i++) {
            [self submitAndDeleteCrashReport:[crashReports objectAtIndex:i]];
        }
    }
    
	SUUpdater *updater = [SUUpdater sharedUpdater];
	// this must be enabled via code, there is no .plist entry key for this
	[updater setSendsSystemProfile:YES];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self incSearchCount];
	// TODO: should this be in willFinishLaunching?
    if (![self isVackLinkPresentAndCurrent]) {
        [self createLinkToVack];
    }
    // TODO: only show the window if not invoked via vack
    searchWindowController = [[SearchWindowController alloc] initWithWindowNibName:@"SearchWindow"];
    [searchWindowController showWindow:nil];
}

-(IBAction)showSearchWindow:(id)sender {
    [searchWindowController showWindow:sender];
}

@end
