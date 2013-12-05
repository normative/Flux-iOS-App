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

@interface FluxPublicProfileViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>{
    
    IBOutlet UITableView *profileTableView;
    FluxUserObject*theUser;
    
    UILabel *socialStatusLabel;
    UIButton *followButton;
    UIButton *addFriendButton;
}
@property (nonatomic, strong)FluxDataManager*fluxDataManager;

- (void)prepareViewWithUser:(FluxUserObject*)user;

@end
