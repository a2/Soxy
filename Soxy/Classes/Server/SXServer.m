//
//  SXProxyServer.m
//  Soxy
//
//  Created by Alexsander Akers on 11/10/12.
//  Copyright (c) 2012 Pandamonia LLC. All rights reserved.
//

#import "SXServer.h"
#import "SXServerSubclass.h"

@interface SXServer ()

@property (nonatomic, readwrite) SXServerState state;
@property (nonatomic, strong) NSNetService *netService;

@end

@implementation SXServer

- (BOOL) start
{
	BOOL didStart = NO;
	if (self.state == SXServerStateStopped)
	{
		self.state = SXServerStateStarting;
		didStart = [self serverWillStart];
		if (!didStart) [self serverFailedToStart];
	}
	
	return didStart;
}
- (BOOL) serverWillStart
{
	return YES;
}

- (id) init
{
	if ([self class] == [SXServer class])
	{
		[NSException raise: NSInternalInconsistencyException format: @"Error, attempting to instantiate SXProxyServer directly."];
	}
	else if ((self = [super init]))
	{
		self.state = SXServerStateStopped;
	}
	
	return self;
}

+ (instancetype) sharedServer
{
	static NSMutableDictionary *servers;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		servers = [NSMutableDictionary dictionary];
	});
	
	NSString *key = NSStringFromClass(self);
	id server = servers[key];
	if (!server)
	{
		server = [[self alloc] init];
		servers[key] = server;
	}
	
	return server;
}

+ (NSString *) serviceDomain
{
	SXMustOverrideSelector(_cmd);
	return nil;
}

+ (NSUInteger) servicePort
{
	SXMustOverrideSelector(_cmd);
	return 0;
}

- (void) serverDidStart
{
	NSString *type = [[self class] serviceDomain];
	NSUInteger port = [[self class] servicePort];
	self.netService = [[NSNetService alloc] initWithDomain: @"" type: type name: @"" port: port];
	self.netService.delegate = self;
	[self.netService publish];
	
	self.state = SXServerStateRunning;
}
- (void) serverFailedToStart
{
	self.state = SXServerStateStopped;
}
- (void) serverDidStop
{
	[self.netService stop];
	self.netService = nil;
	
	self.state = SXServerStateStopped;
}
- (void) serverWillStop
{
	
}
- (void) stop
{
	if (self.state == SXServerStateRunning)
	{
		self.state = SXServerStateStopping;
		[self serverWillStop];
	}
}

@end
