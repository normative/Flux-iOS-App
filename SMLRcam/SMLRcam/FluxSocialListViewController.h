//
//  FluxSocialListViewController.h
//  Flux
//
//  Created by Kei Turner on 1/17/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FluxDataManager.h"
#import "FluxUserObject.h"
#import "FluxFriendFollowerCell.h"
#import "FluxAddUserViewController.h"

typedef enum SocialListMode : NSUInteger {
    friendMode = 0,
    followingMode = 1,
    followerMode = 2
} SocialListMode;

@interface FluxSocialListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, FluxFriendFollowerCellDelegate>{
    SocialListMode listMode;
    IBOutlet UISegmentedControl *segmentedControl;
    IBOutlet UITableView *friendsTableView;
    IBOutlet UITableView *followingTableView;
    IBOutlet UITableView *followersTableView;
    

    NSArray*socialListTableViewVCs;
    NSMutableArray*socialListsRefreshControls;
    NSMutableArray*socialListArray;
    NSMutableArray*socialListImagesArray;
    NSMutableArray*socialTableViews;
}
@property (nonatomic, strong) FluxDataManager *fluxDataManager;
@property (nonatomic, strong) FluxAddUserViewController*searchUserVC;
@property (nonatomic, strong) UINavigationController*childNavC;

@property (atomic, strong) UIWindow *window;

- (IBAction)segmentedControllerDidChange:(id)sender;
- (IBAction)searchButtonAction:(id)sender;

- (void)setSearchVCHidden:(BOOL)hidden animated:(BOOL)animated;


//-(void)prepareViewforMode:(SocialListMode)mode andIDList:(NSArray*)idList;


@end
