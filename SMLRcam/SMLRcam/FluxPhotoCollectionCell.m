//
//  FluxPhotoCollectionCell.m
//  Flux
//
//  Created by Kei Turner on 12/30/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxPhotoCollectionCell.h"

@implementation FluxPhotoCollectionCell

@synthesize delegate;

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

//- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
//    UITouch *touch = [[event allTouches] anyObject];
//    CGPoint touchLocation = [touch locationInView:self];
//    
//    if (CGRectContainsPoint(self.lockContainerView.frame, touchLocation)) {
//        if ([delegate respondsToSelector:@selector(PhotoCollectionCellLockWasTapped:)]) {
//            [delegate PhotoCollectionCellLockWasTapped:self];
//        }
//    }
//    else{
//        if ([delegate respondsToSelector:@selector(PhotoCollectionCellWasTapped:)]) {
//            [delegate PhotoCollectionCellWasTapped:self];
//        }
//    }
//}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
