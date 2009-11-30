#import "VisualAckAppDelegate.h"
#import "SearchWindowController.h"
#import <Sparkle/Sparkle.h>

#define VACK_BIN_LINK "/usr/local/bin/vack"
#define VACK_BIN_LINK_STR @"/usr/local/bin/vack"

NSString * PREF_UNIQUE_ID = @"uniqueId";

@implementation VisualAckAppDelegate

@synthesize searchWindowController;

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
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: 
                          @"uniqueId", @"key",
						  uniqueId, @"value",
                          @"uniqueId", @"displayKey",
						  uniqueId, @"displayValue",
                          nil];
    NSArray *arr = [NSArray arrayWithObject:dict];
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
	SUUpdater *updater = [SUUpdater sharedUpdater];
	// this must be enabled via code, there is no .plist entry key for this
	[updater setSendsSystemProfile:YES];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// TODO: should this be in willFinishLaunching?
    if (![self isVackLinkPresentAndCurrent]) {
        [self createLinkToVack];
    }
    // TODO: only show the window if not invoked via vack
    searchWindowController = [[SearchWindowController alloc] initWithWindowNibName:@"SearchWindow"];
    [searchWindowController showWindow:nil];
}

@end
