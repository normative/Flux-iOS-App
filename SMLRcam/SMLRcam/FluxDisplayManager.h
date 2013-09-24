//
//  FluxDisplayManager.h
//  Flux
//
//  Created by Kei Turner on 2013-09-23.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FluxDataManager.h"
#import "FluxLocationServicesSingleton.h"

extern NSString* const FluxDisplayManagerDidUpdateDisplayList;
extern NSString* const FluxLocationServicesSingletonDidUpdateHeading;
extern NSString* const FluxLocationServicesSingletonDidUpdatePlacemark;

@interface FluxDisplayManager : NSObject{
    FluxLocationServicesSingleton *locationManager;
}
@property (nonatomic)CLLocationCoordinate2D locationsCoordinate;
@property (nonatomic, strong) FluxDataManager *fluxDataManager;

@end
