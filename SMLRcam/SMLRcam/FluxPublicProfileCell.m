//
//  FluxFluxPublicProfileCell.m
//  Flux
//
//  Created by Kei Turner on 2/10/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxPublicProfileCell.h"
#import "UIActionSheet+Blocks.h"
#import "UICKeyChainStore.h"

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
    [self.followingTitleLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.followingTitleLabel.font.pointSize]];
    [self.statusLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.statusLabel.font.pointSize]];

    
    [self.followButton.titleLabel setFont:[UIFont fontWithName:@"Akkurat-Bold" size:self.followButton.titleLabel.font.pointSize]];
    
    [self.followButton setImage:[UIImage imageNamed:@"friend"] forState:UIControlStateNormal];
    [self.followButton setImage:[UIImage imageNamed:@"friends"] forState:UIControlStateSelected];
    
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
    
}

- (IBAction)profilePictureButtonAction:(id)sender {
    if ([delegate respondsToSelector:@selector(PublicProfileCellButtonWasTapped:)]) {
        [delegate PublicProfileCellButtonWasTapped:self];
    }
}

- (IBAction)followButtonAction:(id)sender {
    switch (self.userObject.amFollowerFlag) {
        case 0:
        {
            [UIActionSheet showInView:self.superview
                            withTitle:nil
                    cancelButtonTitle:@"Cancel"
               destructiveButtonTitle:nil
                    otherButtonTitles:@[@"Send Follow Request"]
                             tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                                 if (buttonIndex != actionSheet.cancelButtonIndex) {
                                     if ([delegate respondsToSelector:@selector(PublicProfileCell:shouldSendFollowRequestToUser:)]) {
                                         [self.followButton setUserInteractionEnabled:NO];
                                         [delegate PublicProfileCell:self shouldSendFollowRequestToUser:self.userObject];
                                         [self.followButton setUserInteractionEnabled:YES];
                                     }
                                 }
                             }];
        }
            break;
        case 1:{
            [UIActionSheet showInView:self.superview
                            withTitle:nil
                    cancelButtonTitle:@"Cancel"
               destructiveButtonTitle:@"Cancel Follow Request"
                    otherButtonTitles:nil
                             tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                                 if (buttonIndex != actionSheet.cancelButtonIndex) {
                                     if ([delegate respondsToSelector:@selector(PublicProfileCell:shouldUnfollowUser:)]) {
                                         [self.followButton setUserInteractionEnabled:NO];
                                         [delegate PublicProfileCell:self shouldUnfollowUser:self.userObject];
                                         [self.followButton setUserInteractionEnabled:YES];
                                     }
                                 }
                             }];
        }
            return;
            break;
//        case 1:{
//            if ([delegate respondsToSelector:@selector(PublicProfileCell:shouldAcceptFollowRequestToUser:)]) {
//                [self.followButton setUserInteractionEnabled:NO];
//                [delegate PublicProfileCell:self shouldAcceptFollowRequestToUser:self.userObject];
//                [self.followButton setUserInteractionEnabled:YES];
//            }
//            
//        }
            break;
        case 2:{
            [UIActionSheet showInView:self.superview
                            withTitle:nil
                    cancelButtonTitle:@"Cancel"
               destructiveButtonTitle:@"Unfollow"
                    otherButtonTitles:nil
                             tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                                 if (buttonIndex != actionSheet.cancelButtonIndex) {
                                     if ([delegate respondsToSelector:@selector(PublicProfileCell:shouldUnfollowUser:)]) {
                                         [self.followButton setUserInteractionEnabled:NO];
                                         [delegate PublicProfileCell:self shouldUnfollowUser:self.userObject];
                                         [self.followButton setUserInteractionEnabled:YES];
                                     }
                                 }
                             }];
        }
            break;
        default:
            break;
    }
}

- (void)setUserObject:(FluxUserObject *)userObject{
    _userObject = userObject;
    
    [self.nameLabel setText:[NSString stringWithFormat:@"@%@",userObject.username]];
    if (userObject.bio) {
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        style.lineSpacing = 5;
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.lineSpacing = 17;
        paragraphStyle.alignment = NSTextAlignmentCenter;
        
        NSDictionary *attribs = @{
                                  NSForegroundColorAttributeName: self.bioLabel.textColor,
                                  NSFontAttributeName: self.bioLabel.font,
                                  NSParagraphStyleAttributeName : style
                                  };
        NSMutableAttributedString *attributedText =
        [[NSMutableAttributedString alloc] initWithString:userObject.bio
                                               attributes:attribs];
        
        [self.bioLabel setAttributedText:attributedText];
        [self.bioLabel setTextAlignment:NSTextAlignmentCenter];
    }
    else{
        [self.bioLabel setText:@""];
    }
    
    switch (userObject.amFollowerFlag) {
        case 0:
            [self.followButton setSelected:NO];
            [self.followButton setImage:[UIImage imageNamed:@"friend"] forState:UIControlStateNormal];
            break;
        case 1:
            [self.followButton setSelected:NO];
            [self.followButton setImage:[UIImage imageNamed:@"friendSent"] forState:UIControlStateNormal];
            break;
//            case 1:
//                [self.followButton setSelected:NO];
//                [self.followButton setFrame:CGRectMake(self.followButton.frame.origin.x, self.frame.origin.y, self.frame.size.width+20, self.frame.size.height)];
//                [self.followButton setImage:[UIImage imageNamed:@"friendAccept"] forState:UIControlStateNormal];
//                
//                break;
        case 2:
            [self.followButton setSelected:YES];
            break;
            
        default:
            break;
    }
    
    if (userObject.isFollowingFlag == 2) {
        [self.statusLabel setText:[NSString stringWithFormat:@"@%@ is following you",userObject.username]];
    }
    

    
    
    [self.photosCountLabel setText:[NSString stringWithFormat:@"%i",userObject.imageCount]];
    [self.followersCountLabel setText:[NSString stringWithFormat:@"%i",userObject.followerCount]];
    [self.followingCountLabel setText:[NSString stringWithFormat:@"%i",userObject.followingCount]];
    
    
    NSString *userID = [UICKeyChainStore stringForKey:FluxUserIDKey service:FluxService];
    if (_userObject.userID == userID.intValue) {
        [self.followButton setHidden:YES];
        [self.statusLabel setHidden:YES];
    }
    
}

@end
