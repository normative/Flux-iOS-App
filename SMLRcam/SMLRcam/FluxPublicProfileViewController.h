//
//  FluxPublicProfileViewController.h
//  Flux
//
//  Created by Kei Turner on 11/27/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FluxUserObject.h"
#import "FluxDataManager.h"
#import "FluxPublicProfileCell.h"
#import "GAITrackedViewController.h"

typedef enum ProfileViewSource : NSUInteger {
    socialLists = 0,
    search = 1,
    imageTapping = 2
} ProfileViewSource;

@interface FluxPublicProfileViewController : GAITrackedViewController<UITableViewDelegate, UITableViewDataSource, FluxPublicProfileCellDelegate>{
    
    IBOutlet UITableView *profileTableView;
    FluxUserObject*theUser;    
}
@property (nonatomic, strong)FluxDataManager*fluxDataManager;
@property (nonatomic)ProfileViewSource viewSource;

- (void)prepareViewWithUser:(FluxUserObject*)user;

@end
