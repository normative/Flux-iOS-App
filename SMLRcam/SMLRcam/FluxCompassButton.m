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
#import "Masonry.h"

@interface FluxCompassButton()

- (void)updateRadarImageView;
- (void)createRadarView;

@end

@implementation FluxCompassButton

#pragma mark - update methods

// update radarStatusMutableArray according to the newMetaData
- (void)updateImageList:(NSNotification*)notification
{
    NSMutableArray *newMetadata = [[notification.userInfo objectForKey:@"displayList"]mutableCopy];
    for (int i = 0; i < 12; i++)
    {
        [radarStatusArray replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:0]];
    }
    
    for (FluxImageRenderElement *ire in newMetadata)
    {
        FluxScanImageObject *imageObject = ire.imageMetadata;
        
        int bucket_size_degrees = 30;
        double h = imageObject.absHeading;
        int position = (((int)(h + bucket_size_degrees/2 + 360) % 360)  / bucket_size_degrees);
        [radarStatusArray replaceObjectAtIndex:position withObject:[NSNumber numberWithInt:1]];
    }
    
    [self updateRadarImageView];
}

// update radar image view according to the radarStatusMutableArray
- (void)updateRadarImageView
{
    for (int i = 0; i<radarStatusArray.count; i++)
    {
        if ([[radarStatusArray objectAtIndex:i] integerValue] != 0)
        {
            [[radarImagesArray objectAtIndex:i] setHidden:NO];
        }
        else
        {
            [[radarImagesArray objectAtIndex:i] setHidden:YES];
        }
    }
}

#pragma mark - alloc and init objects

// first time creating a RadarView
- (void)createRadarView
{
    radarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    UIImageView*bgView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"radarSegmentsBase"]];
    [bgView setFrame:radarView.bounds];
    [radarView addSubview:bgView];
    
    [self addSubview:radarView];
    
    [radarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    [bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(radarView);
    }];
    
    radarStatusArray = [[NSMutableArray alloc] init];
    radarImagesArray = [[NSMutableArray alloc] init];
    
    onImg = [UIImage imageNamed:@"radarSegmentOn"];
    
    for (int i = 0; i < 12; i++)
    {
        [radarStatusArray addObject:[NSNumber numberWithInt:0]];
        UIImageView *radarImageView = [[UIImageView alloc] initWithImage:onImg];
        [radarImageView setFrame: CGRectMake(0, 0, 0, 0)];
        [radarImageView setContentMode:UIViewContentModeScaleAspectFit];
        float rotateDegree = (i * 30);
        radarImageView.transform = CGAffineTransformMakeRotation(rotateDegree * M_PI/180);
        [radarImageView setHidden:YES];
        
        [radarView addSubview:radarImageView];
        
        [radarImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(radarView);
        }];
        [radarImagesArray addObject:radarImageView];
    }
    
    UIImageView *radarHeadingImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"radarButtonCenter"]];
    [radarHeadingImageView setFrame: CGRectMake(0, 0, 0, 0)];
    [radarHeadingImageView setContentMode:UIViewContentModeScaleAspectFit];
    
    radarHeadingImageView.userInteractionEnabled = NO;
    radarHeadingImageView.exclusiveTouch = NO;
    
    radarView.userInteractionEnabled = NO;
    radarView.exclusiveTouch = NO;
    
    CGAffineTransform transform = CGAffineTransformMakeRotation(0.0);
    radarView.transform = transform;
    
    [self addSubview:radarHeadingImageView];
    
    [radarHeadingImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    [self bringSubviewToFront:radarHeadingImageView];
}

#pragma mark - location notification

// heading update from location manager
- (void)headingUpdated:(NSNotification *)notification
{
//    CGAffineTransform transform = CGAffineTransformMakeRotation(-(float)locationManager.heading * (M_PI / 180.0));
    CGAffineTransform transform = CGAffineTransformMakeRotation(-(float)locationManager.orientationHeading * (M_PI / 180.0));
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
    }
    
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    locationManager = [FluxLocationServicesSingleton sharedManager];
    
    if (locationManager != nil)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(headingUpdated:) name:FluxLocationServicesSingletonDidUpdateHeading object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateImageList:) name:FluxDisplayManagerDidUpdateDisplayList object:nil];

        [self headingUpdated:nil];
    }
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxLocationServicesSingletonDidUpdateHeading object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxDisplayManagerDidUpdateDisplayList object:nil];
}

@end
