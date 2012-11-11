//
//  SXSocketServer.m
//  Soxy
//
//  Created by Alexsander Akers on 11/10/12.
//  Copyright (c) 2012 Pandamonia LLC. All rights reserved.
//

#import <malloc/malloc.h>
#import <netinet/in.h>

#import "SXServerSubclass.h"
#import "SXSocketServer.h"
#import "SXSocketServerSubclass.h"

NSString *const SXSocketServerErrorDomain = @"SXSocketServerErrorDomain";

static void SXSocketCallBack(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info);

@interface SXSocketServer ()

@property (nonatomic, readwrite) NSUInteger connectionCount;
@property (nonatomic, strong) NSMutableDictionary *connectionsPerIP;
@property (nonatomic, strong, readwrite) NSError *lastError;
@property (nonatomic) CFSocketRef *sockets; // [2]
@property (nonatomic) CFRunLoopSourceRef *runLoopSources; // [2]

@end

@implementation SXSocketServer

- (BOOL) openSockets
{
	[self createSockets];
	
	CFRunLoopRef rl = CFRunLoopGetCurrent();
	
	unsigned int count = malloc_size(self.sockets) / sizeof(self.sockets[0]);
	for (unsigned int i = 0; i < count; ++i)
	{
		// Create the run loop source for putting on the run loop.
		if (!self.sockets[i])
			continue;
		
		if (!(self.runLoopSources[i] = CFSocketCreateRunLoopSource(kCFAllocatorDefault, self.sockets[i], 0)))
			break;
		
		// Add the run loop source to the current run loop and default mode.
		CFRunLoopAddSource(rl, self.runLoopSources[i], kCFRunLoopCommonModes);
	}
	
	struct sockaddr_in addr4;
	memset(&addr4, 0, sizeof(addr4));
	
	// Put the local port and address into the native address.
	addr4.sin_len = sizeof(addr4);
	addr4.sin_family = AF_INET;
	addr4.sin_port = htons((UInt16) [[self class] servicePort]);
	addr4.sin_addr.s_addr = htonl(INADDR_ANY);
	
	// Wrap the native address structure for CFSocketCreate.
	CFDataRef addressData = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, (const UInt8 *) &addr4, sizeof(addr4), kCFAllocatorNull);
	
	// Set the local binding which causes the socket to start listening.
	if (CFSocketSetAddress(self.sockets[0], addressData) != kCFSocketSuccess)
	{
		CFSafeRelease(addressData);
		if (self.sockets[0])
		{
			CFSocketInvalidate(self.sockets[0]);
			CFSafeRelease(self.sockets[0]);
		}
		self.lastError = [NSError errorWithDomain: SXSocketServerErrorDomain code: SXSocketServerErrorUnableToBindSocketToAddress userInfo: @{ NSLocalizedDescriptionKey : NSLocalizedStringFromTable(@"Unable to bind socket to address.", @"SXSocketServerErrors", nil) }];
		return NO;
	}
	
	CFSafeRelease(addressData);
	
	if (self.sockets[1])
	{
		struct sockaddr_in6 addr6;
		memset(&addr6, 0, sizeof(addr6));
		
		// Put the local port and address into the native address.
		addr6.sin6_family = AF_INET6;
		addr6.sin6_port = htons((UInt16) [[self class] servicePort]);
		addr6.sin6_len = sizeof(addr6);
		memcpy(&(addr6.sin6_addr), &in6addr_any, sizeof(addr6.sin6_addr));
		
		// Wrap the native address structure for CFSocketCreate.
		addressData = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, (const UInt8 *) &addr6, sizeof(addr6), kCFAllocatorNull);
		
		// Set the local binding which causes the socket to start listening.
		if (CFSocketSetAddress(self.sockets[1], addressData) != kCFSocketSuccess)
		{
			CFSafeRelease(addressData);
			if (self.sockets[1])
			{
				CFSocketInvalidate(self.sockets[1]);
				CFSafeRelease(self.sockets[1]);
			}
			self.lastError = [NSError errorWithDomain: SXSocketServerErrorDomain code: SXSocketServerErrorUnableToBindSocketToAddress userInfo: @{ NSLocalizedDescriptionKey : NSLocalizedStringFromTable(@"Unable to bind socket to address.", @"SXSocketServerErrors", nil) }];
			return NO;
		}
		
		CFSafeRelease(addressData);
	}
	
	return YES;
}
- (BOOL) serverWillStart
{
	BOOL started;
	
	started = [self openSockets];
	if (started) [self serverDidStart];
	
	return started;
}

- (id) init
{
	if ((self = [super init]))
	{
		self.connectionsPerIP = [NSMutableDictionary dictionary];
		self.runLoopSources = calloc(2, sizeof(CFRunLoopSourceRef));
		self.sockets = calloc(2, sizeof(CFSocketRef));
	}
	
	return self;
}

- (NSUInteger) IPAddressCount
{
	return self.connectionsPerIP.count;
}

- (void) closeConnection: (NSDictionary *) info
{
	[self willChangeValueForKey: @"connectionCount"];
	
	_connectionCount--;
	
	[(NSFileHandle *) info[@"handle"] closeFile];
	
	NSString *ip = info[@"ip"];
	NSMutableSet *connections = self.connectionsPerIP[ip];
	[connections removeObject: info[@"handle"]];
	
	if (connections && connections.count == 0)
	{
		[self willChangeValueForKey: @"IPAddressCount"];
		[self.connectionsPerIP removeObjectForKey: ip];
		[self didChangeValueForKey: @"IPAddressCount"];
	}
	
	[self socketServerDidCloseConnection: info];
	
	[self didChangeValueForKey: @"connectionCount"];
}
- (void) createSockets
{
	bool reuse = true;
	CFSocketContext socketCtx = {
		.version = 0,
		.info = (__bridge void *) self,
		.retain = &CFRetain,
		.release = &CFRelease,
		.copyDescription = &CFCopyDescription
	};
	SInt32 protocolFamilies[] = { PF_INET, PF_INET6 };
	
	for (int i = 0; i < 2; ++i)
	{
		if (!(self.sockets[i] = CFSocketCreate(kCFAllocatorDefault, protocolFamilies[i], SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, &SXSocketCallBack, &socketCtx)))
		{
			self.lastError = [NSError errorWithDomain: SXSocketServerErrorDomain code: SXSocketServerErrorUnableToCreateSocket userInfo: @{ NSLocalizedDescriptionKey : NSLocalizedStringFromTable(@"Unable to create socket.", @"SXSocketServerErrors", nil) }];
			return;
		}
		
		if (setsockopt(CFSocketGetNative(self.sockets[i]), SOL_SOCKET, SO_REUSEADDR, &reuse, sizeof(int)))
		{
			CFSocketInvalidate(self.sockets[i]);
			CFSafeRelease(self.sockets[i]);
			self.lastError = [NSError errorWithDomain: SXSocketServerErrorDomain code: SXSocketServerErrorUnableToSetSocketOptions userInfo: @{ NSLocalizedDescriptionKey : NSLocalizedStringFromTable(@"Unable to set socket options.", @"SXSocketServerErrors", nil) }];
			return;
		}
	}
}
- (void) closeSockets
{
	[[NSNotificationCenter defaultCenter] removeObserver: self name: NSFileHandleConnectionAcceptedNotification object: nil];
	
	[self.connectionsPerIP.allValues each: ^(NSMutableSet *connections) {
		[connections makeObjectsPerformSelector: @selector(closeFile)];
	}];
	
	CFRunLoopRef rl = CFRunLoopGetCurrent();
	unsigned int count = malloc_size(self.sockets) / sizeof(self.sockets[0]);
	for (unsigned int i = 0; i < count; ++i)
	{
		if (self.runLoopSources[i])
		{
			CFRunLoopRemoveSource(rl, self.runLoopSources[i], kCFRunLoopCommonModes);
			CFSafeRelease(self.runLoopSources[i]);
		}
		
		if (self.sockets[i])
		{
			CFSocketInvalidate(self.sockets[i]);
			CFSafeRelease(self.sockets[i]);
		}
	}
}
- (void) didReceiveIncomingConnectionWithInfo: (NSDictionary *) info
{
	[self willChangeValueForKey: @"connectionCount"];
	
	_connectionCount++;
	
	NSString *ip = info[@"ip"];
	NSMutableSet *connections = self.connectionsPerIP[ip];
	if (!connections)
	{
		[self willChangeValueForKey: @"IPAddressCount"];
		connections = [NSMutableSet setWithCapacity: 1];
		self.connectionsPerIP[ip] = connections;
		[self didChangeValueForKey: @"IPAddressCount"];
	}
	[connections addObject: info[@"handle"]];
	[self socketServerDidOpenConnection: info];
	
	[self didChangeValueForKey: @"connectionCount"];
}
- (void) setLastError: (NSError *) lastError
{
	_lastError = lastError;
	NSLog(@"SXSocketServer Error: %@", lastError);
}
- (void) socketCallbackWithSocket: (CFSocketRef) sock type: (CFSocketCallBackType) type address: (CFDataRef) address data: (const void *) data
{
	assert(sock == self.sockets[0] || sock == self.sockets[1]);
	
	// We only care about accept callbacks.
	if (type != kCFSocketAcceptCallBack)
		return;
	
	assert(data != NULL && *(CFSocketNativeHandle *) data != -1);
	
	int description = *(CFSocketNativeHandle *) data;
	NSFileHandle *handle = [[NSFileHandle alloc] initWithFileDescriptor: description];
	NSDictionary *info = @{
		@"handle" : handle,
		@"address": (__bridge NSData *) address,
		@"ip": [NSString stringWithAddressFromSockaddr: (struct sockaddr *) CFDataGetBytePtr(address)]
	};
	[self didReceiveIncomingConnectionWithInfo: info];
}
- (void) socketServerDidCloseConnection: (NSDictionary *) info
{
	
}
- (void) socketServerDidOpenConnection: (NSDictionary *) info
{
	SXMustOverrideSelector(_cmd);
}
- (void) serverWillStop
{
	[self closeSockets];
	[self serverDidStop];
}

@end

static void SXSocketCallBack(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
{
	SXSocketServer *server = (__bridge SXSocketServer *) info;
	[server socketCallbackWithSocket: s type: type address: address data: data];
}
