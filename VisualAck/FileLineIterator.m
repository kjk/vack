#import "FileLineIterator.h"
#import <assert.h>
#import <sys/mman.h>

// http://en.wikipedia.org/wiki/Newline
// CR   - (old) MAC
// LF   - UNIX
// CRLF - WINDOWS
#define CR 0xd
#define LF 0xa

#define MAX_LINE_LEN 512

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
    [super dealloc];
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
		fd_ = -1;
        close(fd_);
        return NO;
    }
    fileEnd_ = fileStart_ + fileSize_;
    fileCurrPos_ = fileStart_;

    // default to utf8, auto-detect files with BOM
    currentEncoding_ = kCFStringEncodingUTF8;
    static const unsigned char utf32be[4] = {0   , 0,    0xfe, 0xff};
    static const unsigned char utf32le[4] = {0xff, 0xfe, 0,    0};
    static const unsigned char utf16be[2] = {0xfe, 0xff};
    static const unsigned char utf16le[2] = {0xff, 0xfe};
    static const unsigned char utf8[3]    = {0xef, 0xbb, 0xbf};
    if (fileSize_ > 4) {
        if (0 == memcmp(fileStart_, utf32be, 4)) {
            currentEncoding_ = kCFStringEncodingUTF32BE;
            fileCurrPos_ += 4;
        } else if (0 == memcmp(fileStart_, utf32le, 4)) {
            currentEncoding_ = kCFStringEncodingUTF32LE;
            fileCurrPos_ += 4;
        } else if (0 == memcmp(fileStart_, utf16be, 2)) {
            currentEncoding_ = kCFStringEncodingUTF16BE;
            fileCurrPos_ += 2;
        } else if (0 == memcmp(fileStart_, utf16le, 2)) {
            currentEncoding_ = kCFStringEncodingUTF16LE;
            fileCurrPos_ += 2;
        } else if (0 == memcmp(fileStart_, utf8, 3)) {
            currentEncoding_ = kCFStringEncodingUTF8;
            fileCurrPos_ += 3;
        }
    }
    return YES;
}

// Return next line from the file, nil if end of file. <lineNo> is the line 
// number (starting with 1)
// TODO: handle unicode files
- (NSString*)getNextLine:(int*)lineNo {
    BOOL ok = [self openFileIfNeeded];
    if (!ok)
        return nil;
    if (fileCurrPos_ == fileEnd_) {
        return nil;
    }
    assert(fileEnd_ > fileCurrPos_);
    char *curr = fileCurrPos_;
    char *lineEnd = NULL;
    while (curr < fileEnd_) {
        char c = *curr++;
        lineEnd = curr;
        if (c == CR || c == LF) {
            lineEnd = curr - 1;
            if (c == CR && curr < fileEnd_) {
                if (*curr == LF) {
                    ++curr;
                }
            }
            break;
        }
    }
    assert(lineEnd != NULL);
    int len = lineEnd - fileCurrPos_;

    Boolean isExternal = FALSE;
    CFStringRef s = CFStringCreateWithBytesNoCopy(kCFAllocatorDefault, 
                                                  (UInt8*)fileCurrPos_, len, 
                                                  currentEncoding_, isExternal,
                                                  kCFAllocatorNull);

    if (!s) {
        // if failed, try system encoding, usually MacRoman
        CFStringEncoding encoding = CFStringGetSystemEncoding();
        s = CFStringCreateWithBytesNoCopy(kCFAllocatorDefault, 
                                          (UInt8*)fileCurrPos_, len, 
                                          encoding, isExternal,
                                          kCFAllocatorNull);
    }
    if (!s) {
        return nil;
    }
    NSString* str = (NSString*)s;
    // lines that are too long might slow down or even hang display in
    // NSOutlineView, so limit them to a reasonable size
    if ([str length] > MAX_LINE_LEN) {
        str = [str substringToIndex:MAX_LINE_LEN];
    }
    fileCurrPos_ = curr;
    *lineNo = ++currLineNo_;
    return str;
}

@end
