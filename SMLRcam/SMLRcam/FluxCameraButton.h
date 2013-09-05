//
//  FluxCameraButton.h
//  Flux
//
//  Created by Kei Turner on 2013-09-04.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FluxCameraButton : UIButton{
    UIImageView *circleView;
}
- (UIImageView*)getThumbView;

@end
