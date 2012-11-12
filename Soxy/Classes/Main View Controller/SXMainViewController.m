//
//  SXMainViewController.m
//  Soxy
//
//  Created by Alexsander Akers on 11/10/12.
//  Copyright (c) 2012 Pandamonia LLC. All rights reserved.
//

#import "SXHTTPProxyServer.h"
#import "SXHTTPServer.h"
#import "SXMainViewController.h"
#import "SXSOCKSProxyServer.h"
#import "TTTUnitOfInformationFormatter.h"

extern int fdEventNum;

static NSString *const SXMainViewControllerShowsProxyAutoConfigKey = @"MainViewControllerShowsProxyAutoConfig";

static void *SXSOCKSProxyServerConnectionCountKVOContext;

@interface SXMainViewController ()

@property (nonatomic) BOOL showsProxyAutoConfig;
@property (nonatomic, getter = isApplicationActive) BOOL applicationActive;
@property (nonatomic, getter = isViewVisible) BOOL viewVisible;
@property (nonatomic, getter = isWindowVisible) BOOL windowVisible;
@property (nonatomic, strong) NSTimer *labelTimer;
@property (nonatomic, strong) NSTimer *socksProxyInfoTimer;
@property (nonatomic, strong) NSTimer *updateTransferTimer;
@property (nonatomic, strong) TTTUnitOfInformationFormatter *unitOfInformationFormatter;
@property (nonatomic, strong) UIPopoverController *activityPopoverController;

- (void) sharedInit;

@end

@implementation SXMainViewController

- (id) initWithCoder: (NSCoder *) decoder
{
	if ((self = [super initWithCoder: decoder]))
	{
		[self sharedInit];
	}
	
	return self;
}
- (id) initWithNibName: (NSString *) nibNameOrNil bundle: (NSBundle *) nibBundleOrNil
{
	if ((self = [super initWithNibName: nibNameOrNil bundle: nibBundleOrNil]))
	{
		[self sharedInit];
	}
	
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[[SXSOCKSProxyServer sharedServer] removeObserver: self forKeyPath: @"connectionCount" context: &SXSOCKSProxyServerConnectionCountKVOContext];
}
- (void) observeValueForKeyPath: (NSString *) keyPath ofObject: (id) object change: (NSDictionary *) change context: (void *) context
{
	if (context == &SXSOCKSProxyServerConnectionCountKVOContext)
	{
		[self scheduleSocksProxyInfoTimer];
	}
}
- (void) scheduleSocksProxyInfoTimer
{
	if (!self.socksProxyInfoTimer) self.socksProxyInfoTimer = [NSTimer scheduledTimerWithTimeInterval: 0.5 target: self selector: @selector(updateSocksProxyInfo) userInfo: nil repeats: YES];
}
- (void) sharedInit
{
	self.applicationActive = YES;
	self.showsProxyAutoConfig = [[NSUserDefaults standardUserDefaults] boolForKey: SXMainViewControllerShowsProxyAutoConfigKey];
	self.unitOfInformationFormatter = [[TTTUnitOfInformationFormatter alloc] init];
	self.windowVisible = YES;
	
	[[SXSOCKSProxyServer sharedServer] addObserver: self forKeyPath: @"connectionCount" options: NSKeyValueObservingOptionNew context: &SXSOCKSProxyServerConnectionCountKVOContext];
	
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(applicationWillResignActive:) name: UIApplicationWillResignActiveNotification object: UIApp];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(applicationDidBecomeActive:) name: UIApplicationDidBecomeActiveNotification object: UIApp];
}
- (void) updateHTTPProxy
{
	if (self.httpSwitch.on)
	{
		[[SXHTTPProxyServer sharedServer] start];
		
		self.httpAddressLabel.alpha = 1.0;
		[[self.httpAddressLabel.gestureRecognizers lastObject] setEnabled: YES];
	}
	else
	{
		[[SXHTTPProxyServer sharedServer] stop];
		
		self.httpAddressLabel.alpha = 0.5;
		[[self.httpAddressLabel.gestureRecognizers lastObject] setEnabled: NO];
	}
}
- (void) updateLabels
{
//	NSString *hostName = [[NSProcessInfo processInfo] hostName];
	NSString *hostName = [[UIDevice currentDevice] IPAddressForInterface: @"en0"];
	
	if (self.showsProxyAutoConfig)
	{
		self.httpAddressLabel.text = [NSString stringWithFormat: @"http://%@:%d/%@", hostName, [SXHTTPServer servicePort], [SXHTTPProxyServer proxyAutoConfigPath]];
		self.socksAddressLabel.text = [NSString stringWithFormat: @"http://%@:%d/%@", hostName, [SXHTTPServer servicePort], [SXSOCKSProxyServer proxyAutoConfigPath]];
	}
	else
	{
		self.httpAddressLabel.text = [NSString stringWithFormat: @"%@:%d", hostName, [SXHTTPProxyServer servicePort]];
		self.socksAddressLabel.text = [NSString stringWithFormat: @"%@:%d", hostName, [SXSOCKSProxyServer servicePort]];
	}
	
	if (fdEventNum == 1)
		self.httpEventCountLabel.text = @"1 event";
	else
		self.httpEventCountLabel.text = [NSString stringWithFormat: @"%d events", fdEventNum];
}
- (void) updateSocksProxy
{
	if (self.socksSwitch.on)
	{
		[[SXSOCKSProxyServer sharedServer] start];
		
		self.socksAddressLabel.alpha = 1.0;
		[[self.socksAddressLabel.gestureRecognizers lastObject] setEnabled: YES];
	}
	else
	{
		[[SXSOCKSProxyServer sharedServer] stop];
		
		self.socksAddressLabel.alpha = 0.5;
		[[self.socksAddressLabel.gestureRecognizers lastObject] setEnabled: NO];
		
		self.socksConnectionCountLabel.text = @"0 connections";
		
		[self.socksProxyInfoTimer invalidate];
		self.socksProxyInfoTimer = nil;
	}
}
- (void) updateSocksProxyInfo
{
	SXSOCKSProxyServer *server = [SXSOCKSProxyServer sharedServer];
	
	if (server.connectionCount == 1)
		self.socksConnectionCountLabel.text = @"1 connection";
	else
		self.socksConnectionCountLabel.text = [NSString stringWithFormat: @"%d connections", server.connectionCount];
	
	if (server.IPAddressCount == 1)
		self.socksIPCountLabel.text = @"1 IP";
	else
		self.socksIPCountLabel.text = [NSString stringWithFormat: @"%d IPs", server.IPAddressCount];
	
	[self.socksProxyInfoTimer invalidate];
	self.socksProxyInfoTimer = nil;
}
- (void) updateTransfer
{
	[self.updateTransferTimer invalidate];
	self.updateTransferTimer = nil;
	
	double uploadBandwidth;
	double downloadBandwidth;
	[[SXSOCKSProxyServer sharedServer] getBandwidthStatsForUpload: &uploadBandwidth download: &downloadBandwidth];
	
	UInt64 oldIn;
	UInt64 oldOut;
	[[SXSOCKSProxyServer sharedServer] getTotalBytesForUpload: &oldOut download: &oldIn];
	
	self.socksUploadLabel.text = [NSString stringWithFormat: @"%@/s up (%@)", [self.unitOfInformationFormatter stringFromNumber: @(uploadBandwidth) ofUnit: TTTByte], [self.unitOfInformationFormatter stringFromNumber: @(oldOut) ofUnit: TTTByte]];
	self.socksDownloadLabel.text = [NSString stringWithFormat: @"%@/s down (%@)", [self.unitOfInformationFormatter stringFromNumber: @(downloadBandwidth) ofUnit: TTTByte], [self.unitOfInformationFormatter stringFromNumber: @(oldIn) ofUnit: TTTByte]];
	
	if (self.applicationActive && self.windowVisible && self.viewVisible)
	{
		if (uploadBandwidth > 0 && downloadBandwidth > 0)
		{
			self.updateTransferTimer = [NSTimer scheduledTimerWithTimeInterval: 0.5 target: self selector: _cmd userInfo: nil repeats: YES];
		}
		else
		{
			self.updateTransferTimer = [NSTimer scheduledTimerWithTimeInterval: 2.0 target: self selector: _cmd userInfo: nil repeats: YES];
		}
	}
}

#pragma mark - Actions

- (IBAction) handleAddressLabelTapped: (UITapGestureRecognizer *) tapGesture
{
	self.showsProxyAutoConfig ^= YES;
	[[NSUserDefaults standardUserDefaults] setBool: self.showsProxyAutoConfig forKey: SXMainViewControllerShowsProxyAutoConfigKey];
	[self updateLabels];
}
- (IBAction) share: (id) sender
{
	if (self.activityPopoverController)
	{
		[self.activityPopoverController dismissPopoverAnimated: YES];
		self.activityPopoverController = nil;
		return;
	}
	
	NSString *string = [NSString stringWithFormat: @"HTTP: %@\nSOCKS: %@", self.httpAddressLabel.text, self.socksAddressLabel.text];
	UIActivityViewController *activityView = [[UIActivityViewController alloc] initWithActivityItems: @[ string ] applicationActivities: nil];
	if ([UIDevice isPhone])
	{
		[self presentViewController: activityView animated: YES completion: NULL];
	}
	else
	{
		UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController: activityView];
		popoverController.passthroughViews = nil;
		[popoverController presentPopoverFromBarButtonItem: sender permittedArrowDirections: UIPopoverArrowDirectionAny animated: YES];
		self.activityPopoverController = popoverController;
		
		activityView.completionHandler = ^(NSString *activityType, BOOL completed) {
			[popoverController dismissPopoverAnimated: YES];
		};
	}
}
- (IBAction) toggleHTTP: (UISwitch *) sender
{
	[[NSUserDefaults standardUserDefaults] setBool: sender.on forKey: SXHTTPProxyServerOnKey];
	[self updateHTTPProxy];
}
- (IBAction) toggleSOCKS: (UISwitch *) sender
{
	[[NSUserDefaults standardUserDefaults] setBool: sender.on forKey: SXSOCKSProxyServerOnKey];
	[self updateSocksProxy];
}

#pragma mark - Notification Observation

- (void) applicationDidBecomeActive: (NSNotification *) note
{
	if (!self.applicationActive)
	{
		self.applicationActive = YES;
		if (self.windowVisible && self.viewVisible && !self.updateTransferTimer)
		{
			[self updateTransfer];
		}
	}
}
- (void) applicationWillResignActive: (NSNotification *) note
{
	if (self.applicationActive)
	{
		self.applicationActive = NO;
		[self.updateTransferTimer invalidate];
		self.updateTransferTimer = nil;
	}
}
- (void) windowDidBecomeHidden: (NSNotification *) note
{
	if (self.windowVisible)
	{
		self.windowVisible = NO;
		[self.updateTransferTimer invalidate];
		self.updateTransferTimer = nil;
	}
}
- (void) windowDidBecomeVisible: (NSNotification *) note
{
	if (self.windowVisible)
	{
		self.windowVisible = YES;
		if (self.applicationActive && self.viewVisible && !self.updateTransferTimer)
		{
			[self updateTransferTimer];
		}
	}
}

#pragma mark - View Lifecycle

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void) viewDidAppear: (BOOL) animated
{
	[super viewDidAppear: animated];
	
	self.viewVisible = YES;
	if (self.applicationActive && self.windowVisible && !self.updateTransferTimer)
	{
		[self updateTransfer];
	}
}
- (void) viewDidDisappear: (BOOL) animated
{
	[super viewDidDisappear: animated];
	
	self.viewVisible = NO;
	
	[self.updateTransferTimer invalidate];
	self.updateTransferTimer = nil;
	
	[self.socksProxyInfoTimer invalidate];
	self.socksProxyInfoTimer = nil;
	
	[self.labelTimer invalidate];
	self.labelTimer = nil;
}
- (void) viewDidLoad
{
    [super viewDidLoad];
	
	// Do any additional setup after loading the view, typically from a nib.
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(windowDidBecomeVisible:) name: UIWindowDidBecomeVisibleNotification object: self.view.window];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(windowDidBecomeHidden:) name: UIWindowDidBecomeHiddenNotification object: self.view.window];
	
	self.httpSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey: SXHTTPProxyServerOnKey];
	self.socksSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey: SXSOCKSProxyServerOnKey];
}
- (void) viewWillAppear: (BOOL) animated
{
	[super viewWillAppear: animated];
	
	if (!self.labelTimer) self.labelTimer = [NSTimer scheduledTimerWithTimeInterval: 2.0 target: self selector: @selector(updateLabels) userInfo: nil repeats: YES];
	[self updateLabels];
}

@end
