#import "AboutWindowController.h"

@implementation AboutWindowController

static AboutWindowController * aboutWindowControllerInstance = nil;

+ (AboutWindowController *)aboutController
{
    if (!aboutWindowControllerInstance)
        aboutWindowControllerInstance = [[self alloc] initWithWindowNibName: @"AboutWindow"];
    return aboutWindowControllerInstance;
}

- (void)awakeFromNib {
    NSDictionary * info = [[NSBundle mainBundle] infoDictionary];
    [versionLabel_ setStringValue: [NSString stringWithFormat: @"%@ (%@)",
									[info objectForKey: @"CFBundleShortVersionString"], [info objectForKey: (NSString *)kCFBundleVersionKey]]];
    [[textView_ textStorage] setAttributedString: [[NSAttributedString alloc] initWithPath:
													[[NSBundle mainBundle] pathForResource: @"About" ofType: @"rtf"] documentAttributes: nil]];
}

- (void) windowDidLoad {
    [[self window] center];
}

- (void) windowWillClose:(id)sender {
#pragma unused(sender)
    aboutWindowControllerInstance = nil;
}

@end
