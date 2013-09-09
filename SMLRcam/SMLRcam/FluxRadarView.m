//
//  FluxRadarView.m
//  Flux
//
//  Created by Jacky So on 2013-09-06.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxRadarView.h"

@interface FluxRadarView()

- (void)updateRadarImageView;
- (void)createRadarView;

@end

@implementation FluxRadarView

#pragma mark - 

// update radarStatusMutableArray according to the newMetaData
- (void)updateRadarWithNewMetaData:(NSMutableDictionary *)newMetaData
{
    for (int i = 0; i < 12; i++)
    {
        [radarStatusMutatbleArray replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:0]];
    }
    
    for (id key in newMetaData)
    {
        FluxScanImageObject *imageObject = [newMetaData objectForKey:key];
        
        float deltaLat = imageObject.coordinate.latitude - locationManager.location.coordinate.latitude;
        float deltaLong = imageObject.coordinate.longitude - locationManager.location.coordinate.longitude;
        
        float degree = atan2f(deltaLat, deltaLong) * 180.0f / M_PI;
        
        int position = abs(degree / 30);
        [radarStatusMutatbleArray replaceObjectAtIndex:position withObject:[NSNumber numberWithInt:1]];
    }
    [self updateRadarImageView];
}

// update radar image view according to the radarStatusMutableArray
- (void)updateRadarImageView
{
    NSLog(@"radarStatusMutatbleArray count is %i", radarStatusMutatbleArray.count);
    for (int i = 0; i<radarStatusMutatbleArray.count; i++)
    {
        UIImage *newRadarImage;
        NSLog(@"radarStatusMutatbleArray object at indext %i is %i",i, [[radarStatusMutatbleArray objectAtIndex:i] integerValue]);
        
        if ([radarStatusMutatbleArray objectAtIndex:i] == [NSNumber numberWithInt:0])
            newRadarImage = [UIImage imageNamed:@"radarOff.png"];
        else
            newRadarImage = [UIImage imageNamed:@"radarOn.png"];
        
        UIImageView *radarImageView = [radarImageMutableArray objectAtIndex:i];
        [radarImageView setImage:newRadarImage];
    }
}

#pragma mark - alloc and init objects

// first time creating a RadarView
- (void)createRadarView
{
    radarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    
    radarStatusMutatbleArray = [[NSMutableArray alloc] init];
    radarImageMutableArray = [[NSMutableArray alloc] init];
    
    for (int i = 0; i<12; i++)
    {
        [radarStatusMutatbleArray addObject:[NSNumber numberWithInt:0]];
        UIImageView *radarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"radarOff.png"]];
        [radarImageView setFrame: CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        [radarImageView setContentMode:UIViewContentModeScaleAspectFit];
        float rotateDegree = i*30;
        radarImageView.transform = CGAffineTransformMakeRotation(rotateDegree * M_PI/180);
        
        [radarView addSubview:radarImageView];
        [radarImageMutableArray addObject:radarImageView];
    }
    
    UIImageView *radarHeadingImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"radarHeading.png"]];
    [radarHeadingImageView setFrame: CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    [radarHeadingImageView setContentMode:UIViewContentModeScaleAspectFit];
    
    [self addSubview:radarView];
    [self addSubview:radarHeadingImageView];
    [self bringSubviewToFront:radarHeadingImageView];
    
    //setup true north
    CGAffineTransform transform = CGAffineTransformMakeRotation(-(float)45*M_PI/180.0);
    radarView.transform = transform;
}

#pragma mark - selector methods

// heading update from location manager
- (void)headingUpdated:(NSNotification *)notification
{
    CGAffineTransform transform = CGAffineTransformMakeRotation(-(float)locationManager.heading*M_PI/180.0);
    radarView.transform = transform;
}

#pragma mark - uiview lifecycle

//
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self createRadarView];
    }
    return self;
}

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
