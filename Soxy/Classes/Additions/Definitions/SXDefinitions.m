//
//  SXDefinitions.m
//  Soxy
//
//  Created by Alexsander Akers on 11/10/12.
//  Copyright (c) 2012 Pandamonia LLC. All rights reserved.
//

#import "SXDefinitions.h"

NSString *const SXApplicationErrorDomain = @"SoxyErrorDomain";
NSString *const SXHTTPProxyDomain = @"_soxyhttpserver._tcp.";
NSString *const SXHTTPServerDomain = @"_soxyhttpserver._tcp.";
NSString *const SXSOCKSProxyDomain = @"_soxysocksproxy._tcp.";

NSUInteger const SXHTTPProxyPort = 8888;
NSUInteger const SXHTTPServerPort = 8000;
NSUInteger const SXSOCKSProxyPort = 1080;

void CGRectCenterInRect(CGRect *inner, CGRect outer)
{
	NSCParameterAssert(inner != NULL);
	(*inner).origin.x = CGRectGetMinX(outer) + 0.5 * round(CGRectGetWidth (outer) - CGRectGetWidth (*inner));
	(*inner).origin.y = CGRectGetMinY(outer) + 0.5 * round(CGRectGetHeight(outer) - CGRectGetHeight(*inner));
}
