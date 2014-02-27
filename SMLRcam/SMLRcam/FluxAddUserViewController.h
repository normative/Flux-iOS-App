//
//  FluxAddUserViewController.h
//  Flux
//
//  Created by Kei Turner on 2/5/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FluxFriendFollowerCell.h"
#import "FluxDataManager.h"
#import "FluxSocialImportCell.h"
#import "FluxSocialManager.h"
#import "FluxPublicProfileViewController.h"

#import "GAITrackedViewController.h"

typedef enum QuerySearchState : NSUInteger {
    notSearching = 0,
    searching = 1,
    searched = 2
} QuerySearchState;

@class FluxAddUserViewController;
@protocol FluxAddUserViewControllerDelegate <NSObject>
@optional
- (void)AddUserViewController:(FluxAddUserViewController *)AddUserVC didAddFriend:(FluxUserObject*)userObject;
- (void)AddUserViewController:(FluxAddUserViewController *)AddUserVC didUnfriendUser:(FluxUserObject*)userObject;
- (void)AddUserViewController:(FluxAddUserViewController *)AddUserVC didFollowUser:(FluxUserObject*)userObject;
- (void)AddUserViewController:(FluxAddUserViewController *)AddUserVC didUnfollowUser:(FluxUserObject*)userObject;
@end

@interface FluxAddUserViewController : GAITrackedViewController<UISearchBarDelegate, UISearchDisplayDelegate, UITableViewDataSource, UITableViewDelegate, FluxFriendFollowerCellDelegate, UIScrollViewDelegate, FluxSocialManagerDelegate, PublicProfileDelegate>{
    QuerySearchState searchState;
    IBOutlet UISearchBar *userSearchBar;
    IBOutlet UITableView *addUsersTableView;
    IBOutlet UIToolbar *topToolbar;
    IBOutlet UIToolbar *topBarColored;
    
    NSMutableArray*resultsArray;
    NSMutableArray*resultsImageArray;
    NSArray * socialImportArray;
    
    NSTimer*searchTimer;
    NSString*searchQuery;
    
    NSIndexPath*selectedIndexPath;
    
    id __unsafe_unretained delegate;
}

@property (unsafe_unretained) id <FluxAddUserViewControllerDelegate> delegate;
@property (nonatomic, strong) FluxDataManager *fluxDataManager;
- (IBAction)doneButtonAction:(id)sender;
@end
