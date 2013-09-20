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
#import "FluxDataManager.h"
#import "FluxLocationServicesSingleton.h"
#import "DWTagList.h"
#import "FluxDataFilter.h"

@class FluxRightDrawerViewController;
@protocol RightDrawerFilterDelegate <NSObject>
@optional
- (void)RightDrawer:(FluxRightDrawerViewController*)rightDrawerController didChangeFilter:(FluxDataFilter*)filter;
@end

@interface FluxRightDrawerViewController : UITableViewController<DrawerCheckboxTableViewCellDelegate,UISearchBarDelegate, UISearchDisplayDelegate, NetworkServicesDelegate, DWTagListDelegate>{
    
    NSMutableArray *rightDrawerTableViewArray;
    NSArray *contextFiltersArray;
    NSArray *topTagsArray;
    FluxLocationServicesSingleton *locationManager;
    FluxDataFilter *dataFilter;
    FluxDataFilter *previousDataFilter;
    
    __weak id <RightDrawerFilterDelegate> delegate;
}
@property (nonatomic, weak) id <RightDrawerFilterDelegate> delegate;
@property (nonatomic, weak) FluxDataManager *fluxDataManager;
@property (weak, nonatomic) IBOutlet UISearchBar *filterSearchBar;

- (void)setupLocationManager;
- (void)sendTagRequest;



@end
