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

@interface FluxSocialImportViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, FluxImportContactCellDelegate, PublicProfileDelegate,FluxSearchCellDelegate>{
    BOOL isSearching;
}
@property (strong, nonatomic) IBOutlet UITableView *importUserTableView;

@property (nonatomic, strong) NSString*serviceType;
@property (strong, nonatomic) NSMutableArray*importUserArray;
@property (strong, nonatomic) NSMutableArray*importUserImagesArray;


@property (strong, nonatomic) NSMutableArray*importFluxUserArray;
@property (strong, nonatomic) NSMutableArray*importFluxUserImagesArray;

@property (strong, nonatomic) NSMutableArray*searchResultsUserArray;
@property (strong, nonatomic) NSMutableArray*searchResultsImagesArray;



@end
