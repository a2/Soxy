//
//  SXHTTPProxyServer.m
//  Soxy
//
//  Created by Alexsander Akers on 11/10/12.
//  Copyright (c) 2012 Pandamonia LLC. All rights reserved.
//

#import "SXServerSubclass.h"
#import "SXHTTPProxyServer.h"

int polipo_main(int argc, char **argv);

NSString *const SXHTTPProxyServerOnKey = @"HTTPProxyServer.On";

@implementation SXHTTPProxyServer

- (BOOL) serverWillStart
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
		dispatch_sync(dispatch_get_main_queue(), ^{
			[self serverDidStart];
		});
		
		NSString *configurationPath = [[NSBundle mainBundle] pathForResource: @"polipo" ofType: @"config"];
		
		char *args[] = {
			"test",
			"-c",
			(char *) configurationPath.UTF8String,
			"proxyAddress=0.0.0.0",
			(char *) [[NSString stringWithFormat: @"proxyPort=%d", [[self class] servicePort]] UTF8String]
		};
		polipo_main(5, args);
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[self serverDidStop];
		});
	});
	
	return YES;
}

+ (NSString *) serviceDomain
{
	return SXHTTPProxyServerDomain;
}

+ (NSUInteger) servicePort
{
	return SXHTTPProxyServerPort;
}

#pragma mark - Proxy Server

+ (NSString *) proxyAutoConfigPath
{
	return @"http.pac";
}
+ (NSString *) proxyAutoConfigContentsForIPAddress: (NSString *) address
{
    return [NSString stringWithFormat: @"function FindProxyForURL(url, host) { return \"PROXY %@:%d\"; }", address, self.servicePort];
}

@end
