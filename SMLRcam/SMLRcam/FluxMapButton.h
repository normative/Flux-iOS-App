//
//  FluxMapButton.h
//  Flux
//
//  Created by Kei Turner on 2013-08-27.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "FluxLocationServicesSingleton.h"
#import "FluxScanImageObject.h"


//this control needs a custom maps look. In order to accomplish this there are two methods (so far)

// 1. Create custom static google map, add it as a sublayer  of the button underneath a default apple map with annotations. hide the apple map canvas, and rotate + update them all together

// 2. Use another map source - such as route-me which suports custom colors etc. This library needs a map source, so we would need an open source map kit (like open street map)

@interface FluxMapButton : UIButton{
    MKMapView * mapView;
    FluxLocationServicesSingleton* locationManager;
    UIImageView *GMapImageView;
    
    NSMutableDictionary*annotationsDictionary;
}

- (id)initWithFrame:(CGRect)frame userLocation:(CLLocationCoordinate2D)location annotationsDict:(NSDictionary*)dict;
- (void)addAnnotation:(FluxScanImageObject*)imgObject;

@end
