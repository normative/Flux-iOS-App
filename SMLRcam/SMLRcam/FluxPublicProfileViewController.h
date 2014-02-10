//
//  FluxPublicProfileViewController.h
//  Flux
//
//  Created by Kei Turner on 11/27/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FluxUserObject.h"
#import "FluxDataManager.h"

#import "GAITrackedViewController.h"

@interface FluxPublicProfileViewController : GAITrackedViewController<UITableViewDelegate, UITableViewDataSource>{
    
    IBOutlet UITableView *profileTableView;
    FluxUserObject*theUser;
    

    IBOutlet UIButton *profielImageButton;
    IBOutlet UILabel *nameLabel;
    IBOutlet UILabel *bioLabel;
    IBOutlet UILabel *photosTitleLabel;
    IBOutlet UILabel *photosCountLabel;
    IBOutlet UILabel *followersTitleLabel;
    IBOutlet UILabel *followersCountLabel;
    IBOutlet UILabel *followingTitleLabel;
    IBOutlet UILabel *followingCountLabel;
    IBOutlet UILabel *socialStatusLabel;
    
    
    IBOutlet UIButton *followButton;
    IBOutlet UIButton *addFriendButton;
}
@property (nonatomic, strong)FluxDataManager*fluxDataManager;

- (void)prepareViewWithUser:(FluxUserObject*)user;

@end
