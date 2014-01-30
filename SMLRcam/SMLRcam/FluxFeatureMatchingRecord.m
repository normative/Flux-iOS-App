//
//  FluxFeatureMatchingRecord.m
//  Flux
//
//  Created by Ryan Martens on 11/21/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxFeatureMatchingRecord.h"
#import "FluxMatcherWrapper.h"

@implementation FluxFeatureMatchingRecord

@synthesize cfe = _cfe;
@synthesize ire = _ire;
@synthesize hasCameraScene = _hasCameraScene;
@synthesize hasObjectImage = _hasObjectImage;
@synthesize hasObjectFeatures = _hasObjectFeatures;
@synthesize matched = _matched;
@synthesize failed = _failed;

- (id)init
{
    if (self = [super init])
    {
        self.failed = NO;
        self.matched = NO;
        self.isImageDisplayed = NO;
        self.outputDebugImages = NO;
    }
    return self;
}

- (BOOL)hasCameraScene
{
    return ((_cfe != nil) && (_cfe.frameReady) && (_cfe.cameraRequestDate != nil) &&
            (_cfe.cameraFrameImage != nil));
}

- (BOOL)hasObjectImage
{
    return ((_ire != nil) && (_ire.imageMetadata != nil) && (_ire.imageCacheObject.image != nil));
}

- (BOOL)hasObjectFeatures
{
    BOOL retval = false;
    retval = ((_ire != nil) && (_ire.imageMetadata != nil) && (_ire.imageMetadata.features != nil));
    if (retval)
    {
        // secondary tests...
        // header validation
        binHeader *header = (binHeader *)[_ire.imageMetadata.features bytes];
        
        // parse out and validate the header
        retval = ((header->magic == fluxMagic) && (header->major == 1));
    }
    
    return  retval;
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