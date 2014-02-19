//
//  FluxSocialImportViewController.h
//  Flux
//
//  Created by Kei Turner on 2/19/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FluxFriendFollowerCell.h"

@interface FluxSocialImportViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, FluxFriendFollowerCellDelegate>
@property (strong, nonatomic) IBOutlet UITableView *importUserTableView;
@property (strong, nonatomic) IBOutlet UISearchBar *importSearchBar;
@property (strong, nonatomic) NSMutableArray*importUserArray;

@end
