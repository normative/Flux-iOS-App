//
//  FluxFeatureMatchingRecord.h
//  Flux
//
//  Created by Ryan Martens on 11/21/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <UIKit/UIKit.h> // because we need UIImage
#import "FluxCameraFrameElement.h"
#import "FluxImageRenderElement.h"

@interface FluxFeatureMatchingRecord : NSObject

@property (nonatomic, strong) FluxCameraFrameElement *cfe; // Camera Frame Element to store scene image + metadata
@property (nonatomic, strong) FluxImageRenderElement *ire; // Image Render Element to store object image + metadata
@property (nonatomic, readonly) BOOL hasCameraScene; // Return YES if image is downloaded.
@property (nonatomic, readonly) BOOL hasObjectImage; // Return YES if image is downloaded.
@property (nonatomic, readonly) BOOL hasObjectFeatures; // Return YES if object features are downloaded.
@property (nonatomic, getter = isMatched) BOOL matched; // Return YES if object is matched to scene
@property (nonatomic, getter = isFailed) BOOL failed; // Return Yes if image matching failed
@property (nonatomic) BOOL isImageDisplayed; // Property to store if image is currently in displayList (i.e. visible or possibly visible)

@end