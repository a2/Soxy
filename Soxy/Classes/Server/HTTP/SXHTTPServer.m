//
//  SXHTTPServer.m
//  Soxy
//
//  Created by Alexsander Akers on 11/10/12.
//  Copyright (c) 2012 Pandamonia LLC. All rights reserved.
//

#import "HTTPResponseHandler.h"
#import "SXHTTPServer.h"
#import "SXSocketServerSubclass.h"

@interface SXHTTPServer ()

@property (nonatomic, strong) NSMutableArray *responseHandlers;
@property (nonatomic, strong) NSMutableDictionary *incomingRequests;

@end

@implementation SXHTTPServer

- (id) init
{
	if ((self = [super init]))
	{
		self.incomingRequests = [NSMutableDictionary dictionary];
		self.responseHandlers = [NSMutableArray array];
	}
	
	return self;
}

+ (NSString *)serviceDomain
{
	return SXHTTPServerDomain;
}

+ (NSUInteger)servicePort
{
	return SXHTTPServerPort;
}

- (void) closeHandler: (HTTPResponseHandler *) aHandler
{
	[aHandler endResponse];
	[self.responseHandlers removeObject: aHandler];
}
- (void) closeSockets
{
	[super closeSockets];
	[self.incomingRequests.allKeys each: ^(NSFileHandle *incomingFileHandle) {
		[self stopReceivingForFileHandle: incomingFileHandle close: YES];
	}];
}
- (void) fileHandleDataAvailable: (NSNotification *) note
{
	NSFileHandle *incomingFileHandle = note.object;
	NSData *data = incomingFileHandle.availableData;
	
	if (!data.length)
		return [self stopReceivingForFileHandle: incomingFileHandle close: NO];
	
	CFHTTPMessageRef incomingRequest = (__bridge CFHTTPMessageRef) self.incomingRequests[incomingFileHandle];
	
	if (!CFHTTPMessageAppendBytes(incomingRequest, data.bytes, data.length))
		return [self stopReceivingForFileHandle: incomingFileHandle close: NO];
	
	if (CFHTTPMessageIsHeaderComplete(incomingRequest))
	{
		HTTPResponseHandler *handler = [HTTPResponseHandler handlerForRequest: incomingRequest fileHandle: incomingFileHandle server: self];
		[self.responseHandlers addObject: handler];
		[self stopReceivingForFileHandle: incomingFileHandle close: NO];
		
		[handler startResponse];
		return;
	}
	
	[incomingFileHandle waitForDataInBackgroundAndNotify];
}
- (void) socketServerDidOpenConnection: (NSDictionary *) info
{
	if (!info) return;
	
	NSFileHandle *handle = info[@"handle"];
	CFHTTPMessageRef message = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, true);
	self.incomingRequests[(id) handle] = (__bridge id) message;
	CFSafeRelease(message);
	
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(fileHandleDataAvailable:) name: NSFileHandleDataAvailableNotification object: handle];
	[handle waitForDataInBackgroundAndNotify];
}
- (void) stopReceivingForFileHandle: (NSFileHandle *) incomingFileHandle close: (BOOL) close
{
	if (close) [incomingFileHandle closeFile];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self name: NSFileHandleDataAvailableNotification object: incomingFileHandle];
	[self.incomingRequests removeObjectForKey: incomingFileHandle];
}

@end
