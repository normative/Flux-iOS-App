//
//  FluxLeftDrawerSettingsViewController.h
//  Flux
//
//  Created by Jacky So on 25/10/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FluxDataManager.h"

@interface FluxSettingsViewController : UITableViewController{
    int initialMask;
}

@property (weak, nonatomic) IBOutlet UISwitch *saveLocallySwitch;
@property (weak, nonatomic) IBOutlet UIButton *areaResetBtn;
@property (weak, nonatomic) IBOutlet UISegmentedControl *connectServerSegmentedControl;

@property (strong, nonatomic) IBOutlet UISlider *maskSlider;
@property (strong, nonatomic) IBOutlet UILabel *maskLabel;
@property (nonatomic, strong) FluxDataManager *fluxDataManager;

- (IBAction)changeSaveLocallySwitch:(id)sender;
- (IBAction)onAreaResetBtn:(id)sender;
- (IBAction)changeConnectServerSegment:(id)sender;
- (IBAction)maskSliderChanged:(id)sender;
@end
