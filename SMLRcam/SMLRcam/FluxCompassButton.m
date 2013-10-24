//
//  FluxRadarView.m
//  Flux
//
//  Created by Jacky So on 2013-09-06.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxCompassButton.h"

@interface FluxCompassButton()

- (void)updateRadarImageView;
- (void)createRadarView;

@end

@implementation FluxCompassButton

#pragma mark - update methods

// update radarStatusMutableArray according to the newMetaData
- (void)updateRadarWithNewMetaData:(NSMutableDictionary *)newMetaData
{
    for (int i = 0; i < 12; i++)
    {
        [radarStatusArray replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:0]];
    }
    
    for (id key in newMetaData)
    {
        FluxScanImageObject *imageObject = [newMetaData objectForKey:key];
        
        //float deltaLat = imageObject.coordinate.latitude - locationManager.location.coordinate.latitude;
        //float deltaLong = imageObject.coordinate.longitude - locationManager.location.coordinate.longitude;
        //float degree = atan2f(deltaLat, deltaLong) * 180.0f / M_PI;
        
        int position = abs(imageObject.heading / 30);
        [radarStatusArray replaceObjectAtIndex:position withObject:[NSNumber numberWithInt:1]];
    }
    [self updateRadarImageView];
}

// update radar image view according to the radarStatusMutableArray
- (void)updateRadarImageView
{
    for (int i = 0; i<radarStatusArray.count; i++)
    {
        if ([radarStatusArray objectAtIndex:i] == [NSNumber numberWithInt:0]){
            [[radarImagesArray objectAtIndex:i] setImage:offImg];
        }
        else{
            [[radarImagesArray objectAtIndex:i] setImage:onImg];
        }
    }
}

#pragma mark - alloc and init objects

// first time creating a RadarView
- (void)createRadarView
{
    radarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    
    radarStatusArray = [[NSMutableArray alloc] init];
    radarImagesArray = [[NSMutableArray alloc] init];
    
    offImg = [UIImage imageNamed:@"radarSegmentOff"];
    onImg = [UIImage imageNamed:@"radarSegmentOn"];
    
    for (int i = 0; i<12; i++)
    {
        [radarStatusArray addObject:[NSNumber numberWithInt:0]];
        UIImageView *radarImageView = [[UIImageView alloc] initWithImage:offImg];
        [radarImageView setFrame: CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        [radarImageView setContentMode:UIViewContentModeScaleAspectFit];
        float rotateDegree = i*30;
        radarImageView.transform = CGAffineTransformMakeRotation(rotateDegree * M_PI/180);
        
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
            [self headingUpdated:nil];
        }
    }
    return self;
}

@end
