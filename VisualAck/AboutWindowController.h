#import <Cocoa/Cocoa.h>

@interface AboutWindowController : NSWindowController {
	IBOutlet NSTextView *  textView_;
	IBOutlet NSTextField * versionLabel_;
}

+ (AboutWindowController*)aboutController;

@end
