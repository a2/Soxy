//
//  SXFlipsideViewController.m
//  Soxy
//
//  Created by Alexsander Akers on 11/10/12.
//  Copyright (c) 2012 Pandamonia LLC. All rights reserved.
//

#import "SXFlipsideViewController.h"

@interface SXFlipsideViewController ()

@end

@implementation SXFlipsideViewController

#pragma mark - Actions

- (IBAction) done: (id) sender
{
    [self.delegate flipsideViewControllerDidFinish:self];
}

#pragma mark - View Lifecycle

- (void) awakeFromNib
{
	self.contentSizeForViewInPopover = CGSizeMake(320.0, 480.0);
    [super awakeFromNib];
}
- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void) viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

@end
