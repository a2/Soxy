//
//  SXProxyServerSubclass.h
//  Soxy
//
//  Created by Alexsander Akers on 11/10/12.
//  Copyright (c) 2012 Pandamonia LLC. All rights reserved.
//

#import "SXServer.h"

@interface SXServer (ForSubclassEyesOnly) <NSNetServiceDelegate>

@property (nonatomic, readwrite) SXServerState state;

- (BOOL) serverWillStart;

- (void) serverDidStart;
- (void) serverDidStop;
- (void) serverFailedToStart;
- (void) serverWillStop;

@end
