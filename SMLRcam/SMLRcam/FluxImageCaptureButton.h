//
//  FluxImageCaptureButton.h
//  Flux
//
//  Created by Kei Turner on 2/3/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FluxCameraButton.h"
#import "FluxBoxedImageCountView.h"


typedef enum
FluxImageCaptureMode: NSUInteger {
    snapshot_mode = 0,
    camera_mode = 1,
} FluxImageCaptureMode;


@interface FluxImageCaptureButton : UIView{
    FluxBoxedImageCountView*boxedCountView;
}

- (void)addImageCapture;
- (void)removeImageCapture;
- (void)restoreAllImages;

@property (nonatomic) int picCount;
@property (nonatomic, strong) FluxCameraButton*button;
@property (nonatomic) FluxImageCaptureMode captureMode;
@property (nonatomic) bool singleImageCaptureMode;
@property (nonatomic, strong) NSTimer *buttonEnableTimer;

@end
