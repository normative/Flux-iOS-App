//
//  FluxLocationServicesSingleton.h
//  Flux
//
//  Created by Kei Turner on 2013-08-08.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import <GLKit/GLKit.h>
#include "FluxKalmanFilter.h"
#include "FluxOpenGLCommon.h"

extern NSString* const FluxLocationServicesSingletonDidUpdateLocation;
extern NSString* const FluxLocationServicesSingletonDidUpdateHeading;
extern NSString* const FluxLocationServicesSingletonDidUpdatePlacemark;

@interface FluxLocationServicesSingleton : NSObject <CLLocationManagerDelegate>{
    CLLocationManager * locationManager;
    NSMutableArray *locationMeasurements;
    
    
    //kalman filtering
    FluxKalmanFilter *kfilter;
    NSTimer *kfilterTimer;
    bool kfStarted;
    bool kfValidData;
    
    
    double kfDt;
    double kfMeasureX;
    double kfMeasureY;
    double kfMeasureZ;
    double kfNoiseX;
    double kfNoiseY;
    double kfXDisp;
    double kfYDisp;
    GLKMatrix4 kfrotation_teM;
    GLKMatrix4 kfInverseRotation_teM;
    sensorPose _kfInit;
    sensorPose _kfMeasure;
    sensorPose _kfPose;
    
    double _rawX;
    double _rawY;
    double _estimateDelta;
    double _resetThreshold;
    
    int kfilterInitialized;
    
    BOOL camIsOn;
    BOOL imageCaptured;
    
    int _displayListHasChanged;
    
    //KF Debugging
    int stepcount;
    double _lastvalue;//steppe
    
    int _validCurrentLocationData;
    int _validInitLocationData;
    
    double _horizontalAccuracy;

}
@property (nonatomic) CLLocation* location;
@property (nonatomic) CLLocation* rawlocation;
@property (nonatomic) CLLocationDirection heading;
@property (nonatomic) CLPlacemark* placemark;

@property (nonatomic) NSString* sublocality;
@property (nonatomic) NSString* subadministativearea;

@property (nonatomic) int notMoving;
@property (nonatomic) kfECEF kflocation;
@property (nonatomic) kfDEBUG kfdebug;

+ (id)sharedManager;

- (void)startLocating;
- (void)endLocating;
- (void)orientationChanged:(NSNotification *)notification;
- (void)WGS84_to_ECEF:(sensorPose *)sp;
- (void)registerPedDisplacementKFilter:(int)direction;
- (void)reverseGeocodeLocation:(CLLocation*)thelocation;

@end