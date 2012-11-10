//
//  SXDefinitions.h
//  Soxy
//
//  Created by Alexsander Akers on 11/10/12.
//  Copyright (c) 2012 Pandamonia LLC. All rights reserved.
//

extern NSString *const SXApplicationErrorDomain;
extern NSString *const SXHTTPProxyDomain;
extern NSString *const SXHTTPServerDomain;
extern NSString *const SXSOCKSProxyDomain;

extern NSUInteger const SXHTTPProxyPort;
extern NSUInteger const SXHTTPServerPort;
extern NSUInteger const SXSOCKSProxyPort;

#pragma mark - Pragma Defines

#define CFSafeRelease(obj) do { if (obj) CFRelease(obj), obj = NULL; } while (0)
#define NSAssertProperty(prop) NSAssert2(self.prop, @"An instance of %s requires a non-nil %s", object_getClassName(self), #prop)
#define RXCompare(left, right) ((left) == (right) ? NSOrderedSame : ((left) - (right))/abs((left) - (right)))
#define RXFormatDouble(d) ([NSNumberFormatter localizedStringFromNumber: @(d) numberStyle: NSNumberFormatterDecimalStyle]) // ([[NSNumber numberWithDouble: (d)] descriptionWithLocale: [NSLocale currentLocale]])
#define UIApp ((UIApplication *) [UIApplication sharedApplication])

#pragma mark - Functions

extern void CGRectCenterInRect(CGRect *inner, CGRect outer);
