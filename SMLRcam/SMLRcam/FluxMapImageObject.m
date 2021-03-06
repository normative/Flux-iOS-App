//
//  FluxMapImageObject.m
//  Flux
//
//  Created by Kei Turner on 2013-10-18.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxMapImageObject.h"
#import "FluxLocationServicesSingleton.h"

#define showAltitude NO

@implementation FluxMapImageObject

- (NSString*)title
{
    if (showAltitude) {
        return @"1";
    }
    else{
        return @"1 image";
    }
}

//uncomment this to show the altitude subtitle
//- (NSString*)subtitle
//{
//    BOOL isMetric = [[[NSLocale currentLocale] objectForKey:NSLocaleUsesMetricSystem] boolValue];
//    if (isMetric) {
//        return [NSString stringWithFormat:@"±%.fm altitude", fabs(self.altitudeDiff)];
//    }
//    else{
//        return [NSString stringWithFormat:@"±%.fft altitude", fabs(self.altitudeDiff*0.3048)];
//    }
//}

- (CLLocationCoordinate2D)coordinate
{
    CLLocationCoordinate2D theCoordinate;
    theCoordinate.latitude = self.latitude;
    theCoordinate.longitude = self.longitude;
    
    return theCoordinate;
}

- (double)altitudeDiff{
    FluxLocationServicesSingleton*singleton = [FluxLocationServicesSingleton sharedManager];
    return self.altitude-singleton.location.altitude;
}

@end
