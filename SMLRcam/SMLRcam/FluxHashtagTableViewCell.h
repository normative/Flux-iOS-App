//
//  FluxHashtagTableViewCell.h
//  Flux
//
//  Created by Kei Turner on 2013-08-22.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DWTagList.h"

@interface FluxHashtagTableViewCell : UITableViewCell<DWTagListDelegate>
@property (strong, nonatomic) IBOutlet DWTagList *tagList;

@end
