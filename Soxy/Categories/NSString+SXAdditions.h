//
//  NSString+SXAdditions.h
//  Soxy
//
//  Created by Alexsander Akers on 11/10/12.
//  Copyright (c) 2012 Pandamonia LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sys/socket.h>

@interface NSString (SXAdditions)

+ (id) stringWithAddressFromSockaddr: (struct sockaddr *) genericIP;

@end
