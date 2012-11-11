//
//  SXAppDelegate.m
//  Soxy
//
//  Created by Alexsander Akers on 11/10/12.
//  Copyright (c) 2012 Pandamonia LLC. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import <netinet/in.h>
#import <SystemConfiguration/SystemConfiguration.h>

#import "Reachability.h"
#import "SXAppDelegate.h"
#import "SXHTTPProxyServer.h"
#import "SXHTTPServer.h"
#import "SXSOCKSProxyServer.h"

static uint32_t const kSCNetworkFlagsIsDirectWWAN = (1 << 18);
static void SXAppDelegateWWANCallback(void *context);
static void *SXProxyServerStateKVOContext;

@interface SXAppDelegate () <NSStreamDelegate>

@property (nonatomic) BOOL hasNetwork;
@property (nonatomic) BOOL hasWifi;
@property (nonatomic, getter = isServerRunning) BOOL serverRunning;
@property (nonatomic, strong) Reachability *reachability;

@end

@implementation SXAppDelegate

- (void) checkServerStatus
{
	BOOL serverRunning = NO;
	serverRunning |= [[SXHTTPProxyServer sharedServer] state] != SXServerStateStopped;
	serverRunning |= [[SXSOCKSProxyServer sharedServer] state] != SXServerStateStopped;
	
	self.serverRunning = serverRunning;
}
- (void) observeValueForKeyPath: (NSString *) keyPath ofObject: (id) object change: (NSDictionary *) change context: (void *) context
{
	if (context == &SXProxyServerStateKVOContext)
	{
		[self checkServerStatus];
	}
	else
	{
		[super observeValueForKeyPath: keyPath ofObject: object change: change context: context];
	}
}
- (void) setHasNetwork: (BOOL) hasNetwork
{
	if (hasNetwork != _hasNetwork)
		AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
	
	_hasNetwork = hasNetwork;
}
- (void) setServerRunning: (BOOL) serverRunning
{
	if (serverRunning == _serverRunning)
		return;
	
	if (serverRunning)
	{
		[[SXHTTPServer sharedServer] start];
	}
	else
	{
		[[SXHTTPServer sharedServer] stop];
	}
	
	_serverRunning = serverRunning;
}

#pragma mark - Application Delegate

- (BOOL) application: (UIApplication *) application didFinishLaunchingWithOptions: (NSDictionary *) launchOptions
{
    // Override point for customization after application launch.
	[[SXHTTPProxyServer sharedServer] addObserver: self forKeyPath: @"state" options: NSKeyValueObservingOptionNew context: &SXProxyServerStateKVOContext];
	[[SXSOCKSProxyServer sharedServer] addObserver: self forKeyPath: @"state" options: NSKeyValueObservingOptionNew context: &SXProxyServerStateKVOContext];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey: SXHTTPProxyServerOnKey])
		[[SXHTTPProxyServer sharedServer] start];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey: SXSOCKSProxyServerOnKey])
		[[SXSOCKSProxyServer sharedServer] start];
	
	self.reachability = [Reachability reachabilityForInternetConnection];
	
	__weak __typeof__(self) weakSelf = self;
	self.reachability.reachableBlock = self.reachability.unreachableBlock = ^(Reachability *reachability) {
		SCNetworkReachabilityFlags flags = reachability.reachabilityFlags;
		weakSelf.hasNetwork = (flags & kSCNetworkFlagsReachable) ? YES : NO;
		weakSelf.hasWifi = (flags & kSCNetworkFlagsIsDirectWWAN) ? NO : weakSelf.hasNetwork;
	};

	[self checkServerStatus];
	
    return YES;
}

- (void) applicationDidBecomeActive: (UIApplication *) application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}
- (void) applicationDidEnterBackground: (UIApplication *) application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}
- (void) applicationWillEnterForeground: (UIApplication *) application
{
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}
- (void) applicationWillResignActive: (UIApplication *) application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	[[SXSOCKSProxyServer sharedServer] saveTotalBytes];
}
- (void) applicationWillTerminate: (UIApplication *) application
{
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	[[SXHTTPProxyServer sharedServer] removeObserver: self forKeyPath: @"state" context: &SXProxyServerStateKVOContext];
	[[SXSOCKSProxyServer sharedServer] removeObserver: self forKeyPath: @"state" context: &SXProxyServerStateKVOContext];
}

@end

static void SXAppDelegateWWANCallback(void *context)
{
	SXAppDelegate *self = (__bridge id) context;
	NSLog(@"WOOT! %@", self);
}

