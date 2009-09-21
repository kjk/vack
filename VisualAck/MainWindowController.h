#import <Cocoa/Cocoa.h>

@interface MainWindowController : NSWindowController {
    IBOutlet NSTextField *  searchTermField_;
    IBOutlet NSTextField *  dirField_;
    IBOutlet NSButton *	    buttonSearch_;
}

- (IBAction) search:(id)sender;
- (IBAction) chooseDir:(id)sender;

@end
