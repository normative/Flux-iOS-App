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
#import "FluxNetworkServices.h"
#import "FluxLocationServicesSingleton.h"
#import "DWTagList.h"

@interface FluxRightDrawerViewController : UITableViewController<DrawerCheckboxTableViewCellDelegate,UISearchBarDelegate, UISearchDisplayDelegate, NetworkServicesDelegate, DWTagListDelegate>{
    
    NSArray *rightDrawerTableViewArray;
    NSArray *topTagsArray;
    FluxNetworkServices * networkServices;
    FluxLocationServicesSingleton *locationManager;
}
@property (weak, nonatomic) IBOutlet UISearchBar *filterSearchBar;

- (void)setupNetworkServices;
- (void)setupLocationManager;



@end
