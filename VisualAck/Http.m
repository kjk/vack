#import "Http.h"

static NSString * const BOUNDRY = @"0xKhTmLbOuNdArY";
static NSString * const FORM_FLE_INPUT = @"file";

@interface Http (Private)

- (void)upload:(NSData*)aData;

- (NSURLRequest *)postRequestWithURL: (NSURL *)url
                             boundry: (NSString *)boundry
                                data: (NSData *)data;
- (void)uploadSucceeded: (BOOL)success;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;

@end

@implementation Http

- (void)dealloc {
    [serverURL_ release];
    [reply_ release];
    [delegate_ release];
    [filePath_ release];
    [super dealloc];
}

- (id)initAndUploadWithURL: (NSURL *)aServerURL
                      data: (NSData *)aData
                  filePath: (NSString*)filePath
                  delegate: (id)aDelegate
              doneSelector: (SEL)aDoneSelector
             errorSelector: (SEL)anErrorSelector {

    if ((self = [super init])) {		
        serverURL_ = [aServerURL retain];
        delegate_ = [aDelegate retain];
        doneSelector_ = aDoneSelector;
        errorSelector_ = anErrorSelector;
        filePath_ = [filePath copy];
        [self upload:aData];
    }
    return self;
}

- (void)uploadSucceeded: (BOOL)success  {
    [delegate_ performSelector:success ? doneSelector_ : errorSelector_
                   withObject:self];
}

- (NSURLRequest *)postRequestWithURL: (NSURL *)url
                             boundry: (NSString *)boundry
                                data: (NSData *)aData {

    // from http://www.cocoadev.com/index.pl?HTTPFileUpload
    NSMutableURLRequest *urlRequest =
    [NSMutableURLRequest requestWithURL:url];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue:
     [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundry]
      forHTTPHeaderField:@"Content-Type"];
    
    NSMutableData *postData = [NSMutableData dataWithCapacity:[aData length] + 512];
    [postData appendData: [[NSString stringWithFormat:@"--%@\r\n", boundry] dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:
     [[NSString stringWithFormat:
       @"Content-Disposition: form-data; name=\"%@\"; filename=\"test.bin\"\r\n\r\n", FORM_FLE_INPUT]
      dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:aData];
    [postData appendData:
     [[NSString stringWithFormat:@"\r\n--%@--\r\n", boundry] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [urlRequest setHTTPBody:postData];
    return urlRequest;
}

- (void)upload:(NSData*)data {
    if (!data || (0 == [data length]))
        goto Error;

    NSURLRequest *urlRequest = [self postRequestWithURL:serverURL_
                                                boundry:BOUNDRY
                                                   data:data];
    if (!urlRequest)
        goto Error;

    NSURLConnection * connection =
            [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];

    if (!connection)
        goto Error;
    
    // Now wait for the URL connection to call us back.
    return;
Error:
    [self uploadSucceeded:NO];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [connection release];
    [self uploadSucceeded:uploadDidSucceed_];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if (error) {
        NSLog(@"connection:didFailWithError: error:%@", [error localizedDescription]);
    }
    [connection release];
    [self uploadSucceeded:NO];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)aData {
    reply_ = [[NSString alloc] initWithData:aData encoding:NSUTF8StringEncoding];
    uploadDidSucceed_ = YES;
}

- (NSString*)reply {
    return reply_;
}

- (NSString*)filePath {
    return filePath_;
}

@end
