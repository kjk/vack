#import "FileLineIterator.h"
#import <assert.h>

@implementation FileLineIterator

- (id)initWithFileName:(NSString*)path {
    path_ = [path copy];
}

- (void)dealloc {
    [path_ release];
    if (fp_)
	fclose(fp_);
}

- (int) leftInBuf {
    assert(charsInBuf_ >= posInBuf_);
    return charsInBuf_ - posInBuf_;
}

// Return next line from the file, nil if end of file. <lineNo> is the line number.
- (NSString*)getNextLine:(int*)lineNo {
    NSString *s = nil;
    if (!fp_) {
	const char *filepath = [path_ UTF8String];
	fp_ = fopen(filepath, "r");
	// TODO: some way to return errors to the caller
	if (!fp_)
	    return nil;
	currLineNo_ = 0;
	charsInBuf_ = 0;
	posInBuf_ = 0;
    }

    assert(fp_);
    // TODO: write me
    if (0 == [self leftInBuf]) {
	size_t readBytes = fread((void*)buf_, 1, FILE_BUF_SIZE , fp_);
	if (0 == readBytes)
	    return nil;
	charsInBuf_ = readBytes;
	posInBuf_ = 0;
    }

    int left = [self leftInBuf];
    assert(left > 0);
    char *start = &(buf_[posInBuf_]);
    char *curr = start;
    while (left > 0) {
	char c = *curr;
	if (c == '\n' || c == '\r') {
	    break;
	}
	++curr;
	left--;
    }

    // TODO: update posInBuf_
    // TODO; handle \n\r so that it doesn't show as an empty line
    // didn't find newline
    // TODO: handle line spanning buffers
    if (0 == left) {
	goto Exit;
    }
    int len = curr - start;
    s = [NSString stringWithCString:start length:len];
    *lineNo = currLineNo_;

Exit:
    currLineNo_++;
    return s;
}

@end
