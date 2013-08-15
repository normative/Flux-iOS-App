//
//  SMLRcamViewController.m
//  SMLRcam
//
//  Created by Kei Turner on 7/4/13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxScanViewController.h"
#import "UIViewController+MMDrawerController.h"
#import "FPPopoverController.h"

#import "FluxAnnotationsTableViewController.h"


#pragma mark- OpenGL Init

static CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};
static CGFloat RadiansToDegrees(CGFloat radians) {return radians * 180.0 / M_PI;};


@implementation FluxScanViewController

#pragma mark - location

//allocates the location object and sets some parameters
- (void)setupLocationManager
{
    // Create the manager object
    locationManager = [FluxLocationServicesSingleton sharedManager];
}

- (void)startUpdatingLocation
{
    if (locationManager != nil)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePlacemark:) name:FluxLocationServicesSingletonDidUpdatePlacemark object:nil];
    }
    [locationManager startLocating];
}

- (void)stopUpdatingLocation
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [locationManager endLocating];
}

-(void)updatePlacemark:(NSNotification *)notification
{
    NSDictionary *userInfoDict = [notification userInfo];
    if (userInfoDict != nil) {
        CLPlacemark *placemark = [userInfoDict objectForKey:FluxLocationServicesSingletonKeyPlacemark];
        NSString * locationString = [placemark.addressDictionary valueForKey:@"SubLocality"];
        locationString = [locationString stringByAppendingString:[NSString stringWithFormat:@", %@", [placemark.addressDictionary valueForKey:@"SubAdministrativeArea"]]];
        locationLabel.text = locationString;
    }
}

#pragma mark - Drawer Methods

- (IBAction)showLeftDrawer:(id)sender {
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (IBAction)showRightDrawer:(id)sender {
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideRight animated:YES completion:nil];
}

#pragma mark - TopView Methods

- (IBAction)showAnnotationsView:(id)sender {
    FluxAnnotationsTableViewController *annotationsFeedView = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"FluxAnnotationsTableViewController"];
    
    
    
    FPPopoverController *popover = [[FPPopoverController alloc] initWithViewController:annotationsFeedView];
    popover.arrowDirection = FPPopoverNoArrow;
    
    //the popover will be presented from the okButton view
    [popover presentPopoverFromView:sender];
}

#pragma mark - OpenGL Methods


+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)setupLayer {
    _eaglLayer = (CAEAGLLayer*) self.view.layer;
    _eaglLayer.opaque = YES;
}

- (void)setupContext {
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    _context = [[EAGLContext alloc] initWithAPI:api];
    if (!_context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
}

#pragma mark - view lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupLocationManager];
    
    //temporarily set the date range label to today's date
    NSDateFormatter *formatter  = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd MMM, YYYY"];
    [dateRangeLabel setText:[formatter stringFromDate:[NSDate date]]];
    
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated{
    [self startUpdatingLocation];
}

- (void)viewWillDisappear:(BOOL)animated{
    [self stopUpdatingLocation];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}


@end



