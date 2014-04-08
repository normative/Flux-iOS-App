//
//  FluxPhotoCollectionCell.h
//  Flux
//
//  Created by Kei Turner on 12/30/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KTCheckboxButton.h"

@class FluxPhotoCollectionCell;
@protocol FluxPhotoCollectionCellDelegate <NSObject>
@optional
- (void)PhotoCollectionCellLockWasTapped:(FluxPhotoCollectionCell *)photoCollectionCell;
- (void)PhotoCollectionCellWasTapped:(FluxPhotoCollectionCell *)photoCollectionCell;
@end

@interface FluxPhotoCollectionCell : UICollectionViewCell{
    
    id __unsafe_unretained delegate;
}

@property (unsafe_unretained) id <FluxPhotoCollectionCellDelegate> delegate;

@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) UIImage *theImage;
@property (strong, nonatomic) IBOutlet UIView *lockContainerView;
@property (nonatomic, strong) IBOutlet UIImageView *lockImageView;
@property (nonatomic, strong) IBOutlet KTCheckboxButton *checkboxButton;


@end
