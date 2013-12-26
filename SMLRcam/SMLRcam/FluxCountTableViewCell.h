//
//  FluxLeftMenuCell.h
//  Flux
//
//  Created by Kei Turner on 11/11/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FluxCountTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *countLabel;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;

- (void)initCell;

@end
