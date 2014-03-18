//
//  FluxAddUserViewController.h
//  Flux
//
//  Created by Kei Turner on 2/5/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FluxFollowerCell.h"
#import "FluxDataManager.h"
#import "FluxSocialImportCell.h"
#import "FluxSocialManager.h"
#import "FluxPublicProfileViewController.h"

#import "GAITrackedViewController.h"
#import <Accounts/Accounts.h>

typedef enum QuerySearchState : NSUInteger {
    notSearching = 0,
    searching = 1,
    searched = 2
} QuerySearchState;

@class FluxAddUserViewController;
@protocol FluxAddUserViewControllerDelegate <NSObject>
@optional
- (void)AddUserViewController:(FluxAddUserViewController *)AddUserVC didAddFollower:(FluxUserObject*)userObject;
- (void)AddUserViewController:(FluxAddUserViewController *)AddUserVC didUnfollowUser:(FluxUserObject*)userObject;
@end

@interface FluxAddUserViewController : GAITrackedViewController<UISearchBarDelegate, UISearchDisplayDelegate, UITableViewDataSource, UITableViewDelegate, FluxFriendFollowerCellDelegate, UIScrollViewDelegate, FluxSocialManagerDelegate, PublicProfileDelegate>{
    QuerySearchState searchState;
    UISearchBar *userSearchBar;
    IBOutlet UITableView *addUsersTableView;
    IBOutlet UIBarButtonItem *searchBarBarButton;
    IBOutlet UIToolbar *topToolbar;
    IBOutlet UIToolbar *topBarColored;
    
    NSMutableArray*resultsArray;
    NSMutableArray*resultsImageArray;
    NSArray * socialImportArray;
    
    NSTimer*searchTimer;
    NSString*searchQuery;
    
    NSIndexPath*selectedIndexPath;
    BOOL didImport;
    
    id __unsafe_unretained delegate;
    ACAccount*TWAccount;
}

@property (unsafe_unretained) id <FluxAddUserViewControllerDelegate> delegate;
@property (nonatomic, strong) FluxDataManager *fluxDataManager;
- (IBAction)doneButtonAction:(id)sender;
@end
