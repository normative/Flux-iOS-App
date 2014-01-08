//
//  FluxCameraFrameElement.h
//  Flux
//
//  Created by Ryan Martens on 11/22/13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FluxOpenGLCommon.h"

@interface FluxCameraFrameElement : NSObject

@property (nonatomic) bool frameRequested;
@property (nonatomic) bool frameReady;
@property (nonatomic, strong) NSCondition *frameReadyCondition;
@property (nonatomic, strong) UIImage *cameraFrameImage; // To store the scene image from the camera
@property (nonatomic, strong) NSDate *cameraRequestDate; // Date request was made
@property (nonatomic, strong) NSDate *cameraFrameDate; // Date of actual camera frame
@property (nonatomic, strong) NSDate *cameraFrameExtractDate; // Date when camera features were extracted
@property (nonatomic) sensorPose cameraPose;
@property (nonatomic) float cameraProjectionDistance;

@end
