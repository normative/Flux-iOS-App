//
//  FluxAnnotationTableViewCell.m
//  Flux
//
//  Created by Kei Turner on 2013-08-12.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxAnnotationTableViewCell.h"

#import <QuartzCore/QuartzCore.h>

@implementation FluxAnnotationTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        [self.descriptionLabel setAdjustsFontSizeToFitWidth:YES];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}



@end
