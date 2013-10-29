//
//  FluxLeftDrawerSettingsViewController.h
//  Flux
//
//  Created by Jacky So on 25/10/13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FluxDataManager.h"
#import "MMDrawerController.h"

@interface FluxLeftDrawerSettingsViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UISwitch *saveLocallySwitch;
@property (weak, nonatomic) IBOutlet UIButton *areaResetBtn;
@property (weak, nonatomic) IBOutlet UISegmentedControl *connectServerSegmentedControl;

@property (nonatomic, strong) FluxDataManager *fluxDataManager;
@property (nonatomic, strong) MMDrawerController *drawerController;

- (IBAction)changeSaveLocallySwitch:(id)sender;
- (IBAction)onAreaResetBtn:(id)sender;
- (IBAction)changeConnectServerSegment:(id)sender;
@end
