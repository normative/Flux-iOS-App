//
//  FluxRightDrawerViewController.h
//  Flux
//
//  Created by Kei Turner on 2013-08-01.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FluxDrawerCheckboxFilterTableViewCell.h"
#import "FluxHashtagTableViewCell.h"

@interface FluxRightDrawerViewController : UITableViewController<DrawerCheckboxTableViewCellDelegate,UISearchBarDelegate, UISearchDisplayDelegate>{
    
    NSArray *rightDrawerTableViewArray;
}
@property (weak, nonatomic) IBOutlet UISearchBar *filterSearchBar;



@end
