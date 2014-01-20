//
//  FluxUserLocationOverlay.h
//  Flux
//
//  Created by Kei Turner on 1/20/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <QuartzCore/QuartzCore.h>

@interface FluxUserLocationOverlay : MKOverlayView {
    
}
+ (id)overlayWithCoordinate:(CLLocationCoordinate2D)coordinate radius:(CLLocationDistance)radius;
- (id) init;

@property (nonatomic, readwrite) CLLocationCoordinate2D coordinate;
@property (nonatomic, readwrite) MKMapRect boundingMapRect;
@property (nonatomic, readwrite) CLLocationDistance radius;

@property (nonatomic, strong) CALayer *colorHaloLayer;
@property (nonatomic, strong) CALayer *colorStaticLayer;


//pulsingOverlay
@property (nonatomic, strong) UIColor *annotationColor; // default is same as MKUserLocationView
@property (nonatomic, strong) UIColor *pulseColor; // default is same as annotationColor
@property (nonatomic, strong) UIImage *image; // default is nil

@property (nonatomic, readwrite) float pulseScaleFactor; // default is 5.3
@property (nonatomic, readwrite) NSTimeInterval pulseAnimationDuration; // default is 1s
@property (nonatomic, readwrite) NSTimeInterval outerPulseAnimationDuration; // default is 3s
@property (nonatomic, readwrite) NSTimeInterval delayBetweenPulseCycles; // default is 1s

@property (nonatomic, strong) CAAnimationGroup *pulseAnimationGroup;

@end
