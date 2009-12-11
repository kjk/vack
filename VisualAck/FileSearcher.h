#import <Cocoa/Cocoa.h>

#import "FileSearchProtocol.h"
#import "SearchOptions.h"

@interface FileSearcher : NSObject {
    id <FileSearchProtocol>     delegate_;
    search_options *            opts_;
    NSString *                  searchPattern_;
    NSMutableDictionary *       dirsToIgnore_;
}

- (id)initWithSearchOptions:(search_options*)opts;

- (void)setDelegate:(id <FileSearchProtocol>)delegate;
- (id <FileSearchProtocol>)delegate;

- (void)doSearch;

@end
