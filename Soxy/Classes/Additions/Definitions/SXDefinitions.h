//
//  SXDefinitions.h
//  Soxy
//
//  Created by Alexsander Akers on 11/10/12.
//  Copyright (c) 2012 Pandamonia LLC. All rights reserved.
//

extern NSString *const SXApplicationErrorDomain;
extern NSString *const SXHTTPProxyServerDomain;
extern NSString *const SXHTTPServerDomain;
extern NSString *const SXSOCKSProxyServerDomain;

extern NSUInteger const SXHTTPProxyServerPort;
extern NSUInteger const SXHTTPServerPort;
extern NSUInteger const SXSOCKSProxyServerPort;

#pragma mark - Pragma Defines

#define CFSafeRelease(obj) do { if (obj) CFRelease(obj), obj = NULL; } while (0)
#define NSAssertProperty(prop) NSAssert2(self.prop, @"An instance of %s requires a non-nil %s", object_getClassName(self), #prop)
#define SXMustOverrideSelector(sel) [NSException raise: NSInternalInconsistencyException format: @"You must override %@ in a subclass.", NSStringFromSelector(sel)]
#define UIApp ((UIApplication *) [UIApplication sharedApplication])
