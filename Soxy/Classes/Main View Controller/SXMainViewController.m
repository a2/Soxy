//
//  SXMainViewController.m
//  Soxy
//
//  Created by Alexsander Akers on 11/10/12.
//  Copyright (c) 2012 Pandamonia LLC. All rights reserved.
//

#import "SXMainViewController.h"

@interface SXMainViewController () <SXFlipsideViewControllerDelegate, UIPopoverControllerDelegate>

@property (strong, nonatomic) UIPopoverController *flipsidePopoverController;

@end

@implementation SXMainViewController

- (IBAction) togglePopover: (id) sender
{
    if (self.flipsidePopoverController)
	{
        [self.flipsidePopoverController dismissPopoverAnimated: YES];
        self.flipsidePopoverController = nil;
    }
	else
	{
        [self performSegueWithIdentifier: @"DisplayFlipside" sender:sender];
    }
}

#pragma mark - Flipside View Controller Delegate

- (void) flipsideViewControllerDidFinish: (SXFlipsideViewController *) controller
{
	if ([UIDevice isPhone])
	{
        [self dismissViewControllerAnimated: YES completion: NULL];
	}
    else
	{
        [self.flipsidePopoverController dismissPopoverAnimated: YES];
        self.flipsidePopoverController = nil;
    }
}

#pragma mark - Popover Controller Delegate

- (void) popoverControllerDidDismissPopover: (UIPopoverController *) popoverController
{
    self.flipsidePopoverController = nil;
}

#pragma mark - View Lifecycle

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void) prepareForSegue: (UIStoryboardSegue *) segue sender: (id) sender
{
    if ([segue.identifier isEqualToString: @"DisplayFlipside"])
	{
		SXFlipsideViewController *flipsideView = A2_STATIC_CAST(SXFlipsideViewController, segue.destinationViewController);
		flipsideView.delegate = self;

        if ([UIDevice isPad])
		{
            UIPopoverController *popoverController = A2_STATIC_CAST(UIStoryboardPopoverSegue, segue).popoverController;
            self.flipsidePopoverController = popoverController;
            popoverController.delegate = self;
        }
    }
}
- (void) viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

@end
