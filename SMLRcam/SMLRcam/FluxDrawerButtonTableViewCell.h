//
//  FluxDrawerButtonTableViewCell.h
//  Flux
//
//  Created by Denis Delorme on 9/4/13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FluxDrawerButtonTableViewCell;
@protocol DrawerButtonTableViewCellDelegate <NSObject>
@optional
- (void)ButtonCell:(FluxDrawerButtonTableViewCell *)buttonCell buttonWasTapped:(UIButton *)theButton;
@end

@interface FluxDrawerButtonTableViewCell : UITableViewCell{
    
    id __unsafe_unretained delegate;
}

@property (unsafe_unretained) id <DrawerButtonTableViewCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet UILabel *theLabel;
@property (weak, nonatomic) IBOutlet UIButton *theButton;
- (IBAction)onButtonPress:(id)sender;
@end



/*
@protocol DrawerSwitchTableViewCellDelegate <NSObject>
@optional
- (void)SwitchCell:(FluxDrawerSwitchTableViewCell *)switchCell switchWasTapped:(UISwitch *)theSwitch;
@end

@interface FluxDrawerSwitchTableViewCell : UITableViewCell{
    
    id __unsafe_unretained delegate;
}

@property (unsafe_unretained) id <DrawerSwitchTableViewCellDelegate> delegate;

*/