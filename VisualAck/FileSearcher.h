#import <Cocoa/Cocoa.h>

#import "FileSearchProtocol.h"
#import "SearchOptions.h"

@interface FileSearcher : NSObject {
    id <FileSearchProtocol>	delegate_;
    NSString *			startDir_;
    NSMutableDictionary *	dirsToIgnore_;
}

- (id)initWithDirectory:(NSString*)path searchOptions:(search_options*)opts;

- (void)setDelegate:(id <FileSearchProtocol>)delegate;
- (id <FileSearchProtocol>)delegate;

- (void)startSearch;

@end
