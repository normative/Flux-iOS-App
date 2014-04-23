//
//  FluxImportContactCell.m
//  Flux
//
//  Created by Kei Turner on 2014-02-27.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxImportContactCell.h"
#import "UICKeyChainStore.h"
#import "UIActionSheet+Blocks.h"

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
    
    [self.invitingActivityIndicator setHidesWhenStopped:YES];
    [self.invitingActivityIndicator stopAnimating];
    //add a white stroke to the image
    //    self.profileImageView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.7].CGColor;
    //    self.profileImageView.layer.borderWidth = 1;
}

- (void)setContactObject:(FluxContactObject *)contactObject{
    _contactObject = contactObject;
    [self.inviteButton setHidden:NO];
    
    
    if (contactObject.userID) {
        [self setSelectionStyle:UITableViewCellSelectionStyleBlue];
        
        
        
        if (serviceType == TwitterService) {
            [self.titleLabel setText:[@"@" stringByAppendingString:contactObject.username]];
            [self.socialTypeImageView setImage:[UIImage imageNamed:@"import_twitter"]];
            [self.socialStatusLabel setText:[NSString stringWithFormat:@"@%@",contactObject.aliasName]];
        }
        else if (serviceType == FacebookService){
            [self.titleLabel setText:[@"@" stringByAppendingString:contactObject.username]];
            [self.socialTypeImageView setImage:[UIImage imageNamed:@"import_facebook"]];
            [self.socialStatusLabel setText:[NSString stringWithFormat:@"%@",contactObject.displayName]];
        }
        else{
            [self.titleLabel setText:contactObject.username];
            [self.socialTypeImageView setImage:[UIImage imageNamed:@"import_contact"]];
        }
        
        if (contactObject.amFollowerFlag > 0) {
            [self.inviteButton setHidden:YES];
        }
        
        
        
        //show friend / follower status. If we do this we lose reference to who that person is on the third party network. (just visually as this takes the space)
//        if (contactObject.friendState == 3) {
//            [self.socialStatusLabel setText:[NSString stringWithFormat:@"You and @%@ are friends",contactObject.username]];
//            [self layoutSubviews];
//        }
//        else if (contactObject.friendState == 2){
//            [self.socialStatusLabel setText:[NSString stringWithFormat:@"You've sent a friend request to @%@",contactObject.username]];
//            [self layoutSubviews];
//        }
//        else if (contactObject.friendState == 1){
//            [self.socialStatusLabel setText:[NSString stringWithFormat:@"@%@ has sent you a friend request",contactObject.username]];
//            [self layoutSubviews];
//        }
//        else if (contactObject.isFollower && contactObject.isFollowing){
//            [self.socialStatusLabel setText:[NSString stringWithFormat:@"You and @%@ follow each other",contactObject.username]];
//            [self layoutSubviews];
//        }
//        else if (contactObject.isFollower){
//            [self.socialStatusLabel setText:[NSString stringWithFormat:@"You're following @%@",contactObject.username]];
//            [self layoutSubviews];
//        }
//        else if (contactObject.isFollower){
//            [self.socialStatusLabel setText:[NSString stringWithFormat:@"is following you"]];
//            [self layoutSubviews];
//        }
//        else{
//            //nthing else
//        }

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
    
    if (!contactObject.inviteSent && !contactObject.inviteSending) {
        [self.titleLabel setAlpha:1.0];
        [self.profileImageView setAlpha:1.0];
        [self.invitingActivityIndicator stopAnimating];
        [self.inviteButton setAlpha:1.0];
        [self.inviteButton setUserInteractionEnabled:YES];
    }
    else if (!contactObject.inviteSent && contactObject.inviteSending){
        [self.titleLabel setAlpha:1.0];
        [self.profileImageView setAlpha:1.0];
        [self.invitingActivityIndicator startAnimating];
        [self.inviteButton setAlpha:0.0];
        [self.inviteButton setUserInteractionEnabled:NO];
    }
    else if (contactObject.inviteSent && !contactObject.inviteSending){
        [self.titleLabel setAlpha:0.5];
        [self.profileImageView setAlpha:0.5];
        [self.invitingActivityIndicator stopAnimating];
        [self.inviteButton setAlpha:0.5];
        [self.inviteButton setUserInteractionEnabled:NO];
    }
    //**should** never hit
    else{
        [self.titleLabel setAlpha:1.0];
        [self.profileImageView setAlpha:1.0];
        [self.invitingActivityIndicator stopAnimating];
        [self.inviteButton setAlpha:0.4];
        [self.inviteButton setUserInteractionEnabled:NO];
    }
}


- (IBAction)inviteButtonAction:(id)sender {
    [UIActionSheet showInView:self.superview
                    withTitle:nil
            cancelButtonTitle:@"Cancel"
       destructiveButtonTitle:nil
            otherButtonTitles:@[@"Send Invitation"]
                     tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                         if (buttonIndex != actionSheet.cancelButtonIndex) {
                             if ([delegate respondsToSelector:@selector(ImportContactCell:shouldInvite:)]) {
                                 [delegate ImportContactCell:self shouldInvite:self.contactObject];
                             }
                         }
                     }];
}

- (IBAction)contactButtonAction:(id)sender {
    [UIActionSheet showInView:self.superview
                    withTitle:nil
            cancelButtonTitle:@"Cancel"
       destructiveButtonTitle:nil
            otherButtonTitles:@[@"Send Follow Request"]
                     tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                         if (buttonIndex != actionSheet.cancelButtonIndex) {
                             if ([delegate respondsToSelector:@selector(ImportContactCell:shouldSendFollowRequestTo:)]) {
                                 [delegate ImportContactCell:self shouldSendFollowRequestTo:self.contactObject];
                             }
                         }
                     }];
}
@end
