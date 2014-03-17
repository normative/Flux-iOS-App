//
//  FluxFriendFollowerCell.h
//  Flux
//
//  Created by Kei Turner on 1/17/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FluxUserObject.h"

@class FluxFollowerCell;
@protocol FluxFriendFollowerCellDelegate <NSObject>
@optional
- (void)FriendFollowerCellButtonWasTapped:(FluxFollowerCell *)friendFollowerCell;
- (void)FriendFollowerCellShouldAcceptFollowingRequest:(FluxFollowerCell *)friendFollowerCell;
- (void)FriendFollowerCellShouldIgnoreFollowingRequest:(FluxFollowerCell *)friendFollowerCell;
@end


@interface FluxFollowerCell : UITableViewCell{
    
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



@end
