//
//  FluxUserLocationPin2.h
//  Flux
//
//  Created by Kei Turner on 1/20/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FluxUserLocationAnnotation.h"
#import "FluxUserLocationOverlay.h"

@interface FluxUserLocationMapPin : NSObject

@property(nonatomic,strong)FluxUserLocationAnnotation* pinAnnotation;
@property(nonatomic,strong)FluxUserLocationOverlay* pulsingCircleOverlay;

@end
