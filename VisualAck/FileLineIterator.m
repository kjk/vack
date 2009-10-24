#import "FileLineIterator.h"
#import <assert.h>
#import <sys/mman.h>

@implementation FileLineIterator

+ (FileLineIterator*) fileLineIteratorWithFileName:(NSString*)path {
    return [[[FileLineIterator alloc] initWithFileName:path] autorelease];
}

- (id)initWithFileName:(NSString*)path {
    self = [super init];
    if (!self)
        return nil;
    path_ = [path copy];
    fd_ = -1;
    return self;
}

- (void)dealloc {
    [path_ release];
    if (fd_ > 0)
	close(fd_);
}

- (BOOL)openFileIfNeeded {
    if (fd_ > 0)
	return YES;
    const char *filepath = [path_ UTF8String];
    fd_ = open(filepath, O_RDONLY);
    if (fd_ < 0)
	return NO;
    fileSize_ = lseek(fd_, 0, SEEK_END);
    // TODO: check for size > 4GB
    fileStart_ = (char*)mmap(NULL, fileSize_, PROT_READ, MAP_SHARED, fd_, 0);
    if ((void*)fileStart_ == MAP_FAILED) {
	close(fd_);
	return NO;
    }
    fileEnd_ = fileStart_ + fileSize_;
    fileCurrPos_ = fileStart_;
    return YES;
}

// Return next line from the file, nil if end of file. <lineNo> is the line 
// number (starting with 1)
// TODO: handle unicode files
- (NSString*)getNextLine:(int*)lineNo {
    NSString *s = nil;
    BOOL ok = [self openFileIfNeeded];
    if (!ok)
	return nil;
    char *lineStart = fileCurrPos_;
    char *lineEnd = NULL;
    char *curr = lineStart;
    while (curr < fileEnd_) {
	char c = *curr++;
	if (c == '\n' || c == '\r') {
	    lineEnd = curr - 1;
	    if (c == '\n' && curr < fileEnd_) {
		if (*curr == '\r') {
		    ++curr;
		}
	    }
	    break;
	}
    }
    if (NULL == lineEnd)
	return nil;
    int len = lineEnd - lineStart;
    fileCurrPos_ = curr;
    // TODO: figure out the right code page
    s = [NSString stringWithCString:lineStart length:len];
    *lineNo = ++currLineNo_;
    return s;
}

@end
