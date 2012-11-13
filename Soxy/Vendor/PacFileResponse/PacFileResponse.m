//
//  AppTextFileResponse.m
//  TextTransfer
//
//  Created by Matt Gallagher on 2009/07/13.
//  Copyright 2009 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import "PacFileResponse.h"
#import "SXHTTPServer.h"

#import "SXHTTPProxyServer.h"
#import "SXSOCKSProxyServer.h"

@implementation PacFileResponse

//
// load
//
// Implementing the load method and invoking
// [HTTPResponseHandler registerHandler:self] causes HTTPResponseHandler
// to register this class in the list of registered HTTP response handlers.
//
+ (void)load
{
	[HTTPResponseHandler registerHandler:self];
}

//
// canHandleRequest:method:url:headerFields:
//
// Class method to determine if the response handler class can handle
// a given request.
//
// Parameters:
//    aRequest - the request
//    requestMethod - the request method
//    requestURL - the request URL
//    requestHeaderFields - the request headers
//
// returns YES (if the handler can handle the request), NO (otherwise)
//
+ (BOOL)canHandleRequest:(CFHTTPMessageRef)aRequest
                  method:(NSString *)requestMethod
                     url:(NSURL *)requestURL
            headerFields:(NSDictionary *)requestHeaderFields
{
    return YES;
}

- (id)init
{
    self = [super init];
    if (self) {
        servers = [[NSMutableDictionary alloc] init];
        [servers setObject:[SXSOCKSProxyServer class] forKey:[SXSOCKSProxyServer proxyAutoConfigPath]];
        [servers setObject:[SXHTTPProxyServer class] forKey:[SXHTTPProxyServer proxyAutoConfigPath]];
    }
    return self;
}

//
// startResponse
//
// Since this is a simple response, we handle it synchronously by sending
// everything at once.
//
- (void)startResponse
{
    NSData *fileData = nil;
    NSString *currentIP = [self serverIPForRequest];
    NSString *requestPath = [url path];
    
    if (currentIP && [servers objectForKey:requestPath]) {
        fileData = [[[servers objectForKey:requestPath] proxyAutoConfigContentsForIPAddress: currentIP] dataUsingEncoding:NSUTF8StringEncoding];
    }
    if (fileData) {
        CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 
                                    200, 
                                    NULL, 
                                    kCFHTTPVersion1_1);

        CFHTTPMessageSetHeaderFieldValue(response, 
                                         (CFStringRef)@"Content-Type", 
                                         (CFStringRef)@"application/x-ns-proxy-autoconfig");
        CFHTTPMessageSetHeaderFieldValue(response, 
                                         (CFStringRef)@"Connection", 
                                         (CFStringRef)@"close");
        CFHTTPMessageSetHeaderFieldValue(response,
                                         (CFStringRef)@"Content-Length",
                                         (__bridge CFStringRef)[NSString stringWithFormat:@"%d", [fileData length]]);

        CFDataRef headerData = CFHTTPMessageCopySerializedMessage(response);
        
        @try
        {
            [fileHandle writeData:(__bridge NSData *)headerData];
            [fileHandle writeData:fileData];
        }
        @catch (NSException *exception)
        {
            // Ignore the exception, it normally just means the client
            // closed the connection from the other end.
        }
        @finally
        {
            CFRelease(headerData);
            [server closeHandler:self];
        }
    } else {
        CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 
                                    currentIP ? 404 : 500, 
                                    NULL, 
                                    kCFHTTPVersion1_1);

        CFDataRef headerData = CFHTTPMessageCopySerializedMessage(response);
        
        @try
        {
            [fileHandle writeData:(__bridge NSData *)headerData];
        }
        @catch (NSException *exception)
        {
            // Ignore the exception, it normally just means the client
            // closed the connection from the other end.
        }
        @finally
        {
            CFRelease(headerData);
            [server closeHandler:self];
        }
    }
}

@end
