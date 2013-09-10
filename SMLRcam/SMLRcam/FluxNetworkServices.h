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

@class FluxNetworkServices;
@protocol NetworkServicesDelegate <NSObject>
@optional
//images
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didreturnImage:(UIImage*)image forImageID:(int)imageID;
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didreturnImageMetadata:(FluxScanImageObject*)imageObject;
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didreturnImageList:(NSMutableDictionary*)imageList;
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didUploadImage:(FluxScanImageObject*)updatedImageObject;

//users
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didCreateUser:(FluxUserObject*)userObject;

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices uploadProgress:(float)bytesSent ofExpectedPacketSize:(float)size;
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didFailWithError:(NSError*)e;
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices imageUploadDidFailWithError:(NSError*)e;
@end

@interface FluxNetworkServices : NSObject{
    RKObjectManager *objectManager;
    __weak id <NetworkServicesDelegate> delegate;
}
@property (nonatomic, weak) id <NetworkServicesDelegate> delegate;

#pragma mark - image methods

//returns the raw image given an imageID
- (void)getImageForID:(int)imageID;

//returns the thumb image given an imageID
- (void)getThumbImageForID:(int)imageID;

//returns an image object given an imageID
- (void)getImageMetadataForID:(int)imageID;

//returns an NSDictionary list of images at a given location within a given radius
- (void)getImagesForLocation:(CLLocationCoordinate2D)location andRadius:(float)radius;

//returns an NSDictionary list of images filtered based on provided details
- (void)getImagesForLocationFiltered:(CLLocationCoordinate2D)location
                           andRadius:(float)radius
                           andMinAlt:(float)altMin
                           andMaxAlt:(float)altMax
                     andMinTimestamp:(NSDate *)timeMin
                     andMaxTimestamp:(NSDate *)timeMax
                         andHashTags:(NSString *)hashTags
                            andUsers:(NSString *)users
                       andCategories:(NSString *)cats;

// execute the request
- (void)doRequest:(NSURLRequest *)request withResponseDesc:(RKResponseDescriptor *)responseDescriptor;

//test purposes
- (void)getAllImages;

//uploads an image. All account info is stored within the FluxScanImageObject
- (void)uploadImage:(FluxScanImageObject*)theImageObject andImage:(UIImage *)theImage;

#pragma mark  - Users

//returns user for a given userID
- (void)getUserForID:(int)userID;

//creates a user with the given object
- (void)createUser:(FluxUserObject*)user;


- (void)deleteLocations;

@end
