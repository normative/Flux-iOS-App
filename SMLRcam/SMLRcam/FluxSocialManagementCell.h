//
//  FluxSocialManagementCell.h
//  Flux
//
//  Created by Kei Turner on 1/9/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FluxSocialManagementCell;
@protocol FluxSocialManagementCellDelegate <NSObject>
@optional
- (void)SocialManagementCellButtonWasTapped:(FluxSocialManagementCell *)socialManagementCell;
@end


@interface FluxSocialManagementCell : UITableViewCell{
    
    id __unsafe_unretained delegate;
}

@property (unsafe_unretained) id <FluxSocialManagementCellDelegate> delegate;


@property (nonatomic)BOOL isActivated;

@property (nonatomic, assign)IBOutlet UIImageView*socialIconImageView;
@property (nonatomic, assign)IBOutlet UILabel*socialPartnerLabel;
@property (nonatomic, assign)IBOutlet UILabel*socialDescriptionLabel;
@property (strong, nonatomic) IBOutlet UIButton *cellButton;
- (IBAction)cellButtonAction:(id)sender;

-(void)initCell;

@end
