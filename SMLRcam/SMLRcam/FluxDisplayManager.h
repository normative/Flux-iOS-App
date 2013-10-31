//
//  FluxDisplayManager.h
//  Flux
//
//  Created by Kei Turner on 2013-09-23.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

#import "FluxDataManager.h"
#import "FluxLocationServicesSingleton.h"
#import "FluxImageRenderElement.h"

extern NSString* const FluxDisplayManagerDidUpdateDisplayList;
extern NSString* const FluxDisplayManagerDidUpdateNearbyList;
extern NSString* const FluxDisplayManagerDidUpdateImageTexture;
extern NSString* const FluxDisplayManagerDidUpdateMapPinList;
extern NSString* const FluxDisplayManagerDidFailToUpdateMapPinList;

extern NSString* const FluxOpenGLShouldRender;


//this class interacts directly with location + data managers, and determines what images the app should display.
@interface FluxDisplayManager : NSObject{
    FluxDataFilter *dataFilter;
    
    NSRecursiveLock *_nearbyListLock;
    NSRecursiveLock *_displayListLock;
    
//    NSMutableArray *renderedTextures;
    
    NSMutableDictionary *_fluxNearbyMetadata;
    NSMutableArray *_nearbyScanList;
    NSMutableArray *_nearbyCamList;
    NSMutableArray *_displayScanList;
    NSMutableArray *_displayCamList;
    
    int _timeRangeMinIndex;
    int _timeRangeMinIndexScan;
//    int oldTimeBracket;
//    NSRange timeSliderRange;
    
    CLLocation*previousMapViewLocation;
    
    float currHeading;
    
    bool _isTimeScrubbing;
    bool _isScanMode;
    
}

@property (nonatomic, strong) FluxDataManager *fluxDataManager;
@property (nonatomic, strong) FluxLocationServicesSingleton *locationManager;
@property (nonatomic, strong) NSArray *fluxMapContentMetadata;

@property (readonly, nonatomic, strong) NSMutableArray *nearbyList;
@property (readonly, nonatomic, strong) NSMutableArray *displayList;

@property (readonly, nonatomic) int nearbyListCount;     // what externals use to get the current count for the nearby list (formerly fluxNearbyMetadata.count)
@property (readonly, nonatomic) int displayListCount;    // what externals use to get the current count for the display list (formerly fluxNearbyMetadata.count)

- (void)timeBracketDidChange:(float)value;

- (void)mapViewWillDisplay;
- (void)requestMapPinsForFilter:(FluxDataFilter*)mapDataFilter;

- (void)lockDisplayList;
- (void)unlockDisplayList;
- (void)sortRenderList:(NSMutableArray *)renderList;

- (FluxImageRenderElement *)getRenderElementForKey:(FluxLocalID *)localID;

@end
