//
//  SMLRcamViewController.m
//  SMLRcam
//
//  Created by Kei Turner on 7/4/13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxScanViewController.h"
#import "UIViewController+MMDrawerController.h"

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
    [locationManager setDelegate:self];
}

- (void)startUpdatingLocation
{
    [locationManager startLocating];
}

- (void)stopUpdatingLocation
{
    [locationManager endLocating];
}

#pragma mark - Location Singleton Delegate Methods
- (void)LocationManager:(FluxLocationServicesSingleton *)locationSingleton didUpdateLocation:(CLLocation *)newLocation{
    [self reverseGeocodeLocation:newLocation];
}


#pragma mark - Drawer Methods

- (IBAction)showLeftDrawer:(id)sender {
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (IBAction)showRightDrawer:(id)sender {
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideRight animated:YES completion:nil];
}

#pragma mark Location_Geocoding

- (void)reverseGeocodeLocation:(CLLocation*)thelocation
{
    theGeocoder = [[CLGeocoder alloc] init];
    
    [theGeocoder reverseGeocodeLocation:thelocation completionHandler:^(NSArray *placemarks, NSError *error) {
        
        if (error)
        {
            if (error.code == kCLErrorNetwork || (error.code == kCLErrorGeocodeFoundPartialResult))
            {
                NSLog(@"No internet connection for reverse geolocation");
                //Alert(@"No Internet connection!");
            }
            else
                NSLog(@"Error Reverse Geolocating: %@", [error localizedDescription]);
        }
        else
        {
            CLPlacemark *placemark = [placemarks objectAtIndex:0];
            NSString * locationString = [placemark.addressDictionary valueForKey:@"SubLocality"];
            locationString = [locationString stringByAppendingString:[NSString stringWithFormat:@", %@", [placemark.addressDictionary valueForKey:@"SubAdministrativeArea"]]];
            locationLabel.text = locationString;
        }
    }];
}

#pragma mark Init

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
    //leftDrawerButton = [[MMDrawerBarButtonItem alloc] initWithTarget:self action:@selector(showLeftDrawer:)];
    
    
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}


@end



