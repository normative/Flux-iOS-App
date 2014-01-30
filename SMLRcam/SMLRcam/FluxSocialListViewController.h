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

typedef enum SocialListMode : NSUInteger {
    friendMode = 0,
    followingMode = 1,
    followerMode = 2
} SocialListMode;

@interface FluxSocialListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, FluxFriendFollowerCellDelegate>{
    SocialListMode listMode;
    IBOutlet UISegmentedControl *segmentedControl;
    IBOutlet UITableView *socialTableView;
    NSMutableArray*socialListArray;
}
@property (nonatomic, strong) FluxDataManager *fluxDataManager;
- (IBAction)segmentedControllerDidChange:(id)sender;

//-(void)prepareViewforMode:(SocialListMode)mode andIDList:(NSArray*)idList;


@end
