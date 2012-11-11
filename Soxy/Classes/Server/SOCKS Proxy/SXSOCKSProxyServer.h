//
//  SXSOCKSProxyServer.h
//  Soxy
//
//  Created by Alexsander Akers on 11/10/12.
//  Copyright (c) 2012 Pandamonia LLC. All rights reserved.
//

#import "SXSocketServer.h"

extern NSString *const SXSOCKSProxyServerOnKey;

@interface SXSOCKSProxyServer : SXSocketServer <SXProxyServer>

- (BOOL) getBandwidthStatsForUpload: (double *) upload download: (double *) download;
- (BOOL) getTotalBytesForUpload: (UInt64 *) upload download: (UInt64 *) download;

- (void) resetTotalBytes;
- (void) saveTotalBytes;

@end
