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
@end


@interface FluxFriendFollowerCell : UITableViewCell{
    
    id __unsafe_unretained delegate;
}

@property (unsafe_unretained) id <FluxFriendFollowerCellDelegate> delegate;

@property (nonatomic, strong)FluxUserObject* userObject;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *bioLabel;
@property (strong, nonatomic) IBOutlet UIImageView *profileImageView;
@property (strong, nonatomic) IBOutlet UIButton *friendFollowButton;
- (IBAction)friendFollowButtonAction:(id)sender;
-(void)initCell;

@end
