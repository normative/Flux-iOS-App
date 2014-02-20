//
//  FluxFluxPublicProfileCell.m
//  Flux
//
//  Created by Kei Turner on 2/10/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxPublicProfileCell.h"
#import "UIActionSheet+Blocks.h"


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
    [self.firstStatusLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.firstStatusLabel.font.pointSize]];
    [self.followingTitleLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.followingTitleLabel.font.pointSize]];
    [self.secondStatusLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.secondStatusLabel.font.pointSize]];
    
    [self.friendButton.titleLabel setFont:[UIFont fontWithName:@"Akkurat-Bold" size:self.friendButton.titleLabel.font.pointSize]];
    [self.followerButton.titleLabel setFont:[UIFont fontWithName:@"Akkurat-Bold" size:self.followerButton.titleLabel.font.pointSize]];
    
    [self.followerButton setImage:[UIImage imageNamed:@"follow"] forState:UIControlStateNormal];
    [self.followerButton setImage:[UIImage imageNamed:@"following"] forState:UIControlStateSelected];
    
    [self.friendButton setImage:[UIImage imageNamed:@"friend"] forState:UIControlStateNormal];
    [self.friendButton setImage:[UIImage imageNamed:@"friends"] forState:UIControlStateSelected];
    
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [UIColor colorWithRed:43/255.0 green:52/255.0 blue:58/255.0 alpha:0.7];
    [self setSelectedBackgroundView:bgColorView];
    
    self.profielImageButton.layer.cornerRadius = self.profielImageButton.frame.size.height/2;
    self.profielImageButton.clipsToBounds = YES;
    //add a white stroke to the image
//    self.profielImageButton.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.7].CGColor;
//    self.profielImageButton.layer.borderWidth = 1;
    
    contentContainerView.layer.cornerRadius = 6;
    contentContainerView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.8].CGColor;
    contentContainerView.layer.borderWidth = 0.5;
    
    [self.firstStatusLabel setText:@""];
    [self.secondStatusLabel setText:@""];
}

- (IBAction)profilePictureButtonAction:(id)sender {
    if ([delegate respondsToSelector:@selector(PublicProfileCellButtonWasTapped:)]) {
        [delegate PublicProfileCellButtonWasTapped:self];
    }
}

- (IBAction)friendButtonAction:(id)sender {
    switch (self.userObject.friendState) {
        case 0:
        {
            [UIActionSheet showInView:self.superview
                            withTitle:nil
                    cancelButtonTitle:@"Cancel"
               destructiveButtonTitle:nil
                    otherButtonTitles:@[@"Send Friend Request"]
                             tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                                 if (buttonIndex != actionSheet.cancelButtonIndex) {
                                     if ([delegate respondsToSelector:@selector(PublicProfileCell:shouldSendFriendRequestToUser:)]) {
                                         [self.friendButton setUserInteractionEnabled:NO];
                                         [delegate PublicProfileCell:self shouldSendFriendRequestToUser:self.userObject];
                                         [self.friendButton setUserInteractionEnabled:YES];
                                     }
                                 }
                             }];
        }
            break;
        case 2:{
            [UIActionSheet showInView:self.superview
                            withTitle:nil
                    cancelButtonTitle:@"Cancel"
               destructiveButtonTitle:@"Cancel Friend Request"
                    otherButtonTitles:nil
                             tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                                 if (buttonIndex != actionSheet.cancelButtonIndex) {
                                     if ([delegate respondsToSelector:@selector(PublicProfileCell:shouldUnfriendUser:)]) {
                                         [self.friendButton setUserInteractionEnabled:NO];
                                         [delegate PublicProfileCell:self shouldUnfriendUser:self.userObject];
                                         [self.friendButton setUserInteractionEnabled:YES];
                                     }
                                 }
                             }];
        }
            return;
            break;
        case 1:{
            [UIActionSheet showInView:self.superview
                            withTitle:nil
                    cancelButtonTitle:@"Cancel"
               destructiveButtonTitle:nil
                    otherButtonTitles:@[@"Accept Friend Request"]
                             tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                                 if (buttonIndex != actionSheet.cancelButtonIndex) {
                                     if ([delegate respondsToSelector:@selector(PublicProfileCell:shouldAcceptFriendRequestToUser:)]) {
                                         [self.friendButton setUserInteractionEnabled:NO];
                                         [delegate PublicProfileCell:self shouldAcceptFriendRequestToUser:self.userObject];
                                         [self.friendButton setUserInteractionEnabled:YES];
                                     }
                                 }
                             }];
            
        }
            break;
        case 3:{
            [UIActionSheet showInView:self.superview
                            withTitle:nil
                    cancelButtonTitle:@"Cancel"
               destructiveButtonTitle:@"Unfriend"
                    otherButtonTitles:nil
                             tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                                 if (buttonIndex != actionSheet.cancelButtonIndex) {
                                     if ([delegate respondsToSelector:@selector(PublicProfileCell:shouldUnfriendUser:)]) {
                                         [self.friendButton setUserInteractionEnabled:NO];
                                         [delegate PublicProfileCell:self shouldUnfriendUser:self.userObject];
                                         [self.friendButton setUserInteractionEnabled:YES];
                                     }
                                 }
                             }];
        }
            break;
        default:
            break;
    }
}

- (IBAction)followButtonAction:(id)sender {
    if (self.userObject.isFollowing) {
        [UIActionSheet showInView:self.superview
                        withTitle:nil
                cancelButtonTitle:@"Cancel"
           destructiveButtonTitle:@"Unfollow"
                otherButtonTitles:nil
                         tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                             if (buttonIndex != actionSheet.cancelButtonIndex) {
                                 if ([delegate respondsToSelector:@selector(PublicProfileCell:shouldUnfollowUser:)]) {
                                     [self.followerButton setUserInteractionEnabled:NO];
                                     [delegate PublicProfileCell:self shouldUnfollowUser:self.userObject];
                                     [self.followerButton setUserInteractionEnabled:YES];
                                 }
                             }
                         }];
    }
    else{
        if ([delegate respondsToSelector:@selector(PublicProfileCell:shouldFollowUser:)]) {
            [self.followerButton setUserInteractionEnabled:NO];
            [delegate PublicProfileCell:self shouldFollowUser:self.userObject];
            [self.followerButton setUserInteractionEnabled:YES];
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
        [self.followerButton setSelected:YES];
    }
    else{
        [self.followerButton setSelected:NO];
    }
    
    [self.friendButtonEllipsis setHidden:YES];
    switch (userObject.friendState) {
        case 0:
            [self.friendButton setSelected:NO];
            break;
        case 2:
            [self.friendButton setSelected:NO];
            [self.friendButtonEllipsis setHidden:NO];
            break;
        case 1:
            [self.friendButton setSelected:NO];
            break;
        case 3:
            [self.friendButton setSelected:YES];
            break;
            
        default:
            break;
    }
    
    
    [self.photosCountLabel setText:[NSString stringWithFormat:@"%i",userObject.imageCount]];
    [self.followersCountLabel setText:[NSString stringWithFormat:@"%i",userObject.followerCount]];
    [self.followingCountLabel setText:[NSString stringWithFormat:@"%i",userObject.followingCount]];
    
    if (userObject.friendState == 3) {
        [self setStatusText:[NSString stringWithFormat:@"You and @%@ are friends",userObject.username] forSocialType:2];
    }
    else if (userObject.isFollower) {
        [self setStatusText:[NSString stringWithFormat:@"@%@ is following you",userObject.username] forSocialType:2];
    }
    else if (userObject.isFollowing) {
        [self setStatusText:[NSString stringWithFormat:@"You're following @%@",userObject.username] forSocialType:2];
    }
    else{
    }
}

- (void)setStatusText:(NSString*) text forSocialType:(int)type{
    if (type == 1) {
        if (self.secondStatusLabel.text.length > 0) {
            [self.firstStatusLabel setText:self.secondStatusLabel.text];
            [self.secondStatusLabel setText:text];
        }
    }
    else{
        if (self.secondStatusLabel.text.length > 0) {
            [self.firstStatusLabel setText:text];
        }
        else{
            [self.secondStatusLabel setText:text];
        }
    }
}

@end
