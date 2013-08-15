//
//  FluxAnnotationTableViewCell.h
//  Flux
//
//  Created by Kei Turner on 2013-08-12.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FluxAnnotationTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *contentImageView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *userLabel;
@property (weak, nonatomic) IBOutlet UILabel *timestampLabel;

@end
