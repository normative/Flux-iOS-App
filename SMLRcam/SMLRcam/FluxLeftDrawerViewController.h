//
//  FluxLeftDrawerViewController.h
//  Flux
//
//  Created by Kei Turner on 2013-08-01.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FluxDrawerSwitchTableViewCell.h"
#import "FluxDrawerSegmentedTableViewCell.h"
#import "FluxDrawerButtonTableViewCell.h"
#import "FluxNetworkServices.h"

@interface FluxLeftDrawerViewController : UITableViewController<DrawerSwitchTableViewCellDelegate, SegmentedCellDelegate, DrawerButtonTableViewCellDelegate>{
    NSArray *leftDrawerTableViewArray;
    FluxNetworkServices *networkServices;
}

- (void)SettingActionForString:(NSString*)string andSetting:(BOOL)setting;
- (NSNumber*)GetSettingForString:(NSString*)string;

@end
