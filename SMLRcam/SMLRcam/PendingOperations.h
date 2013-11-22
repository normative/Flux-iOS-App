//
//  PendingOperations.h
//  Flux
//
//  Created by Ryan Martens on 11/21/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PendingOperations : NSObject

@property (nonatomic, strong) NSMutableDictionary *featureMatchingInProgress;
@property (nonatomic, strong) NSOperationQueue *featureMatchingQueue;

@property (nonatomic, strong) NSMutableDictionary *cameraFrameGrabInProgress;
@property (nonatomic, strong) NSOperationQueue *cameraFrameGrabQueue;

- (void) cleanUpUnusedCameraFrames;

@end