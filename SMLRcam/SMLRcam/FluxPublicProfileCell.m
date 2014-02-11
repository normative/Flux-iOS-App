//
//  FluxFluxPublicProfileCell.m
//  Flux
//
//  Created by Kei Turner on 2/10/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxPublicProfileCell.h"


@implementation FluxPublicProfileCell

@synthesize delegate;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)initCell{
    [self.nameLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.nameLabel.font.pointSize]];
    [self.bioLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.bioLabel.font.pointSize]];
    [self.photosTitleLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.photosTitleLabel.font.pointSize]];
    [self.photosCountLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.photosCountLabel.font.pointSize]];
    [self.followersTitleLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.followersTitleLabel.font.pointSize]];
    [self.followersCountLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.followersCountLabel.font.pointSize]];
    [self.socialStatusLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.socialStatusLabel.font.pointSize]];
    [self.followingTitleLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.followingTitleLabel.font.pointSize]];
    [self.socialStatusLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.socialStatusLabel.font.pointSize]];
    
    [self.friendButton.titleLabel setFont:[UIFont fontWithName:@"Akkurat-Bold" size:self.friendButton.titleLabel.font.pointSize]];
    [self.followerButton.titleLabel setFont:[UIFont fontWithName:@"Akkurat-Bold" size:self.followerButton.titleLabel.font.pointSize]];
    
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [UIColor colorWithRed:43/255.0 green:52/255.0 blue:58/255.0 alpha:0.7];
    [self setSelectedBackgroundView:bgColorView];
    
    self.profielImageButton.layer.cornerRadius = self.profielImageButton.frame.size.height/2;
    self.profielImageButton.clipsToBounds = YES;
    //add a white stroke to the image
    self.profielImageButton.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.7].CGColor;
    self.profielImageButton.layer.borderWidth = 1;
    
    contentContainerView.layer.cornerRadius = 6;
    contentContainerView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.9].CGColor;
    contentContainerView.layer.borderWidth = 1;
}

- (IBAction)profilePictureButtonAction:(id)sender {
    if ([delegate respondsToSelector:@selector(PublicProfileCellButtonWasTapped:)]) {
        [delegate PublicProfileCellButtonWasTapped:self];
    }
}

- (IBAction)friendButtonAction:(id)sender {
    switch (self.userObject.friendState) {
        case 0:
            if ([delegate respondsToSelector:@selector(PublicProfileCell:shouldSendFriendRequestToUser:)]) {
                [delegate PublicProfileCell:self shouldSendFriendRequestToUser:self.userObject];
            }
            break;
        case 1:
            return;
            break;
        case 2:
            if ([delegate respondsToSelector:@selector(PublicProfileCell:shouldAcceptFriendRequestToUser:)]) {
                [delegate PublicProfileCell:self shouldAcceptFriendRequestToUser:self.userObject];
            }
            break;
        case 3:
            if ([delegate respondsToSelector:@selector(PublicProfileCell:shouldUnfriendUser:)]) {
                [delegate PublicProfileCell:self shouldUnfriendUser:self.userObject];
            }
            break;
            
        default:
            break;
    }
}

- (IBAction)followButtonAction:(id)sender {
    if (self.userObject.isFollowing) {
        if ([delegate respondsToSelector:@selector(PublicProfileCell:shouldUnfollowUser:)]) {
            [delegate PublicProfileCell:self shouldUnfollowUser:self.userObject];
        }
    }
    else{
        if ([delegate respondsToSelector:@selector(PublicProfileCell:shouldFollowUser:)]) {
            [delegate PublicProfileCell:self shouldFollowUser:self.userObject];
        }
    }
    
    
}
- (void)setUserObject:(FluxUserObject *)userObject{
    _userObject = userObject;
    
    [self.nameLabel setText:[NSString stringWithFormat:@"@%@",userObject.username]];
    if (userObject.bio) {
        [self.bioLabel setText:[NSString stringWithFormat:@"%@",userObject.bio]];
    }
    else{
        [self.bioLabel setText:@""];
    }
    if (userObject.isFollowing) {
        [self.followerStatusLabel setText:@"Following"];
        [self.followerButton setImage:[UIImage imageNamed:@"following"] forState:UIControlStateNormal];
    }
    switch (userObject.friendState) {
        case 0:
            [self.friendStatusLabel setText:@"Not Friends"];
            [self.friendButton setImage:[UIImage imageNamed:@"addFriend"] forState:UIControlStateNormal];
            break;
        case 1:
            [self.friendStatusLabel setText:@"Friend request sent"];
            [self.friendButton setImage:[UIImage imageNamed:@"friendRequestSent"] forState:UIControlStateNormal];
            self.friendButton.userInteractionEnabled = NO;
            break;
        case 2:
            [self.friendStatusLabel setText:@"Add Friend"];
            [self.friendButton setImage:[UIImage imageNamed:@"addFriend"] forState:UIControlStateNormal];
            break;
        case 3:
            [self.friendStatusLabel setText:@"Friends"];
            [self.friendButton setImage:[UIImage imageNamed:@"friends"] forState:UIControlStateNormal];
            break;
            
        default:
            break;
    }
    
    
    [self.photosCountLabel setText:[NSString stringWithFormat:@"%i",userObject.imageCount]];
    [self.followersCountLabel setText:[NSString stringWithFormat:@"%i",userObject.followerCount]];
    [self.followingCountLabel setText:[NSString stringWithFormat:@"%i",userObject.followingCount]];
    
    if (userObject.friendState == 3) {
        [self.socialStatusLabel setText:[NSString stringWithFormat:@"You and @%@ are friends",userObject.username]];
    }
    else if (userObject.isFollower) {
        [self.socialStatusLabel setText:[NSString stringWithFormat:@"@%@ is following you",userObject.username]];
    }
    else if (userObject.isFollowing) {
        [self.socialStatusLabel setText:[NSString stringWithFormat:@"You're following @%@",userObject.username]];
    }
    else{
        [self.socialStatusLabel setText:@""];
    }
}

@end
