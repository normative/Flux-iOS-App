//
//  FluxFriendFollowerCell.m
//  Flux
//
//  Created by Kei Turner on 1/17/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxFollowerCell.h"


@implementation FluxFollowerCell

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

- (void)initCell{
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [UIColor colorWithRed:43/255.0 green:52/255.0 blue:58/255.0 alpha:0.7];
    [self setSelectedBackgroundView:bgColorView];
    
    self.titleLabel.font = [UIFont fontWithName:@"Akkurat" size:self.titleLabel.font.pointSize];
    self.socialStatusLabel.font = [UIFont fontWithName:@"Akkurat" size:self.socialStatusLabel.font.pointSize];
    [self.socialStatusLabel setTextColor:[UIColor colorWithWhite:1.0 alpha:0.8]];
    
    self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.height/2;
    self.profileImageView.clipsToBounds = YES;
    //add a white stroke to the image
//    self.profileImageView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.7].CGColor;
//    self.profileImageView.layer.borderWidth = 1;
}

- (void)setUserObject:(FluxUserObject *)userObject{
    _userObject = userObject;
    
    [self.titleLabel setText:[NSString stringWithFormat:@"@%@",userObject.username]];
    if (userObject.bio) {
        [self.bioLabel setText:[NSString stringWithFormat:@"%@",userObject.bio]];
    }
    else{
        [self.bioLabel setText:@""];
    }
    
    [self.socialStatusLabel setText:@""];
    
    if (userObject.isFollowingFlag == 2 && userObject.amFollowerFlag == 2) {
        [self.socialStatusLabel setText:[NSString stringWithFormat:@"You and @%@ follow each other",_userObject.username]];
        [self layoutSubviews];
    }
    else if (userObject.amFollowerFlag == 1){
        [self.socialStatusLabel setText:[NSString stringWithFormat:@"You've sent a follow request to @%@",_userObject.username]];
        [self layoutSubviews];
    }
    else if (userObject.isFollowingFlag == 1){
        [self.socialStatusLabel setText:[NSString stringWithFormat:@"@%@ has sent you a follow request",_userObject.username]];
        [self layoutSubviews];
    }
    else if (userObject.amFollowerFlag == 2){
        [self.socialStatusLabel setText:[NSString stringWithFormat:@"You're following @%@",_userObject.username]];
        [self layoutSubviews];
    }
    else if (userObject.isFollowingFlag == 2){
        [self.socialStatusLabel setText:[NSString stringWithFormat:@"@%@ is following you", _userObject.username]];
        [self layoutSubviews];
    }
    else{
        //nthing else
    }
}

- (IBAction)acceptFriendButtonAction:(id)sender {
    if ([delegate respondsToSelector:@selector(FriendFollowerCellShouldAcceptFollowingRequest:)]) {
        [delegate FriendFollowerCellShouldAcceptFollowingRequest:self];
    }
}


- (IBAction)ignoreFriendButtonAction:(id)sender {
    if ([delegate respondsToSelector:@selector(FriendFollowerCellShouldIgnoreFollowingRequest:)]) {
        [delegate FriendFollowerCellShouldIgnoreFollowingRequest:self];
    }
}

- (IBAction)friendFollowButtonAction:(id)sender {
    if ([delegate respondsToSelector:@selector(FriendFollowerCellButtonWasTapped:)]) {
        [delegate FriendFollowerCellButtonWasTapped:self];
    }
}

@end
