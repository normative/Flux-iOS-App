//
//  FluxFriendFollowerCell.h
//  Flux
//
//  Created by Kei Turner on 1/17/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FluxUserObject.h"

@class FluxFriendFollowerCell;
@protocol FluxFriendFollowerCellDelegate <NSObject>
@optional
- (void)FriendFollowerCellButtonWasTapped:(FluxFriendFollowerCell *)friendFollowerCell;
- (void)FriendFollowerCellShouldAcceptFriendRequest:(FluxFriendFollowerCell *)friendFollowerCell;
- (void)FriendFollowerCellShouldIgnoreFriendRequest:(FluxFriendFollowerCell *)friendFollowerCell;
@end


@interface FluxFriendFollowerCell : UITableViewCell{
    
    id __unsafe_unretained delegate;
}

@property (unsafe_unretained) id <FluxFriendFollowerCellDelegate> delegate;

@property (nonatomic, strong)FluxUserObject* userObject;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *bioLabel;
@property (strong, nonatomic) IBOutlet UILabel*socialStatusLabel;
@property (strong, nonatomic) IBOutlet UIImageView *profileImageView;
@property (strong, nonatomic) IBOutlet UIButton *friendFollowButton;
@property (strong, nonatomic) IBOutlet UIView *contentContainerView;
- (IBAction)acceptFriendButtonAction:(id)sender;
- (IBAction)friendFollowButtonAction:(id)sender;
- (IBAction)ignoreFriendButtonAction:(id)sender;
-(void)initCell;

- (void)setSocialMode:(int)socialMode;

@end
