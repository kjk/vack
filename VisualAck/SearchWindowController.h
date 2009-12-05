#import <Cocoa/Cocoa.h>

@interface SearchWindowController : NSWindowController {
    IBOutlet NSTextField *      searchTermField_;
    IBOutlet NSTextField *      dirField_;
    IBOutlet NSButton *         buttonSearch_;
    IBOutlet NSButton *         buttonChooseDir_;
}

- (IBAction)showWindow:(id)sender;
- (IBAction)search:(id)sender;
- (IBAction)chooseDir:(id)sender;

@end
