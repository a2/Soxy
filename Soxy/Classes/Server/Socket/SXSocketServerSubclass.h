//
//  SXSocketServerSubclass.h
//  Soxy
//
//  Created by Alexsander Akers on 11/10/12.
//  Copyright (c) 2012 Pandamonia LLC. All rights reserved.
//

@interface SXSocketServer (SXSocketServerSubclass)

- (void) closeSockets;
- (void) socketServerDidCloseConnection: (NSDictionary *) info;
- (void) socketServerDidOpenConnection: (NSDictionary *) info;

@end
