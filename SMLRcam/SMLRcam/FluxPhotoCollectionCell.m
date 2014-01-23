//
//  FluxPhotoCollectionCell.m
//  Flux
//
//  Created by Kei Turner on 12/30/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxPhotoCollectionCell.h"

@implementation FluxPhotoCollectionCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setTheImage:(UIImage *)theImage{
    self->_theImage = theImage;
    [self.imageView setImage:theImage];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
