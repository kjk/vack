#import <Cocoa/Cocoa.h>

#import "FileSearchProtocol.h"
#import "SearchOptions.h"

@interface FileSearcher : NSObject {
    id <FileSearchProtocol>  delegate_;
    NSString *		     startDir_;
}

- (id)initWithDirectory:(NSString*)path;

- (void)setDelegate:(id <FileSearchProtocol>)delegate;
- (id <FileSearchProtocol>)delegate;

- (void)startSearch;

@end
