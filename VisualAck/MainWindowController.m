#import "MainWindowController.h"
#import "CrashReporter.h"

@interface MainWindowController(Private)
- (BOOL)isSearchButtonEnabled;
- (void)updateSearchButtonStatus;
@end

@implementation MainWindowController

- (void)awakeFromNib {
    [dirField_ setStringValue:@"~"];
    [self updateSearchButtonStatus];
    [[self window] makeFirstResponder:searchTermField_];
    NSArray *crashReports = [CrashReporter findCrashReports];
    if (crashReports) {
        [CrashReporter submitAndDeleteCrashReports:crashReports];
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
