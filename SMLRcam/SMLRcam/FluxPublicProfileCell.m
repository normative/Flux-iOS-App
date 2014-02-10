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
}

- (IBAction)profilePictureButtonAction:(id)sender {
    if ([delegate respondsToSelector:@selector(PublicProfileCellButtonWasTapped:)]) {
        [delegate PublicProfileCellButtonWasTapped:self];
    }
}

- (IBAction)friendButtonAction:(id)sender {
    if ([delegate respondsToSelector:@selector(PublicProfileCellFriendButtonWasTapped:)]) {
        [delegate PublicProfileCellFriendButtonWasTapped:self];
    }
}

- (IBAction)followButtonAction:(id)sender {
    if ([delegate respondsToSelector:@selector(PublicProfileCellFollowerButtonWasTapped:)]) {
        [delegate PublicProfileCellFollowerButtonWasTapped:self];
    }
}

@end
