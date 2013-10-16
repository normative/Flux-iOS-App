//
//  FluxMapViewController.m
//  Flux
//
//  Created by Jacky So on 2013-08-12.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxMapViewController.h"

#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"

#define MERCATOR_RADIUS 85445659.44705395

NSString* const locationAnnotationIdentifer = @"locationAnnotation";
NSString* const userAnnotationIdentifer = @"userAnnotation";

@interface FluxMapViewController ()

- (void) setupLocationManager;
- (void) setupMapView;

@end

@implementation FluxMapViewController

@synthesize myViewOrientation;

#pragma mark - Callbacks
- (void)FiltersTableViewDidPop:(FluxFiltersTableViewController *)filtersTable andChangeFilter:(FluxDataFilter *)dataFilter{
    [self animationPopFrontScaleUp];
    
    if (![dataFilter isEqualToFilter:currentDataFilter] && dataFilter !=nil) {
        currentDataFilter = [dataFilter copy];
    }
}

#pragma mark MapKit Delegate

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
	MIAnnotation *annotation = (MIAnnotation *)view.annotation;
	if ([annotation class] == [MIAnnotation class])
	{
        NSLog(@"It's an annotation class");
    }
    else{
        NSLog(@"It's Not");
    }
}



- (void)setupLocationManager
{
    locationManager = [FluxLocationServicesSingleton sharedManager];
}

// initialize and allocate memory to the map view object
- (void) setupMapView
{
    [fluxMapView setShowsUserLocation:YES];
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(locationManager.location.coordinate, 1050, 1050);
    MKCoordinateRegion adjustedRegion = [fluxMapView regionThatFits:viewRegion];
    [fluxMapView setRegion:adjustedRegion animated:YES];
    [fluxMapView setTheUserLocation:locationManager.location];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^
                   {
                       if (self.fluxDisplayManager.fluxNearbyMetadata) {
                           dispatch_async(dispatch_get_main_queue(), ^
                              {
                                  [fluxMapView addAnnotations:[self.fluxDisplayManager.fluxNearbyMetadata allValues]];
                              });
                       }
                   });
}


#pragma mark - IBActions

//mapKit uses openGL, this clears the context for our openGlView
- (IBAction)closeButtonAction:(id)sender{
    [self dismissViewControllerAnimated:YES completion:^(void)
     {
         [EAGLContext setCurrentContext:nil];
     }];
}

#pragma mark - view lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupLocationManager];
    [self setupMapView];
    [filterButton setTitle:[NSString stringWithFormat:@"%i",self.fluxDisplayManager.fluxNearbyMetadata.count] forState:UIControlStateNormal];
    
    currentDataFilter = [[FluxDataFilter alloc] init];
    transitionFadeView = [[UIView alloc]initWithFrame:self.view.bounds];
    [transitionFadeView setBackgroundColor:[UIColor blackColor]];
    [transitionFadeView setAlpha:0.0];
    [transitionFadeView setHidden:YES];
    [self.view addSubview:transitionFadeView];
    
    self.screenName = @"Map View";
}

#pragma mark Transitions
- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //set the delegate of the navControllers top view (our filters View)
    UINavigationController*tmp = segue.destinationViewController;
    FluxFiltersTableViewController* filtersVC = (FluxFiltersTableViewController*)tmp.topViewController;
    [filtersVC setDelegate:self];
    [filtersVC setFluxDataManager:self.fluxDisplayManager.fluxDataManager];
    [filtersVC prepareViewWithFilter:currentDataFilter];
    
    [self animationPushBackScaleDown];
}

#pragma mark Transition Animations

#define HC_DEFINE_TO_SCALE (CATransform3DMakeScale(0.95, 0.95, 0.95))
#define HC_DEFINE_TO_OPACITY (0.4f)


-(void) animationPushBackScaleDown {
	CABasicAnimation* scaleDown = [CABasicAnimation animationWithKeyPath:@"transform"];
	scaleDown.toValue = [NSValue valueWithCATransform3D:HC_DEFINE_TO_SCALE];
	scaleDown.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
	scaleDown.removedOnCompletion = YES;
	
	CABasicAnimation* opacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
	opacity.fromValue = [NSNumber numberWithFloat:1.0f];
	opacity.toValue = [NSNumber numberWithFloat:HC_DEFINE_TO_OPACITY];
	opacity.removedOnCompletion = YES;
	
	CAAnimationGroup* group = [CAAnimationGroup animation];
	group.duration = 0.4;
	group.animations = [NSArray arrayWithObjects:scaleDown, opacity, nil];
	
	UIView* view = self.navigationController.view?self.navigationController.view:self.view;
	[view.layer addAnimation:group forKey:nil];
    
    [transitionFadeView setHidden:NO];
    [UIView animateWithDuration:0.5 animations:^{
        [transitionFadeView setAlpha:1.0];
    }completion:nil];
}

-(void) animationPopFrontScaleUp {
    [transitionFadeView setAlpha:0.0];
    [transitionFadeView setHidden:YES];
    
	CABasicAnimation* scaleUp = [CABasicAnimation animationWithKeyPath:@"transform"];
	scaleUp.toValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
	scaleUp.fromValue = [NSValue valueWithCATransform3D:HC_DEFINE_TO_SCALE];
	scaleUp.removedOnCompletion = YES;
	
	CABasicAnimation* opacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
	opacity.fromValue = [NSNumber numberWithFloat:HC_DEFINE_TO_OPACITY];
	opacity.toValue = [NSNumber numberWithFloat:1.0f];
	opacity.removedOnCompletion = YES;
	
	CAAnimationGroup* group = [CAAnimationGroup animation];
	group.duration = 0.43;
	group.animations = [NSArray arrayWithObjects:scaleUp, opacity, nil];
	
	UIView* view = self.navigationController.view?self.navigationController.view:self.view;
	[view.layer addAnimation:group forKey:nil];
}

@end
