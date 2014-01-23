//
//  FluxCameraButton.h
//  Flux
//
//  Created by Kei Turner on 2013-09-04.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum
FluxImageCaptureMode: NSUInteger {
    snapshot_mode = 0,
    camera_mode = 1,
} FluxImageCaptureMode;

@interface FluxCameraButton : UIButton{
    UIImageView *circleView;
}

@property (nonatomic) FluxImageCaptureMode captureMode;

- (UIImageView*)getThumbView;

@end
