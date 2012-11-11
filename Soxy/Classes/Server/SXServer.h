//
//  SXProxyServer.h
//  Soxy
//
//  Created by Alexsander Akers on 11/10/12.
//  Copyright (c) 2012 Pandamonia LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SXServerState)
{
	SXServerStateStopped,
	SXServerStateStarting,
	SXServerStateRunning,
	SXServerStateStopping
};

@interface SXServer : NSObject

@property (nonatomic, readonly) SXServerState state;

- (BOOL) start;

+ (instancetype) sharedServer;

+ (NSString *) serviceDomain;

+ (NSUInteger) servicePort;

- (void) stop;

@end

@protocol SXProxyServer <NSObject>

+ (NSString *) proxyAutoConfigPath;
+ (NSString *) proxyAutoConfigContentsForIPAddress: (NSString *) address;

@end
