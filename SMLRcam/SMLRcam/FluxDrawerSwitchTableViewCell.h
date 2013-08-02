//
//  FluxLeftDrawerCustomTableViewCell.h
//  Flux
//
//  Created by Kei Turner on 2013-08-01.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FluxDrawerSwitchTableViewCell;
@protocol DrawerSwitchTableViewCellDelegate <NSObject>
@optional
- (void)SwitchCell:(FluxDrawerSwitchTableViewCell *)switchCell switchWasTapped:(UISwitch *)theSwitch;
@end

@interface FluxDrawerSwitchTableViewCell : UITableViewCell{
    
    id __unsafe_unretained delegate;
}

@property (unsafe_unretained) id <DrawerSwitchTableViewCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet UISwitch *theSwitch;
@property (weak, nonatomic) IBOutlet UILabel *theLabel;

- (IBAction)SwtichDidChange:(id)sender;
@end
