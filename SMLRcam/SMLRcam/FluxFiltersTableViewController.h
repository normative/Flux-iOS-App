//
//  FluxFiltersTableViewController.h
//  Flux
//
//  Created by Kei Turner on 2013-10-03.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FluxDrawerCheckboxFilterTableViewCell.h"
#import "FluxHashtagTableViewCell.h"
#import "FluxDataManager.h"
#import "FluxLocationServicesSingleton.h"
#import "DWTagList.h"
#import "FluxDataFilter.h"

@class FluxFiltersTableViewController;
@protocol FiltersTableViewDelegate <NSObject>
@optional
- (void)FiltersTableViewDidPop:(FluxFiltersTableViewController *)filtersTable andChangeFilter:(FluxDataFilter*)dataFilter;
@end


@interface FluxFiltersTableViewController : UITableViewController<DrawerCheckboxTableViewCellDelegate,UISearchBarDelegate, UISearchDisplayDelegate, NetworkServicesDelegate, DWTagListDelegate>{
    
    NSMutableArray *rightDrawerTableViewArray;
    NSArray *contextFiltersArray;
    NSArray *topTagsArray;
    NSMutableArray *selectedTags;
    FluxLocationServicesSingleton *locationManager;
    
    FluxDataFilter *dataFilter;
    FluxDataFilter *previousDataFilter;
    
    
    __weak id <FiltersTableViewDelegate> delegate;
}
@property (nonatomic, weak) id <FiltersTableViewDelegate> delegate;
@property (nonatomic, weak) FluxDataManager *fluxDataManager;
@property (weak, nonatomic) IBOutlet UISearchBar *filterSearchBar;
@property (nonatomic)int radius;

- (IBAction)cancelButtonAction:(id)sender;
- (IBAction)doneButtonAction:(id)sender;

- (void)prepareViewWithFilter:(FluxDataFilter*)theDataFilter;

@end
