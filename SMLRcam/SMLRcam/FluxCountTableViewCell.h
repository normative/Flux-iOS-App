//
//  FluxLeftMenuCell.h
//  Flux
//
//  Created by Kei Turner on 11/11/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CustomBadge.h"

@interface FluxCountTableViewCell : UITableViewCell{
    CustomBadge*badge;
}
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *countLabel;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;

- (void)initCell;
- (void)addBadge:(int)count;
- (void)clearBadge;

@end
