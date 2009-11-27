#import <Cocoa/Cocoa.h>

@interface Http : NSObject {
    NSURL *         serverURL_;
    id              delegate_;
    NSString *      reply_;
    SEL             doneSelector_;
    SEL             errorSelector_;
    BOOL            uploadDidSucceed_;
    NSString *      filePath_;
}

- (id)initAndUploadWithURL: (NSURL *)serverURL
                      data: (NSData *)data
                  filePath: (NSString*)filePath
                  delegate: (id)delegate
              doneSelector: (SEL)doneSelector
             errorSelector: (SEL)errorSelector;

- (NSString*)reply;
- (NSString*)filePath;

@end
