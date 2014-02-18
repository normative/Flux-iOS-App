//
//  FluxMapViewController.m
//  Flux
//
//  Created by Jacky So on 2013-08-12.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxMapViewController.h"
#import "ProgressHUD.h"

#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"

NSString* const locationAnnotationIdentifer = @"locationAnnotation";
NSString* const userAnnotationIdentifer = @"userAnnotation";

@interface FluxMapViewController ()

- (void) setupLocationManager;
- (void) setupMapView;

@end

@implementation FluxMapViewController

@synthesize myViewOrientation;

#pragma mark - Callbacks

- (void)didUpdateMapPins:(NSNotification*)notification{
    if (self.fluxDisplayManager.fluxMapContentMetadata) {
        outstandingRequests--;
        [filterButton setTitle:[NSString stringWithFormat:@"%i",self.fluxDisplayManager.fluxMapContentMetadata.count] forState:UIControlStateNormal];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^
       {
           if (self.fluxDisplayManager.fluxMapContentMetadata) {
               
               dispatch_async(dispatch_get_main_queue(), ^
                              {
                                  [fluxMapView removeAnnotations:fluxMapView.annotations];
                                  [fluxMapView addAnnotations:self.fluxDisplayManager.fluxMapContentMetadata];
                                  //clear it.
                                  [self.fluxDisplayManager setFluxMapContentMetadata:nil];
                              });
           }
       });
    }
}

- (void)didFailToUpdatePins:(NSNotification*)notification{
    NSString*str = [[notification userInfo]objectForKey:@"errorString"];
    [ProgressHUD showError:str];
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

-(void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    
    MKCoordinateRegion region = mapView.region;
    CLLocationCoordinate2D centerCoordinate = mapView.centerCoordinate;
    CLLocation * newLocation = [[CLLocation alloc] initWithLatitude:centerCoordinate.latitude+region.span.latitudeDelta longitude:centerCoordinate.longitude];
    CLLocation * centerLocation = [[CLLocation alloc] initWithLatitude:centerCoordinate.latitude longitude:centerCoordinate.longitude];
    CLLocationDistance screenDistance = [centerLocation distanceFromLocation:newLocation]; // in meters
    
    MKMapPoint p1 = MKMapPointForCoordinate(fluxMapView.centerCoordinate);
    MKMapPoint p2 = MKMapPointForCoordinate(lastSynchedLocation);
    CLLocationDistance distanceFromLastSync = MKMetersBetweenMapPoints(p1, p2);
    BOOL distanceFlag = (distanceFromLastSync)>lastRadius;
    BOOL radiusFlag = (screenDistance/2)>lastRadius;
    
    if (distanceFlag || radiusFlag) {
        [self.fluxDisplayManager requestMapPinsForLocation:fluxMapView.centerCoordinate withRadius:screenDistance/2 andFilter:self.currentDataFilter];
        outstandingRequests++;
    }

    lastSynchedLocation = fluxMapView.centerCoordinate;
    lastRadius = screenDistance/2;
    
    
    MKMapRect narrowedScreenRect = [self shrunkenMapRect:fluxMapView.visibleMapRect];
    [filterButton setTitle:[NSString stringWithFormat:@"%i",[[fluxMapView annotationsInMapRect:narrowedScreenRect]count]] forState:UIControlStateNormal];
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay {
    
    userLocationPin.pulsingCircleOverlay = [[FluxUserLocationOverlay alloc]init];
    userLocationPin.pulsingCircleOverlay.coordinate = overlay.coordinate;
    userLocationPin.pulsingCircleOverlay.boundingMapRect = overlay.boundingMapRect;
    
    return userLocationPin.pulsingCircleOverlay;
}

- (MKMapRect)shrunkenMapRect:(MKMapRect)mapRect{
    MKOverlayRenderer*tmpRenderer = [[MKOverlayRenderer alloc]init];
    CGRect narowedRect = [tmpRenderer rectForMapRect:mapRect];
    NSLog(@"Norm: %@",NSStringFromCGRect(narowedRect));
    narowedRect = CGRectInset(narowedRect, narowedRect.size.width*.15, narowedRect.size.width*.15);
    mapRect = [tmpRenderer mapRectForRect:narowedRect];
    NSLog(@"Small: %@",NSStringFromCGRect(narowedRect));
    return mapRect;
}

- (void)setupLocationManager
{
    self.locationManager = [FluxLocationServicesSingleton sharedManager];
}

- (void)didUpdateLocation:(NSNotification*)notification
{
    // NSLog(@"Old Accuracy: %f, New Accuract: %f",tempCircle.radius, locationManager.location.horizontalAccuracy);
//    [UIView animateWithDuration:0.5f
//                     animations:^(void){
//                         
//                     }
//                     completion:^(BOOL finished){
//                         
//                     }];
    [userLocationPin.pinAnnotation setCoordinate:self.locationManager.location.coordinate];
    
    [fluxMapView removeOverlay:tempCircle];
    tempCircle = [MKCircle circleWithCenterCoordinate:self.locationManager.location.coordinate radius:self.locationManager.location.horizontalAccuracy];
    [fluxMapView addOverlay:tempCircle];
}

#pragma mark - IBActions

//mapKit uses openGL, this clears the context for our openGlView
- (IBAction)closeButtonAction:(id)sender{
    [self dismissViewControllerAnimated:YES completion:^(void)
     {
         [EAGLContext setCurrentContext:nil];
     }];
}

#pragma mark - Filters
- (void)FiltersTableViewDidPop:(FluxFiltersViewController *)filtersTable andChangeFilter:(FluxDataFilter *)dataFilter{
    [self animationPopFrontScaleUp];
    
    if (![dataFilter isEqualToFilter:self.currentDataFilter] && dataFilter !=nil) {
        [self setCurrentDataFilter:[dataFilter copy]];
        [self.fluxDisplayManager requestMapPinsForLocation:fluxMapView.centerCoordinate withRadius:lastRadius andFilter:self.currentDataFilter];
        outstandingRequests++;
    }
    
}

- (void)setCurrentDataFilter:(FluxDataFilter *)currentDataFilter{
    _currentDataFilter = currentDataFilter;
    
    if ([currentDataFilter isEqualToFilter:[[FluxDataFilter alloc]init]]) {
        [filterButton setBackgroundImage:[UIImage imageNamed:@"filterButton"] forState:UIControlStateNormal];
    }
    else{
        [filterButton setBackgroundImage:[UIImage imageNamed:@"FilterButton_active"] forState:UIControlStateNormal];
    }
}

#pragma mark - view lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupLocationManager];
    
    firstRunDone = NO;
    transitionFadeView = [[UIView alloc]initWithFrame:self.view.bounds];
    [transitionFadeView setBackgroundColor:[UIColor blackColor]];
    [transitionFadeView setAlpha:0.0];
    [transitionFadeView setHidden:YES];
    [self.view addSubview:transitionFadeView];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if (!firstRunDone)
    {
        [self setupMapView];
        firstRunDone = YES;
    }
    else
    {
        [self didUpdateLocation:nil];
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.screenName = @"Map View";
}

// initialize and allocate memory to the map view object
- (void) setupMapView
{
    [fluxMapView setShowsUserLocation:NO];
    [fluxMapView setPitchEnabled:NO];
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(self.locationManager.location.coordinate, 150, 150);
    MKCoordinateRegion adjustedRegion = [fluxMapView regionThatFits:viewRegion];
    [fluxMapView setRegion:adjustedRegion animated:YES];
    lastSynchedLocation = self.locationManager.location.coordinate;
    lastRadius = 75.0;
    outstandingRequests = 0;
    
    userLocationPin = [[FluxUserLocationMapPin alloc]init];
    userLocationPin.pinAnnotation = [[FluxUserLocationAnnotation alloc] initWithCoordinate:self.locationManager.location.coordinate];
    userLocationPin.pinAnnotation.title = @"Current Location";
    userLocationPin.pinAnnotation.horizontalAccuracy = self.locationManager.location.horizontalAccuracy;
    [fluxMapView addAnnotation:userLocationPin.pinAnnotation];
    
    //userLocationPin.pulsingCircleOverlay = [[FluxUserLocationOverlay alloc]init];
    tempCircle = [MKCircle circleWithCenterCoordinate:self.locationManager.location.coordinate radius:self.locationManager.location.horizontalAccuracy];
    [fluxMapView addOverlay:tempCircle];

    
    filterButton.contentEdgeInsets = UIEdgeInsetsMake(2.0, 0.0, 0.0, 0.0);
    
    if (self.currentDataFilter == nil) {
        self.currentDataFilter = [[FluxDataFilter alloc] init];
    }
    else{
        if ([self.currentDataFilter isEqualToFilter:[[FluxDataFilter alloc]init]]) {
            [filterButton setBackgroundImage:[UIImage imageNamed:@"filterButton"] forState:UIControlStateNormal];
        }
        else{
            [filterButton setBackgroundImage:[UIImage imageNamed:@"FilterButton_active"] forState:UIControlStateNormal];
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateLocation:) name:FluxLocationServicesSingletonDidUpdateLocation object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateMapPins:) name:FluxDisplayManagerDidUpdateMapPinList object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFailToUpdatePins:) name:FluxDisplayManagerDidFailToUpdateMapPinList object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxLocationServicesSingletonDidUpdateLocation object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxDisplayManagerDidUpdateMapPinList object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxDisplayManagerDidFailToUpdateMapPinList object:nil];
    
    
}

#pragma mark Transitions
- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //set the delegate of the navControllers top view (our filters View)
    UINavigationController*tmp = segue.destinationViewController;
    FluxFiltersViewController* filtersVC = (FluxFiltersViewController*)tmp.topViewController;
    [filtersVC setDelegate:self];
    [filtersVC setFluxDataManager:self.fluxDisplayManager.fluxDataManager];
    [filtersVC prepareViewWithFilter:self.currentDataFilter andInitialCount:[[fluxMapView annotationsInMapRect:[self shrunkenMapRect:fluxMapView.visibleMapRect]]count]];
    [self animationPushBackScaleDown];
    [filtersVC setRadius:lastRadius];
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
