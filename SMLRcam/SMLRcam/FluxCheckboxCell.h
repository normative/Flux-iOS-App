//
//  FluxDrawerCheckboxFilterTableViewCell.h
//  Flux
//
//  Created by Kei Turner on 2013-08-07.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KTCheckboxButton.h"

@class FluxCheckboxCell;
@protocol CheckboxTableViewCellDelegate <NSObject>
@optional
- (void)checkboxCell:(FluxCheckboxCell *)checkCell boxWasChecked:(BOOL)checked;
@end

@interface FluxCheckboxCell : UITableViewCell <KTCheckboxButtonDelegate>{
    BOOL active;
    id __unsafe_unretained delegate;
}
@property (strong, nonatomic) IBOutlet UILabel *countLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptorLabel;
@property (weak, nonatomic) IBOutlet KTCheckboxButton *checkbox;


@property (unsafe_unretained) id <CheckboxTableViewCellDelegate> delegate;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;
-(void)setIsActive:(BOOL)bActive;
-(BOOL)isChecked;

@end
