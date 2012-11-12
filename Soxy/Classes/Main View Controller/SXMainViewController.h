//
//  SXMainViewController.h
//  Soxy
//
//  Created by Alexsander Akers on 11/10/12.
//  Copyright (c) 2012 Pandamonia LLC. All rights reserved.
//

@interface SXMainViewController : UIViewController

#pragma mark - Outlets

@property (nonatomic, weak) IBOutlet UILabel *httpAddressLabel;
@property (nonatomic, weak) IBOutlet UILabel *httpEventCountLabel;
@property (nonatomic, weak) IBOutlet UISwitch *httpSwitch;

@property (nonatomic, weak) IBOutlet UILabel *socksAddressLabel;
@property (nonatomic, weak) IBOutlet UILabel *socksConnectionCountLabel;
@property (nonatomic, weak) IBOutlet UILabel *socksDownloadLabel;
@property (nonatomic, weak) IBOutlet UILabel *socksIPCountLabel;
@property (nonatomic, weak) IBOutlet UILabel *socksUploadLabel;
@property (nonatomic, weak) IBOutlet UISwitch *socksSwitch;

#pragma mark - Actions

- (IBAction) handleAddressLabelTapped: (UITapGestureRecognizer *) tapGesture;
- (IBAction) share: (id) sender;
- (IBAction) toggleHTTP: (id) sender;
- (IBAction) toggleSOCKS: (id) sender;

@end
