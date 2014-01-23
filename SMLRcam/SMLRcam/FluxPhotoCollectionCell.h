//
//  FluxPhotoCollectionCell.h
//  Flux
//
//  Created by Kei Turner on 12/30/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KTCheckboxButton.h"

@interface FluxPhotoCollectionCell : UICollectionViewCell

@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) UIImage *theImage;
@property (nonatomic, strong) IBOutlet KTCheckboxButton *checkboxButton;


@end
