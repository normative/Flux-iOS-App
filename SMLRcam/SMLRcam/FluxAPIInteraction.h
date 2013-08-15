//
//  FluxAPIInteraction.h
//  Flux
//
//  Created by Kei Turner on 2013-08-14.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FluxScanImageObject.h"
#import "FluxUserObject.h"
#import <CoreLocation/CoreLocation.h>

@class FluxAPIInteraction;
@protocol APIInteractionDelegate <NSObject>
@optional
//images
- (void)APIInteraction:(FluxAPIInteraction *)APIInteraction didreturnImage:(UIImage*)image;
- (void)APIInteraction:(FluxAPIInteraction *)APIInteraction didreturnImageMetadata:(FluxScanImageObject*)imageObject;
- (void)APIInteraction:(FluxAPIInteraction *)APIInteraction didreturnImageList:(NSDictionary*)imageList;

//users
- (void)APIInteraction:(FluxAPIInteraction *)APIInteraction didCreateUser:(FluxUserObject*)userObject;

- (void)APIInteraction:(FluxAPIInteraction *)APIInteraction didFailWithError:(NSError*)e;
@end

@interface FluxAPIInteraction : NSObject{
    RKObjectManager *objectManager;
    __weak id <APIInteractionDelegate> delegate;
}
@property (nonatomic, weak) id <APIInteractionDelegate> delegate;

#pragma mark - image methods

#pragma mark get images

//returns the raw image given an imageID
- (void)getImageForID:(int)imageID;

//returns the thumb image given an imageID
- (void)getThumbImageForID:(int)imageID;

//returns an image object given an imageID
- (void)getImageMetadataForID:(int)imageID;

//returns an NSDictionary list of images at a given location within a given radius
- (void)getImagesForLocation:(CLLocationCoordinate2D)location andRadius:(float)radius;

//test purposes
- (void)getAllImages;

#pragma mark upload images
- (void)uploadImage:(FluxScanImageObject*)img;

#pragma mark - user methods

#pragma mark get users

//returns user for a given userID
- (void)getUserForID:(int)userID;

#pragma mark user creation

- (void)createUser:(FluxUserObject*)user;



@end
