//
//  FluxFiltersTableViewController.h
//  Flux
//
//  Created by Kei Turner on 2013-10-03.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FluxSocialFilterCell.h"
#import "FluxTagFilterCell.h"

#import "FluxDataManager.h"
#import "FluxLocationServicesSingleton.h"
#import "FluxDataFilter.h"

@class FluxFiltersViewController;
@protocol FiltersTableViewDelegate <NSObject>
@optional
- (void)FiltersTableViewDidPop:(FluxFiltersViewController *)filtersTable andChangeFilter:(FluxDataFilter*)dataFilter;
@end


@interface FluxFiltersViewController : UIViewController<UITableViewDataSource, UITableViewDelegate,UISearchBarDelegate, UISearchDisplayDelegate, NetworkServicesDelegate, SocialFilterTableViewCellDelegate, TagFilterTableViewCellDelegate>{
    
    NSMutableArray *rightDrawerTableViewArray;
    NSArray *socialFiltersArray;
    NSArray *topTagsArray;
    NSMutableArray *selectedTags;
    FluxLocationServicesSingleton *locationManager;
    
    UIImage*bgImage;
    
    int imageCount;
    
    FluxDataFilter *dataFilter;
    FluxDataFilter *previousDataFilter;
    
    __weak id <FiltersTableViewDelegate> delegate;
}
@property (nonatomic, weak) id <FiltersTableViewDelegate> delegate;
@property (nonatomic, weak) FluxDataManager *fluxDataManager;
@property (strong, nonatomic) IBOutlet UISearchBar *tagsSearchBar;
@property (nonatomic)int radius;
@property (strong, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (strong, nonatomic) IBOutlet UITableView *filterTableView;

- (IBAction)cancelButtonAction:(id)sender;
- (IBAction)doneButtonAction:(id)sender;

- (void)prepareViewWithFilter:(FluxDataFilter*)theDataFilter;
- (void)setBackgroundView:(UIImage*)image;

@end
