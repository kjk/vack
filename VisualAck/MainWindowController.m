#import "MainWindowController.h"
#import "CrashReporter.h"
#import "Http.h"

@interface MainWindowController(Private)
- (BOOL)isSearchButtonEnabled;
- (void)updateSearchButtonStatus;
@end

@implementation MainWindowController

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

- (void)awakeFromNib {
    [dirField_ setStringValue:@"~"];
    [self updateSearchButtonStatus];
    [[self window] makeFirstResponder:searchTermField_];
    NSArray *crashReports = [CrashReporter findCrashReports];
    if (crashReports) {
        for (NSUInteger i = 0; i < [crashReports count]; i++) {
            [self submitAndDeleteCrashReport:[crashReports objectAtIndex:i]];
        }
    }
}

- (BOOL)isSearchButtonEnabled {
    if ([[searchTermField_ stringValue] length] == 0)
        return NO;
    // TODO: verify that all entries are valid directories
    if ([[dirField_ stringValue] length] == 0)
        return NO;
    return YES;
}

- (void)updateSearchButtonStatus {
    BOOL enabled = [self isSearchButtonEnabled];
    [buttonSearch_ setEnabled:enabled];
}

- (void)controlTextDidChange:(NSNotification*)aNotification {
    [self updateSearchButtonStatus];
}

// Sent by either a "Search" button or pressing Enter in the text fields
- (IBAction) search:(id)sender {
    // came from text field but not ready to do search
    if (![self isSearchButtonEnabled])
        return;
    NSLog(@"search");
}

- (IBAction) chooseDir:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:YES];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setAllowsMultipleSelection:YES];
    [openPanel setAllowedFileTypes:nil];
    NSInteger res = [openPanel runModal];
    if (res != NSOKButton)
        return;
    NSString * dir = [openPanel directory];
    NSArray *files = [openPanel filenames];
    NSMutableString *s = [NSMutableString stringWithString:@""];
    for (NSString *file in files) {
        [s appendString:file];
        [s appendString:@";"];
    }
    [s deleteCharactersInRange:NSMakeRange([s length] - 1, 1)];
    [dirField_ setStringValue:s];
}

@end
