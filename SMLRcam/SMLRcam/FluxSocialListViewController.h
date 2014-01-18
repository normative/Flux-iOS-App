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
    followerMode = 0,
    followingMode = 1,
    friendMode = 2
} SocialListMode;

@interface FluxSocialListViewController : UITableViewController <FluxFriendFollowerCellDelegate>{
    NSMutableArray*friendFollowerArray;
    SocialListMode listMode;
}
@property (nonatomic, strong) FluxDataManager *fluxDataManager;

-(void)prepareViewforMode:(SocialListMode)mode andIDList:(NSArray*)idList;


@end
