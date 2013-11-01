//
//  FluxSocialFilterCell.h
//  Flux
//
//  Created by Kei Turner on 11/1/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KTCheckboxButton.h"

@class FluxSocialFilterCell;
@protocol SocialFilterTableViewCellDelegate <NSObject>
@optional
- (void)SocialCell:(FluxSocialFilterCell *)checkCell boxWasChecked:(BOOL)checked;
@end

@interface FluxSocialFilterCell : UITableViewCell <KTCheckboxButtonDelegate>{
    BOOL active;
    id __unsafe_unretained delegate;
}
@property (weak, nonatomic) IBOutlet UIImageView *descriptorIconImageView;
@property (weak, nonatomic) IBOutlet UILabel *descriptorLabel;
@property (weak, nonatomic) NSString*dbTitle;
@property (weak, nonatomic) IBOutlet KTCheckboxButton *checkbox;


@property (unsafe_unretained) id <SocialFilterTableViewCellDelegate> delegate;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;
-(void)setIsActive:(BOOL)bActive;

@end