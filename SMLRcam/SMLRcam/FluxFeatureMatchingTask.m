//
//  FluxFeatureMatchingTask.m
//  Flux
//
//  Created by Ryan Martens on 11/21/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxFeatureMatchingTask.h"


@implementation FluxFeatureMatchingTask

@synthesize delegate = _delegate;

#pragma mark - Life Cycle

- (id)initWithImageRenderElement:(FluxImageRenderElement *)ire withMatcher:(FluxMatcherWrapper *)matcher
                        delegate:(id<FluxFeatureMatchingTaskDelegate>)theDelegate
{
    if (self = [super init])
    {
        self.delegate = theDelegate;
        self.imageRenderElementToMatch = ire;
        self.matcherEngine = matcher;
    }
    return self;
}

#pragma mark - Feature matching on image

- (void)main
{
    @autoreleasepool
    {
        if (self.isCancelled)
            return;
        
        NSLog(@"Matching Local ID: %@", self.imageRenderElementToMatch.localID);
        
//        NSData *imageData = [[NSData alloc] initWithContentsOfURL:self.matchRecord.URL];
//        
//        if (self.isCancelled)
//        {
//            imageData = nil;
//            return;
//        }
//        
//        if (imageData)
//        {
//            UIImage *downloadedImage = [UIImage imageWithData:imageData];
//            self.matchRecord.image = downloadedImage;
//        }
//        else
//        {
//            self.matchRecord.failed = YES;
//        }
//        
//        imageData = nil;
//        
//        if (self.isCancelled)
//            return;

        // TODO: this does nothing yet until the IRE propagates back to the OpenGL VC
        self.imageRenderElementToMatch.matched = true;
        
        [(NSObject *)self.delegate performSelectorOnMainThread:@selector(featureMatchingTaskDidFinish:) withObject:self waitUntilDone:NO];
    }
}

@end


