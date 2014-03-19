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
#import "FluxFollowerCell.h"
#import "FluxAddUserViewController.h"
#import "FluxPublicProfileViewController.h"
#import "FluxSegmentedControl.h"

#import "GAITrackedViewController.h"

typedef enum SocialListMode : NSUInteger {
    amFollowingMode = 0,
    isFollowerMode = 1
    
} SocialListMode;

@interface FluxSocialListViewController : GAITrackedViewController <UITableViewDataSource, UITableViewDelegate, FluxFriendFollowerCellDelegate, PublicProfileDelegate, FluxAddUserViewControllerDelegate>{
    SocialListMode listMode;
    IBOutlet UIView *segmentedControlContainerView;
    IBOutlet FluxSegmentedControl *segmentedControl;
    IBOutlet UITableView *followingTableView;
    IBOutlet UITableView *followersTableView;
    

    NSArray*socialListTableViewVCs;
    NSMutableArray*socialListsRefreshControls;
    NSMutableArray*socialListArray;
    NSMutableArray*socialListImagesArray;
    NSMutableArray*socialTableViews;
    
    NSMutableArray*shouldReloadArray;
    
    NSIndexPath*selectedIndexPath;
}
@property (nonatomic, strong) FluxDataManager *fluxDataManager;
@property (nonatomic, strong) FluxAddUserViewController*searchUserVC;
@property (nonatomic, strong) UINavigationController*childNavC;
@property (nonatomic) int badgeCount;

@property (atomic, strong) UIWindow *window;

- (IBAction)segmentedControllerDidChange:(id)sender;
- (IBAction)searchButtonAction:(id)sender;

- (void)setSearchVCHidden:(BOOL)hidden animated:(BOOL)animated;


//-(void)prepareViewforMode:(SocialListMode)mode andIDList:(NSArray*)idList;


@end
