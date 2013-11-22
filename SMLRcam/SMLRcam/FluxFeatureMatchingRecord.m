//
//  FluxFeatureMatchingRecord.m
//  Flux
//
//  Created by Ryan Martens on 11/21/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxFeatureMatchingRecord.h"

@implementation FluxFeatureMatchingRecord

@synthesize cfe = _cfe;
@synthesize ire = _ire;
@synthesize hasCameraScene = _hasCameraScene;
@synthesize hasObjectImage = _hasObjectImage;
@synthesize matched = _matched;
@synthesize failed = _failed;

- (BOOL)hasCameraScene
{
    return _cfe != nil;
}

- (BOOL)hasObjectImage
{
    return _ire != nil;
}

- (BOOL)isFailed
{
    return _failed;
}

- (BOOL)isMatched
{
    return _matched;
}

@end