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

typedef enum QuerySearchState : NSUInteger {
    notSearching = 0,
    searching = 1,
    searched = 2
} QuerySearchState;

@interface FluxAddUserViewController : UIViewController<UISearchBarDelegate, UISearchDisplayDelegate, UITableViewDataSource, UITableViewDelegate, FluxFriendFollowerCellDelegate, UIScrollViewDelegate, FluxSocialManagerDelegate>{
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
}
@property (nonatomic, strong) FluxDataManager *fluxDataManager;
- (IBAction)doneButtonAction:(id)sender;
@end
