//
//  FluxHashtagTableViewCell.m
//  Flux
//
//  Created by Kei Turner on 2013-08-22.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxHashtagTableViewCell.h"

@implementation FluxHashtagTableViewCell


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        [self setBackgroundColor:[UIColor clearColor]];
        self.tagList = [[DWTagList alloc]init];
        [self.tagList setAutomaticResize:YES];
        [self.contentView addSubview:self.tagList];
    }
    return self;
}



- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    //[super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)tagList:(DWTagList *)list selectedTagWithTitle:(NSString *)title{
    
}




@end
