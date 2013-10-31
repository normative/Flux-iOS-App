//
//  FluxDrawerCheckboxFilterTableViewCell.h
//  Flux
//
//  Created by Kei Turner on 2013-08-07.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KTCheckboxButton.h"

@class FluxDrawerCheckboxFilterTableViewCell;
@protocol DrawerCheckboxTableViewCellDelegate <NSObject>
@optional
- (void)CheckboxCell:(FluxDrawerCheckboxFilterTableViewCell *)checkCell boxWasChecked:(BOOL)checked;
@end

@interface FluxDrawerCheckboxFilterTableViewCell : UITableViewCell <KTCheckboxButtonDelegate>{
    BOOL active;
    id __unsafe_unretained delegate;
}
@property (weak, nonatomic) IBOutlet UIImageView *descriptorIconImageView;
@property (weak, nonatomic) IBOutlet UILabel *descriptorLabel;
@property (weak, nonatomic) IBOutlet KTCheckboxButton *checkbox;
@property (weak, nonatomic) NSString*dbTitle;

@property (unsafe_unretained) id <DrawerCheckboxTableViewCellDelegate> delegate;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;

-(void)setIsActive:(BOOL)bActive;

@end
