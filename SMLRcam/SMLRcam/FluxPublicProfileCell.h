//
//  FluxFluxPublicProfileCell.h
//  Flux
//
//  Created by Kei Turner on 2/10/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FluxUserObject.h"

@class FluxPublicProfileCell;
@protocol FluxPublicProfileCellDelegate <NSObject>
@optional
- (void)PublicProfileCellButtonWasTapped:(FluxPublicProfileCell *)publicProfileCell;
- (void)PublicProfileCell:(FluxPublicProfileCell *)publicProfileCell shouldSendFriendRequestToUser:(FluxUserObject*)userObject;
- (void)PublicProfileCell:(FluxPublicProfileCell *)publicProfileCell shouldAcceptFriendRequestToUser:(FluxUserObject*)userObject;
- (void)PublicProfileCell:(FluxPublicProfileCell *)publicProfileCell shouldUnfriendUser:(FluxUserObject*)userObject;
- (void)PublicProfileCell:(FluxPublicProfileCell *)publicProfileCell shouldFollowUser:(FluxUserObject*)userObject;
- (void)PublicProfileCell:(FluxPublicProfileCell *)publicProfileCell shouldUnfollowUser:(FluxUserObject*)userObject;
@end

@interface FluxPublicProfileCell : UITableViewCell{
    
    id __unsafe_unretained delegate;
    IBOutlet UIView *contentContainerView;
    IBOutlet UIView *socialStatusContainerView;
}

@property (unsafe_unretained) id <FluxPublicProfileCellDelegate> delegate;
@property (nonatomic, strong) FluxUserObject*userObject;

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
@property (strong, nonatomic) IBOutlet UILabel *friendStatusLabel;
@property (strong, nonatomic) IBOutlet UIButton *followerButton;
@property (strong, nonatomic) IBOutlet UILabel *followerStatusLabel;

- (void)initCell;
- (IBAction)profilePictureButtonAction:(id)sender;
- (IBAction)friendButtonAction:(id)sender;
- (IBAction)followButtonAction:(id)sender;

@end
