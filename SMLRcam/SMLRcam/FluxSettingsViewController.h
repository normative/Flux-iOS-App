//
//  FluxLeftDrawerSettingsViewController.h
//  Flux
//
//  Created by Jacky So on 25/10/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FluxDataManager.h"
#import "FluxSocialManager.h"
#import "FluxSocialManagementCell.h"

#import <Accounts/Accounts.h>
#import <Twitter/Twitter.h>
#import "OAuth+Additions.h"
#import "TWAPIManager.h"
#import "TWSignedRequest.h"


@interface FluxSettingsViewController : UITableViewController<UIAlertViewDelegate, FluxSocialManagerDelegate, FluxSocialManagementCellDelegate>{
    int initialMask;
    IBOutlet UIView *fakeSeparator;
}
@property (strong, nonatomic) IBOutlet UIButton *logoutButton;

@property (weak, nonatomic) IBOutlet UISwitch *saveLocallySwitch;
@property (weak, nonatomic) IBOutlet UIButton *areaResetBtn;
@property (weak, nonatomic) IBOutlet UISegmentedControl *connectServerSegmentedControl;

@property (strong, nonatomic) IBOutlet UISlider *maskSlider;
@property (strong, nonatomic) IBOutlet UILabel *maskLabel;
@property (nonatomic, strong) FluxDataManager *fluxDataManager;

@property (nonatomic, strong) ACAccountStore *accountStore;
@property (nonatomic, strong) TWAPIManager *apiManager;
@property (nonatomic, strong) NSArray *accounts;

//- (IBAction)changeSaveLocallySwitch:(id)sender;
- (IBAction)onAreaResetBtn:(id)sender;
//- (IBAction)changeConnectServerSegment:(id)sender;
//- (IBAction)maskSliderChanged:(id)sender;
- (IBAction)logoutButtonAction:(id)sender;
@end
