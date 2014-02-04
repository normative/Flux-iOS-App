//
//  FluxBoxedImageCountView.h
//  Flux
//
//  Created by Kei Turner on 2/3/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FluxBoxedImageCountView : UIView{
    NSMutableArray*boxesArray;
}

@property (nonatomic)float centeredWidth;
@property (nonatomic)int markCount;

- (void)addImageCapture;
- (void)removeImageCapture;

- (void)restoreAllBoxes;

@end
