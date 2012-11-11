//
//  UINavigationController+A2Additions.m
//  Arex
//
//  Created by Alexsander Akers on 10/5/11.
//  Copyright (c) 2011-2012 Pandamonia LLC. All rights reserved.
//

#import "UINavigationController+A2Additions.h"

@implementation UINavigationController (A2Additions)

- (UIViewController *) rootViewController
{
	return (self.viewControllers.count > 0) ? self.viewControllers[0] : nil;
}

@end
