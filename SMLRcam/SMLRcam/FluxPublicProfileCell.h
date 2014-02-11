//
//  FluxFluxPublicProfileCell.h
//  Flux
//
//  Created by Kei Turner on 2/10/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FluxPublicProfileCell;
@protocol FluxPublicProfileCellDelegate <NSObject>
@optional
- (void)PublicProfileCellButtonWasTapped:(FluxPublicProfileCell *)publicProfileCell;
- (void)PublicProfileCellFriendButtonWasTapped:(FluxPublicProfileCell *)publicProfileCell;
- (void)PublicProfileCellFollowerButtonWasTapped:(FluxPublicProfileCell *)publicProfileCell;
@end

@interface FluxPublicProfileCell : UITableViewCell{
    
    id __unsafe_unretained delegate;
}

@property (unsafe_unretained) id <FluxPublicProfileCellDelegate> delegate;


@property (strong, nonatomic) IBOutlet UIButton *profielImageButton;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) IBOutlet UILabel *bioLabel;
@property (strong, nonatomic) IBOutlet UILabel *photosTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *photosCountLabel;
@property (strong, nonatomic) IBOutlet UILabel *followersTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *followersCountLabel;
@property (strong, nonatomic) IBOutlet UILabel *followingTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *followingCountLabel;
@property (strong, nonatomic) IBOutlet UILabel *socialStatusLabel;
@property (strong, nonatomic) IBOutlet UIButton *friendButton;
@property (strong, nonatomic) IBOutlet UIButton *followerButton;

- (void)initCell;
- (IBAction)profilePictureButtonAction:(id)sender;
- (IBAction)friendButtonAction:(id)sender;
- (IBAction)followButtonAction:(id)sender;

@end
