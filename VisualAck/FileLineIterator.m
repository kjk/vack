#import "FileLineIterator.h"

@implementation FileLineIterator

- (id)initWithFileName:(NSString*)path {
    path_ = [path copy];
}

- (void)dealloc {
    [path_ release];
    if (fp_)
	fclose(fp_);
}

// Return next line from the file, nil if end of file. <lineNo> is the line number.
- (NSString*)getNextLine:(int*)lineNo {
    if (!fp_) {
	const char *filepath = [path_ UTF8String];
	fp_ = fopen(filepath, "r");
	// TODO: some way to return errors to the caller
	if (!fp_)
	    return nil;
	currLineNo_ = 0;
    }

    // TODO: write me
    *lineNo = currLineNo_;
    currLineNo_++;
    return nil;
}

@end
