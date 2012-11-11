//
//  SXHTTPServer.h
//  Soxy
//
//  Created by Alexsander Akers on 11/10/12.
//  Copyright (c) 2012 Pandamonia LLC. All rights reserved.
//

#import "SXSocketServer.h"

@class HTTPResponseHandler;

@interface SXHTTPServer : SXSocketServer

- (void) closeHandler: (HTTPResponseHandler *) aHandler;

@end
