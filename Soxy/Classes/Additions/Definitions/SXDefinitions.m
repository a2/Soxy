//
//  SXDefinitions.m
//  Soxy
//
//  Created by Alexsander Akers on 11/10/12.
//  Copyright (c) 2012 Pandamonia LLC. All rights reserved.
//

#import "SXDefinitions.h"

NSString *const SXApplicationErrorDomain = @"SoxyErrorDomain";

void CGRectCenterInRect(CGRect *inner, CGRect outer)
{
	NSCParameterAssert(inner != NULL);
	(*inner).origin.x = CGRectGetMinX(outer) + 0.5 * round(CGRectGetWidth (outer) - CGRectGetWidth (*inner));
	(*inner).origin.y = CGRectGetMinY(outer) + 0.5 * round(CGRectGetHeight(outer) - CGRectGetHeight(*inner));
}
