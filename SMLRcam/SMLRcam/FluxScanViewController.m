//
//  SMLRcamViewController.m
//  SMLRcam
//
//  Created by Kei Turner on 7/4/13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxScanViewController.h"

#import "UIViewController+MMDrawerController.h"
#import "FluxAnnotationsTableViewController.h"


#pragma mark- OpenGL Init

static CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};
static CGFloat RadiansToDegrees(CGFloat radians) {return radians * 180.0 / M_PI;};


@implementation FluxScanViewController

#pragma mark - location

-(void)updatePlacemark:(NSNotification *)notification
{
    CLPlacemark *placemark = locationManager.placemark;
    NSString * locationString = [placemark.addressDictionary valueForKey:@"SubLocality"];
    locationString = [locationString stringByAppendingString:[NSString stringWithFormat:@", %@", [placemark.addressDictionary valueForKey:@"SubAdministrativeArea"]]];
    locationLabel.text = locationString;
}

#pragma mark - Drawer Methods
// Left Drawer
- (IBAction)showLeftDrawer:(id)sender {
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

// Right Drawer
- (IBAction)showRightDrawer:(id)sender {
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideRight animated:YES completion:nil];
}

#pragma mark - TopView Methods

- (IBAction)showAnnotationsView:(id)sender {
    FluxAnnotationsTableViewController *annotationsFeedView = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"FluxAnnotationsTableViewController"];
    
    popover = [[FPPopoverController alloc] initWithViewController:annotationsFeedView];
    popover.arrowDirection = FPPopoverNoArrow;
    
    //the popover will be presented from the okButton view
    [popover presentPopoverFromView:sender];
}

# pragma mark - prepare segue action with identifer
- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"pushMapModalView"]) {
        FluxMapViewController *fluxMapViewController = (FluxMapViewController *)segue.destinationViewController;
        fluxMapViewController.myViewOrientation = changeToOrientation;
    }
    
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

#pragma mark - orientation and rotation
// Presenting mapview if current view is switching
- (BOOL) shouldAutorotate
{
    return YES;
}

- (NSUInteger) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        changeToOrientation = toInterfaceOrientation;
        
        if (popover != nil) {
            [popover dismissPopoverAnimated:NO];
        }
        
        [self performSegueWithIdentifier:@"pushMapModalView" sender:self];
    }
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation
{
    return changeToOrientation ? changeToOrientation : UIInterfaceOrientationPortraitUpsideDown;
}

#pragma mark - view lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Start the location manager service which will continue for the life of the app
    locationManager = [FluxLocationServicesSingleton sharedManager];
    [locationManager startLocating];
    
    //temporarily set the date range label to today's date
    NSDateFormatter *formatter  = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd MMM, YYYY"];
    [dateRangeLabel setText:[formatter stringFromDate:[NSDate date]]];
    
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillAppear:(BOOL)animated{
    if (locationManager != nil)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePlacemark:) name:FluxLocationServicesSingletonDidUpdatePlacemark object:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [locationManager endLocating];
    
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc{
    NSLog(@"!!!!!!!!!!!!!!!!!!!!!");
    NSLog(@"%s", __func__);
    
    locationManager = nil;
}

@end



