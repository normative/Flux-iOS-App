//
//  FluxImportContactCell.m
//  Flux
//
//  Created by Kei Turner on 2014-02-27.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxImportContactCell.h"
#import "UICKeyChainStore.h"

@implementation FluxImportContactCell

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


-(void)initCellWithType:(NSString*)type{
    serviceType = type;
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

- (void)setContactObject:(FluxContactObject *)contactObject{
    _contactObject = contactObject;

    if (contactObject.userID) {
        [self setSelectionStyle:UITableViewCellSelectionStyleBlue];
        
        [self.socialStatusLabel setText:[NSString stringWithFormat:@"%@",contactObject.displayName]];
        
        
        if (contactObject.friendState == 3) {
            [self.socialStatusLabel setText:[NSString stringWithFormat:@"You and @%@ are friends",contactObject.username]];
            [self layoutSubviews];
        }
        else if (contactObject.friendState == 2){
            [self.socialStatusLabel setText:[NSString stringWithFormat:@"You've sent a friend request to @%@",contactObject.username]];
            [self layoutSubviews];
        }
        else if (contactObject.friendState == 1){
            [self.socialStatusLabel setText:[NSString stringWithFormat:@"@%@ has sent you a friend request",contactObject.username]];
            [self layoutSubviews];
        }
        else if (contactObject.isFollower && contactObject.isFollowing){
            [self.socialStatusLabel setText:[NSString stringWithFormat:@"You and @%@ follow each other",contactObject.username]];
            [self layoutSubviews];
        }
        else if (contactObject.isFollower){
            [self.socialStatusLabel setText:[NSString stringWithFormat:@"You're following @%@",contactObject.username]];
            [self layoutSubviews];
        }
        else if (contactObject.isFollower){
            [self.socialStatusLabel setText:[NSString stringWithFormat:@"is following you"]];
            [self layoutSubviews];
        }
        else{
            //nthing else
        }
        

        if (serviceType == TwitterService) {
            [self.titleLabel setText:[@"@" stringByAppendingString:contactObject.username]];
            [self.socialTypeImageView setImage:[UIImage imageNamed:@"import_twitter"]];
        }
        else if (serviceType == FacebookService){
            [self.titleLabel setText:[@"@" stringByAppendingString:contactObject.username]];
            [self.socialTypeImageView setImage:[UIImage imageNamed:@"import_facebook"]];
        }
        else{
            [self.titleLabel setText:contactObject.username];
            [self.socialTypeImageView setImage:[UIImage imageNamed:@"import_contact"]];
        }
    }
    else{
        [self.socialStatusLabel setText:@""];
        [self setSelectionStyle:UITableViewCellSelectionStyleNone];
        [self.socialTypeImageView setImage:[UIImage imageNamed:@"nothing"]];
        
        if (serviceType == TwitterService) {
            [self.titleLabel setText:[NSString stringWithFormat:@"@%@",contactObject.aliasName]];
        }
        else if (serviceType == FacebookService){
            [self.titleLabel setText:[NSString stringWithFormat:@"%@",contactObject.displayName]];
        }
        else{
            [self.titleLabel setText:[NSString stringWithFormat:@"%@",contactObject.aliasName]];
        }
        
        
    }
    
    if (contactObject.inviteSent) {
        [self.inviteButton setAlpha:0.4];
        [self.inviteButton setUserInteractionEnabled:NO];
    }
    else{
        [self.inviteButton setAlpha:1.0];
        [self.inviteButton setUserInteractionEnabled:YES];
    }
}


- (IBAction)inviteButtonAction:(id)sender {
    if ([delegate respondsToSelector:@selector(ImportContactCell:shouldInvite:)]) {
        [delegate ImportContactCell:self shouldInvite:self.contactObject];
    }
}

- (IBAction)contactButtonAction:(id)sender {
    if ([delegate respondsToSelector:@selector(ImportContactCellFriendFollowButtonWasTapped:)]) {
        [delegate ImportContactCellFriendFollowButtonWasTapped:self];
    }
}
@end
