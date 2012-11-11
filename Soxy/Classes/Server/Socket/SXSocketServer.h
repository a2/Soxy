//
//  SXSocketServer.h
//  Soxy
//
//  Created by Alexsander Akers on 11/10/12.
//  Copyright (c) 2012 Pandamonia LLC. All rights reserved.
//

#import "SXServer.h"

extern NSString *const SXSocketServerErrorDomain;

typedef NS_ENUM(NSInteger, SXSocketServerError)
{
	SXSocketServerErrorUnableToCreateSocket,
	SXSocketServerErrorUnableToSetSocketOptions,
	SXSocketServerErrorUnableToBindSocketToAddress,
	SXSocketServerErrorUnableToBindSocketTOAddress6
};

@interface SXSocketServer : SXServer

@property (nonatomic, readonly) NSUInteger connectionCount;
@property (nonatomic, readonly) NSUInteger IPAddressCount;
@property (nonatomic, strong, readonly) NSError *lastError;

- (void) closeConnection: (NSDictionary *) info;

@end
