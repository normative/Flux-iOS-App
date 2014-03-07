//
//  FluxSocialImportViewController.h
//  Flux
//
//  Created by Kei Turner on 2/19/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FluxImportContactCell.h"
#import "FluxSearchCell.h"
#import "FluxPublicProfileViewController.h"
#import "FluxDataManager.h"
#import <Accounts/Accounts.h>

@interface FluxSocialImportViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, FluxImportContactCellDelegate, PublicProfileDelegate,FluxSearchCellDelegate>{
    BOOL isSearching;
    IBOutlet UIView *emptyListView;
    IBOutlet UILabel *emptyListLabel;
    
    BOOL loadDidFail;
    BOOL alreadyAppeared;
}

@property (nonatomic, strong) FluxDataManager *fluxDataManager;


@property (strong, nonatomic) IBOutlet UITableView *importUserTableView;

@property (nonatomic, strong) NSString*serviceType;
@property (nonatomic, strong) ACAccount*TWAccount;
@property (strong, nonatomic) NSMutableArray*importUserArray;
@property (strong, nonatomic) NSMutableArray*importUserImagesArray;


@property (strong, nonatomic) NSMutableArray*importFluxUserArray;
@property (strong, nonatomic) NSMutableArray*importFluxUserImagesArray;

@property (strong, nonatomic) NSMutableArray*searchResultsUserArray;
@property (strong, nonatomic) NSMutableArray*searchResultsImagesArray;



@end
