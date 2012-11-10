//
//  SXFlipsideViewController.h
//  Soxy
//
//  Created by Alexsander Akers on 11/10/12.
//  Copyright (c) 2012 Pandamonia LLC. All rights reserved.
//

@protocol SXFlipsideViewControllerDelegate;

@interface SXFlipsideViewController : UIViewController

@property (nonatomic, weak) id <SXFlipsideViewControllerDelegate> delegate;

- (IBAction) done: (id) sender;

@end

@protocol SXFlipsideViewControllerDelegate

- (void) flipsideViewControllerDidFinish: (SXFlipsideViewController *) controller;

@end
