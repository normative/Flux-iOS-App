//
//  FluxDisplayManager.h
//  Flux
//
//  Created by Kei Turner on 2013-09-23.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

#import "FluxDataManager.h"
#import "FluxLocationServicesSingleton.h"

extern NSString* const FluxDisplayManagerDidUpdateDisplayList;
extern NSString* const FluxDisplayManagerDidUpdateOpenGLDisplayList;
extern NSString* const FluxDisplayManagerDidUpdateImageTexture;
extern NSString* const FluxDisplayManagerDidUpdateMapPinList;
extern NSString* const FluxDisplayManagerDidFailToUpdateMapPinList;


//this class interacts directly with location + data managers, and determines what images the app should display.
@interface FluxDisplayManager : NSObject{
    FluxDataFilter *dataFilter;
    
    NSLock *_nearbyListLock;
//    NSLock *_renderListLock;
    
//    NSMutableArray *renderedTextures;
    
    int oldTimeBracket;
    NSRange timeSliderRange;
    
    CLLocation*previousMapViewLocation;
}
@property (nonatomic, strong) FluxDataManager *fluxDataManager;
@property (nonatomic, strong) FluxLocationServicesSingleton *locationManager;
@property (nonatomic, strong) NSMutableArray *nearbyList;
@property (nonatomic, strong) NSMutableDictionary *fluxNearbyMetadata;
@property (nonatomic, strong) NSArray *fluxMapContentMetadata;

- (void)timeBracketDidChange:(float)value;

- (void)mapViewWillDisplay;
- (void)requestMapPinsForFilter:(FluxDataFilter*)mapDataFilter;


@end
