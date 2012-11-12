//
//  UIDevice+SXAdditions.m
//  Soxy
//
//  Created by Alexsander Akers on 11/11/12.
//  Copyright (c) 2012 Pandamonia LLC. All rights reserved.
//

#import <arpa/inet.h>
#import <ifaddrs.h>

#import "UIDevice+SXAdditions.h"

@implementation UIDevice (SXAdditions)

- (NSString *) IPAddressForInterface: (NSString *) _interfaceName
{
	const char *interfaceName = _interfaceName.UTF8String;
	NSString *ipAddress = nil;
	struct ifaddrs *interfaces = NULL;
	
	if (getifaddrs(&interfaces) == 0)
	{
		struct ifaddrs *address = interfaces;
		do
		{
			if (!strcmp(address->ifa_name, interfaceName) && address->ifa_addr->sa_family == AF_INET)
			{
				ipAddress = [NSString stringWithAddressFromSockaddr: address->ifa_addr];
				break;
			}
		}
		while ((address = address->ifa_next) != NULL);
	}
	
	freeifaddrs(interfaces);
	
	return ipAddress;
	
}

@end
