//
//  FluxRadarView.m
//  Flux
//
//  Created by Jacky So on 2013-09-06.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxCompassButton.h"
#import "FluxDisplayManager.h"
#import "FluxImageRenderElement.h"

@interface FluxCompassButton()

- (void)updateRadarImageView;
- (void)createRadarView;

@end

@implementation FluxCompassButton

#pragma mark - update methods

// update radarStatusMutableArray according to the newMetaData
- (void)updateImageList:(NSNotification*)notification{
    NSMutableArray *newMetadata = [[notification.userInfo objectForKey:@"displayList"]mutableCopy];
    for (int i = 0; i < 12; i++)
    {
        [radarStatusArray replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:0]];
    }
    
    for (FluxImageRenderElement *ire in newMetadata)
    {
        FluxScanImageObject *imageObject = ire.imageMetadata;
        
        double h = imageObject.heading;
        int position = (((int)(h + 360) % 360)  / 30);
        [radarStatusArray replaceObjectAtIndex:position withObject:[NSNumber numberWithInt:1]];
    }
    [self updateRadarImageView];
}

// update radar image view according to the radarStatusMutableArray
- (void)updateRadarImageView
{
    for (int i = 0; i<radarStatusArray.count; i++)
    {
        if ([radarStatusArray objectAtIndex:i] != [NSNumber numberWithInt:0]){
            [[radarImagesArray objectAtIndex:i] setHidden:NO];
        }
        else{
            [[radarImagesArray objectAtIndex:i] setHidden:YES];
        }
    }
}

#pragma mark - alloc and init objects

// first time creating a RadarView
- (void)createRadarView
{
    radarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    UIImageView*bgView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"radarSegmentsBase"]];
    [bgView setFrame:radarView.bounds];
    [radarView addSubview:bgView];
    
    radarStatusArray = [[NSMutableArray alloc] init];
    radarImagesArray = [[NSMutableArray alloc] init];
    
    onImg = [UIImage imageNamed:@"radarSegmentOn"];
    
    for (int i = 0; i < 12; i++)
    {
        [radarStatusArray addObject:[NSNumber numberWithInt:0]];
        UIImageView *radarImageView = [[UIImageView alloc] initWithImage:onImg];
        [radarImageView setFrame: CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        [radarImageView setContentMode:UIViewContentModeScaleAspectFit];
        float rotateDegree = (i * 30);
        radarImageView.transform = CGAffineTransformMakeRotation(rotateDegree * M_PI/180);
        [radarImageView setHidden:YES];
        
        [radarView addSubview:radarImageView];
        [radarImagesArray addObject:radarImageView];
    }
    
    UIImageView *radarHeadingImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"radarButtonCenter"]];
    [radarHeadingImageView setFrame: CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    [radarHeadingImageView setContentMode:UIViewContentModeScaleAspectFit];
    
    radarHeadingImageView.userInteractionEnabled = NO;
    radarHeadingImageView.exclusiveTouch = NO;
    
    radarView.userInteractionEnabled = NO;
    radarView.exclusiveTouch = NO;
    
    
    
    [self addSubview:radarView];
    [self addSubview:radarHeadingImageView];
    [self bringSubviewToFront:radarHeadingImageView];
    
    //setup true north
    CGAffineTransform transform = CGAffineTransformMakeRotation(-(float)45*M_PI/180.0);
    radarView.transform = transform;
}

#pragma mark - location notification

// heading update from location manager
- (void)headingUpdated:(NSNotification *)notification
{
    CGAffineTransform transform = CGAffineTransformMakeRotation(-(float)locationManager.heading*M_PI/180.0);
    radarView.transform = transform;
}

#pragma mark - uiview lifecycle

// init with storyboard
- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        [self setBackgroundColor:[UIColor clearColor]];
        [self createRadarView];        
        
        locationManager = [FluxLocationServicesSingleton sharedManager];
        if (locationManager != nil)
        {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(headingUpdated:) name:FluxLocationServicesSingletonDidUpdateHeading object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateImageList:) name:FluxDisplayManagerDidUpdateDisplayList object:nil];
            [self headingUpdated:nil];
        }
    }
    return self;
}

@end
