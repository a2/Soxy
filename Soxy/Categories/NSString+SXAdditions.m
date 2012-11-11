//
//  NSString+SXAdditions.m
//  Soxy
//
//  Created by Alexsander Akers on 11/10/12.
//  Copyright (c) 2012 Pandamonia LLC. All rights reserved.
//

#import <arpa/inet.h>
#import <netinet/in.h>

#import "NSString+SXAdditions.h"

@implementation NSString (SXAdditions)

+ (id) stringWithAddressFromSockaddr: (struct sockaddr *) genericIP
{
	char buffer[255];
	memset(buffer, 0, sizeof(buffer));
	
	switch (genericIP->sa_family)
	{
		case AF_INET:
		{
			struct sockaddr_in *ipv4 = (struct sockaddr_in *) genericIP;
			inet_ntop(genericIP->sa_family, &(ipv4->sin_addr), buffer, sizeof(buffer) - 1);
			break;
		}
			
		case AF_INET6:
		{
			struct sockaddr_in6 *ipv6 = (struct sockaddr_in6 *) genericIP;
			inet_ntop(genericIP->sa_family, &(ipv6->sin6_addr), buffer, sizeof(buffer) - 1);
			break;
		}
			
		case AF_UNSPEC:
			break;
			
		default:
			NSAssert1(NO, @"Unknown sockaddr family %d", genericIP->sa_family);
			break;
	}
	
	return (*buffer) ? [self stringWithFormat: @"%s", buffer] : nil;
}

@end
