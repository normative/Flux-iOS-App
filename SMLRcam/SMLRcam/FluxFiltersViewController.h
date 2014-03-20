//
//  FluxFiltersTableViewController.h
//  Flux
//
//  Created by Kei Turner on 2013-10-03.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FluxSocialFilterCell.h"
#import "FluxCheckboxCell.h"

#import "FluxDataManager.h"
#import "FluxLocationServicesSingleton.h"
#import "FluxDataFilter.h"

#import "GAITrackedViewController.h"
#import "FluxFilterCountTableViewCell.h"

@class FluxFiltersViewController;
@protocol FiltersTableViewDelegate <NSObject>
@optional
- (void)FiltersTableViewDidPop:(FluxFiltersViewController *)filtersTable andChangeFilter:(FluxDataFilter*)dataFilter;
@end


@interface FluxFiltersViewController : GAITrackedViewController<UITableViewDataSource, UITableViewDelegate,FluxFilterCountTableViewCellDelegate, SocialFilterTableViewCellDelegate, CheckboxTableViewCellDelegate>{
    
    NSMutableArray *rightDrawerTableViewArray;
    NSArray *socialFiltersArray;
    NSMutableArray *topTagsArray;
    NSMutableArray *selectedTags;
    BOOL isFetchingCount;
    
    UIImage*bgImage;
    
    UILabel*imageCountLabel;
    UIView*imageCountActivityIndicatorView;
    NSTimer*newImageCountTimer;
    int startImageCount;
    
    FluxDataFilter *dataFilter;
    FluxDataFilter *previousDataFilter;
    
    __weak id <FiltersTableViewDelegate> delegate;
}
@property (nonatomic, weak) id <FiltersTableViewDelegate> delegate;
@property (nonatomic, weak) FluxDataManager *fluxDataManager;
@property (strong, nonatomic) IBOutlet UISearchBar *tagsSearchBar;
@property (strong, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (strong, nonatomic) IBOutlet UITableView *filterTableView;
@property (nonatomic) double radius;

@property (strong, nonatomic) IBOutlet NSNumber *imageCount;

@property (strong, nonatomic) CLLocation *location;

- (IBAction)cancelButtonAction:(id)sender;
- (IBAction)doneButtonAction:(id)sender;

- (void)prepareViewWithFilter:(FluxDataFilter*)theDataFilter andInitialCount:(int)count;
- (void)setBackgroundView:(UIImage*)image;

@end
