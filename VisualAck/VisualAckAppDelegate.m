#import "VisualAckAppDelegate.h"

#import "CrashReporter.h"
#import "Http.h"
#import "PrefKeys.h"
#import "MainWindowController.h"
#import <Sparkle/Sparkle.h>

extern int g_argc;
extern char **g_argv;

@implementation VisualAckAppDelegate

static VisualAckAppDelegate *shared;

- (id)init {
    if (shared) {
        [self autorelease];
        return shared;
    }
    if (![super init]) return nil; 
    operationQueue_ = [[NSOperationQueue alloc] init];
    shared = self;
    return self;
}

- (void)dealloc {
    [operationQueue_ release];
    [super dealloc];
}

+ (id)shared; {
    if (!shared) {
        [[VisualAckAppDelegate alloc] init];
    }
    return shared;
}

- (void)addOperation:(NSOperation*)operation {
    [operationQueue_ addOperation:operation];
}

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
    NSInteger count = [mainWindowController_ searchCount];
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

// return a full path to vack executable
- (NSString*)vackPath {
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

    char *argsLn[] = { "-s", NULL, "/usr/local/bin/vack", NULL };
    char *argsRm[] = { "/usr/local/bin/vack", NULL };
    FILE *pipe = NULL;

    argsLn[1] = (char*)[[self vackPath] UTF8String];

    status = AuthorizationExecuteWithPrivileges(authorizationRef, "/bin/rm",
                                                kAuthorizationFlagDefaults, argsRm, &pipe);    

    status = AuthorizationExecuteWithPrivileges(authorizationRef, "/bin/ln",
                                                kAuthorizationFlagDefaults, argsLn, &pipe);

    // The only way to guarantee that a credential acquired when you
    // request a right is not shared with other authorization instances is
    // to destroy the credential.  To do so, call the AuthorizationFree
    // function with the flag kAuthorizationFlagDestroyRights.
    // http://developer.apple.com/documentation/Security/Conceptual/authorization_concepts/02authconcepts/chapter_2_section_7.html
    AuthorizationFree(authorizationRef, kAuthorizationFlagDestroyRights);
}

- (BOOL)isVackLinkPresentAndCurrent {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSString *realPath = [fileManager destinationOfSymbolicLinkAtPath:@"/usr/local/bin/vack" error:&error];
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

- (void)alertDidEnd:(NSAlert*)alert returnCode:(NSInteger)returnCode contextInfo:(void*)contextInfo {
	if (returnCode == NSAlertFirstButtonReturn) {
        [self createLinkToVack];		
	}
}

- (void)shouldCreateVackLink {
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert addButtonWithTitle:@"Create"];
	[alert addButtonWithTitle:@"Cancel"];
	[alert setMessageText:@"Create link to vack executable?"];
	[alert setInformativeText:@"VisualAck includes 'vack' command-line executable.\n\nCreate a link to vack executable in /usr/local/bin so that it can be used from terminal?\n\nAn authorization will be required."];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert beginSheetModalForWindow:[mainWindowController_ window]
					  modalDelegate:self
					 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
						contextInfo:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    mainWindowController_ = [[MainWindowController alloc] initWithWindowNibName:@"MainWindow"];
    [mainWindowController_ window];

	// TODO: this needs to be replaced by an apple event, so that it works even if
	// the app is already running
    // command line arguments were given. This means that we were invoked via
    // vack, so we don't have to check for [self isVackLinkPresentAndCurrent]
    // we check for 2 argc, because first is executable path and second is
    // some -psnXXXX argument that Mac OS X seems to be giving to .app programs
    if (g_argc > 2) {
#if 0
        NSLog(@"args: %d", g_argc);
        for (int i=0; i<g_argc; i++) {
            NSLog(@"arg: %s", g_argv[i]);
        }
#endif
        search_options opts;
        init_search_options(&opts);
        cmd_line_to_search_options(&opts, g_argc, g_argv);
        [mainWindowController_ startSearchForSearchOptions:opts];
        // not freeing opts because startSearch: takes ownership
		return;
    }
    
    if (![self isVackLinkPresentAndCurrent]) {
        [self shouldCreateVackLink];
    }
}

- (IBAction)showMainWindow:(id)sender {
    [mainWindowController_ showWindow:self];
}

- (BOOL)isNewSearchMenuEnabled {
    return ![[mainWindowController_ window] isVisible];
}

@end
