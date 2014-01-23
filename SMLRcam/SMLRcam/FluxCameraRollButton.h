//
//  FluxCameraRollButton.h
//  Flux
//
//  Created by Kei Turner on 1/21/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FluxCameraRollButton : UIButton{
    UIImageView*imageView;
}

- (void)addImage:(UIImage*)image;

@end
