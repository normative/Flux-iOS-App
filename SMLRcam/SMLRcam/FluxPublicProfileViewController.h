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
#import "FluxPublicProfileCell.h"
#import "GAITrackedViewController.h"

typedef enum ProfileViewSource : NSUInteger {
    socialLists = 0,
    search = 1,
    imageTapping = 2
} ProfileViewSource;

@class FluxPublicProfileViewController;
@protocol PublicProfileDelegate <NSObject>
@optional
- (void)PublicProfile:(FluxPublicProfileViewController *)publicProfile didAddFollower:(FluxUserObject*)userObject;
- (void)PublicProfile:(FluxPublicProfileViewController *)publicProfile didremoveFollower:(FluxUserObject*)userObject;
- (void)PublicProfile:(FluxPublicProfileViewController *)publicProfile didAddFriend:(FluxUserObject*)userObject;
- (void)PublicProfile:(FluxPublicProfileViewController *)publicProfile didSendFriendRequest:(FluxUserObject*)userObject;
- (void)PublicProfile:(FluxPublicProfileViewController *)publicProfile didRemoveFriend:(FluxUserObject*)userObject;
@end

@interface FluxPublicProfileViewController : GAITrackedViewController<UITableViewDelegate, UITableViewDataSource, FluxPublicProfileCellDelegate>{
    
    IBOutlet UITableView *profileTableView;
    FluxUserObject*theUser;
    id __unsafe_unretained delegate;
}
@property (unsafe_unretained) id <PublicProfileDelegate> delegate;
@property (nonatomic, strong)FluxDataManager*fluxDataManager;
@property (nonatomic)ProfileViewSource viewSource;

- (void)prepareViewWithUser:(FluxUserObject*)user;

@end
