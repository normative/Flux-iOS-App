//
//  FluxMapButton.m
//  Flux
//
//  Created by Kei Turner on 2013-08-27.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxMapButton.h"

@implementation FluxMapButton


- (id)initWithFrame:(CGRect)frame userLocation:(CLLocationCoordinate2D)location annotationsDict:(NSDictionary *)dict{
    self = [super initWithFrame:frame];
    if (self)
    {
        mapView = [[MKMapView alloc]initWithFrame:frame];
        [mapView setShowsBuildings:YES];
        [mapView setShowsUserLocation:YES];
        
        MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(location, 1, 1);
        [mapView setRegion:viewRegion animated:YES];
        
        annotationsDictionary = [[NSMutableDictionary alloc]initWithDictionary:dict];
        
    }
    return self;
}

- (void)addAnnotation:(FluxScanImageObject *)imgObject{
    [annotationsDictionary setObject:imgObject forKey:[NSNumber numberWithInt:imgObject.imageID]];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
