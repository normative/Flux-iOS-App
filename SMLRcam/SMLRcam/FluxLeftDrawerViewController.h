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

#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface FluxLeftDrawerViewController : UITableViewController<DrawerSwitchTableViewCellDelegate, SegmentedCellDelegate, DrawerButtonTableViewCellDelegate, MFMailComposeViewControllerDelegate>{
    NSArray *leftDrawerTableViewArray;
}

- (IBAction)submitFeedbackAction:(id)sender;
- (void)SettingActionForString:(NSString*)string andSetting:(BOOL)setting;
- (NSNumber*)GetSettingForString:(NSString*)string;

@end
