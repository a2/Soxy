//
//  SXFlipsideViewController.h
//  Soxy
//
//  Created by Alexsander Akers on 11/10/12.
//  Copyright (c) 2012 Pandamonia LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SXFlipsideViewController;

@protocol SXFlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(SXFlipsideViewController *)controller;
@end

@interface SXFlipsideViewController : UIViewController

@property (weak, nonatomic) id <SXFlipsideViewControllerDelegate> delegate;

- (IBAction)done:(id)sender;

@end
