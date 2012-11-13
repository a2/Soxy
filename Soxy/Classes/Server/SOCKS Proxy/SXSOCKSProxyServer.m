//
//  SXSOCKSProxyServer.m
//  Soxy
//
//  Created by Alexsander Akers on 11/10/12.
//  Copyright (c) 2012 Pandamonia LLC. All rights reserved.
//

#import "SXServerSubclass.h"
#import "SXSOCKSProxyServer.h"
#import "SXSocketServerSubclass.h"
#import "srelay.h"

extern void (*log_end_transfer_callback)(SOCK_INFO *si, LOGINFO *li, struct timeval elp, const char *prc_ip, const char *prc_port, const char *myc_ip, const char *myc_port, const char *mys_ip, const char *mys_port, const char *prs_ip, const char *prs_port);
extern void (*log_tmp_transfer_callback)(SOCK_INFO *si, LOGINFO *li, ssize_t download, ssize_t upload);
extern void (*msg_out_callback)__P((int, const char *, ...));

static NSString *const SXSOCKSProxyServerTotalDownloadKey = @"SOCKSProxyServer.TotalDownload";
static NSString *const SXSOCKSProxyServerTotalUploadKey = @"SOCKSProxyServer.TotalUpload";

static void sx_log_end_transfer_callback(SOCK_INFO *si, LOGINFO *li, struct timeval elp, const char *prc_ip, const char *prc_port, const char *myc_ip, const char *myc_port, const char *mys_ip, const char *mys_port, const char *prs_ip, const char *prs_port);
static void sx_log_tmp_transfer_callback(SOCK_INFO *si, LOGINFO *li, ssize_t download, ssize_t upload);

NSString *const SXSOCKSProxyServerOnKey = @"SOCKSProxyServer.On";

@interface SXSOCKSProxyServer () <NSNetServiceDelegate>

@property (nonatomic) UInt64 download;
@property (nonatomic) UInt64 totalDownload;
@property (nonatomic) UInt64 totalUpload;
@property (nonatomic) UInt64 upload;
@property (nonatomic, copy) NSDate *lastBandwidthQueryDate;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@end

@implementation SXSOCKSProxyServer

- (BOOL) getBandwidthStatsForUpload: (double *) uploadBandwidth download: (double *) downloadBandwidth
{
	dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
	
	UInt64 upload = self.upload;
	UInt64 download = self.download;
	self.upload = 0;
	self.download = 0;
	
	dispatch_semaphore_signal(self.semaphore);
	
	if (self.lastBandwidthQueryDate)
	{
		NSDate *now = [NSDate date];
		NSTimeInterval interval = [now timeIntervalSinceDate: self.lastBandwidthQueryDate];
		
		if (uploadBandwidth)
		{
			*uploadBandwidth = interval ? (upload / interval) : 0.0;
		}
		
		if (downloadBandwidth)
		{
			*downloadBandwidth = interval ? (download / interval) : 0.0;
			
			self.lastBandwidthQueryDate = now;
		}
	}
	else
	{
		if (downloadBandwidth) *downloadBandwidth = 0.0;
		if (uploadBandwidth) *uploadBandwidth = 0.0;
	}
	
	return YES;
}
- (BOOL) getTotalBytesForUpload: (UInt64 *) upload download: (UInt64 *) download
{
	dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
	
	if (download) *download = self.totalDownload;
	if (upload) *upload = self.totalUpload;
	
	dispatch_semaphore_signal(self.semaphore);
	
	return YES;
}

- (id) init
{
	if ((self = [super init]))
	{
		self.semaphore = dispatch_semaphore_create(1);
		self.totalDownload = [[[NSUserDefaults standardUserDefaults] objectForKey: SXSOCKSProxyServerTotalDownloadKey] unsignedLongLongValue];
		self.totalUpload = [[[NSUserDefaults standardUserDefaults] objectForKey: SXSOCKSProxyServerTotalUploadKey] unsignedLongLongValue];
	}
	
	return self;
}

+ (NSString *) serviceDomain
{
	return SXSOCKSProxyServerDomain;
}

+ (NSUInteger) servicePort
{
	return SXSOCKSProxyServerPort;
}

+ (void) initialize
{
	if (self == [SXSOCKSProxyServer class])
	{
		msg_out_callback = NULL;
		log_end_transfer_callback = sx_log_end_transfer_callback;
		log_tmp_transfer_callback = sx_log_tmp_transfer_callback;
	}
}
- (void) processIncomingConnection: (NSDictionary *) info
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
		SOCKS_STATE state;
		memset(&state, 0, sizeof(state));
		
		SOCK_INFO si;
		memset(&si, 0, sizeof(si));
		
		state.si = &si;
		
		NSFileHandle *fileHandle = info[@"handle"];
		state.s = fileHandle.fileDescriptor;
		
		if (!proto_socks(&state))
		{
			relay(&state);
			close(state.r);
		}
		
		[fileHandle closeFile];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[self closeConnection: info];
		});
	});
}
- (void) resetTotalBytes
{
	dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
	
	self.totalDownload = 0;
	self.totalUpload = 0;
	
	dispatch_semaphore_signal(self.semaphore);
}
- (void) saveTotalBytes
{
	dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);

	[[NSUserDefaults standardUserDefaults] setObject: @(self.totalDownload) forKey: SXSOCKSProxyServerTotalDownloadKey];
	[[NSUserDefaults standardUserDefaults] setObject: @(self.totalUpload) forKey: SXSOCKSProxyServerTotalUploadKey];
	
	dispatch_semaphore_signal(self.semaphore);
}
- (void) serverDidStop
{
	[self saveTotalBytes];
	[super serverDidStop];

}
- (void) socketServerDidCloseConnection: (NSDictionary *) info
{
	
}
- (void) socketServerDidOpenConnection: (NSDictionary *) info
{
	if (!self.lastBandwidthQueryDate)
		self.lastBandwidthQueryDate = [NSDate date];
	
	[self processIncomingConnection: info];
}
- (void) updateTemporaryTransferWithSocket: (SOCK_INFO *) si logInfo: (LOGINFO *) li download: (ssize_t) download upload: (ssize_t) upload
{
	dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
	
	self.download += download;
	self.upload += upload;
	self.totalDownload += download;
	self.totalUpload += upload;
	
	dispatch_semaphore_signal(self.semaphore);
}

#pragma mark - Proxy Server

+ (NSString *)proxyAutoConfigPath
{
	return @"socks.pac";
}
+ (NSString *)proxyAutoConfigContentsForIPAddress: (NSString *) address
{
	return [NSString stringWithFormat: @"function FindProxyForURL(url, host) { return \"SOCKS %@:%d\"; }", address, self.servicePort];
}

@end

static void sx_log_end_transfer_callback(SOCK_INFO *si, LOGINFO *li, struct timeval elp, const char *prc_ip, const char *prc_port, const char *myc_ip, const char *myc_port, const char *mys_ip, const char *mys_port, const char *prs_ip, const char *prs_port)
{
	
}
static void sx_log_tmp_transfer_callback(SOCK_INFO *si, LOGINFO *li, ssize_t download, ssize_t upload)
{
    [[SXSOCKSProxyServer sharedServer] updateTemporaryTransferWithSocket: si logInfo: li download: download upload: upload];
}
