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

@synthesize imageDict;

#pragma mark - Location

-(void)didUpdatePlacemark:(NSNotification *)notification
{
    NSString *locationString = locationManager.subadministativearea;
    NSString *sublocality = locationManager.sublocality;
    
    if (sublocality.length > 0)
    {
        locationString = [NSString stringWithFormat:@"%@, %@", sublocality, locationString];
    }
    [locationLabel setText: locationString];
}

- (void)didUpdateHeading:(NSNotification *)notification{
//    CLLocationDirection heading = locationManager.heading;
//    if (locationManager.location != nil) {
//        ;
//    }
}

- (void)didUpdateLocation:(NSNotification *)notification{
    CLLocation *loc = locationManager.location;
    [networkServices getImagesForLocation:loc.coordinate andRadius:50];
}

#pragma mark - Network Services

- (void)setupNetworkServices{
    networkServices = [[FluxNetworkServices alloc]init];
    [networkServices setDelegate:self];
}

#pragma Networking Delegate Methods

- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices didreturnImageList:(NSMutableDictionary *)imageList
{
    self.imageDict = imageList;
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

//show list of images currently visible
- (IBAction)showAnnotationsView:(id)sender {
    FluxAnnotationsTableViewController *annotationsFeedView = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"FluxAnnotationsTableViewController"];
 
    [annotationsFeedView setTableViewdict: self.imageDict];

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

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (void)setupLayer
{
    _eaglLayer = (CAEAGLLayer*) self.view.layer;
    _eaglLayer.opaque = YES;
}

- (void)setupContext
{
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    _context = [[EAGLContext alloc] initWithAPI:api];
    if (!_context)
    {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
    }
    
    if (![EAGLContext setCurrentContext:_context])
    {
        NSLog(@"Failed to set current OpenGL context");
    }
}
#pragma mark - AV Capture Methods

- (void)setupAVCapture
{
	NSError *error = nil;
	
	AVCaptureSession *session = [AVCaptureSession new];
    [session setSessionPreset:AVCaptureSessionPresetHigh]; // full resolution photo...
	
    // Select a video device, make an input
    device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    //set autofocus
    BOOL locked = [device lockForConfiguration:nil];
    if (locked)
    {
        device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
        [device unlockForConfiguration];
    }
 	
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    
    if (error == nil)
    {
        if ( [session canAddInput:deviceInput] )
            [session addInput:deviceInput];
        
        // Make a still image output
        //stillImageOutput = [AVCaptureStillImageOutput new];
        //[stillImageOutput addObserver:self forKeyPath:@"capturingStillImage" options:NSKeyValueObservingOptionNew context:(__bridge void *)(AVCaptureStillImageIsCapturingStillImageContext)];
//        if ( [session canAddOutput:stillImageOutput] )
//            [session addOutput:stillImageOutput];
        
        // Make a video data output
        videoDataOutput = [AVCaptureVideoDataOutput new];
        
        // we want BGRA, both CoreGraphics and OpenGL work well with 'BGRA'
        NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:
                                           [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        [videoDataOutput setVideoSettings:rgbOutputSettings];
        [videoDataOutput setAlwaysDiscardsLateVideoFrames:YES]; // discard if the data output queue is blocked (as we process the still image)
        
        // create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured
        // a serial dispatch queue must be used to guarantee that video frames will be delivered in order
        // see the header doc for setSampleBufferDelegate:queue: for more information
        videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
        [videoDataOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];
        
        if ([session canAddOutput:videoDataOutput]){
            [session addOutput:videoDataOutput];
        }
        [[videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:NO];
        previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
        [previewLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
        [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        CALayer *rootLayer = [self.view layer];
        //[rootLayer setMasksToBounds:YES];
        [previewLayer setFrame:self.view.bounds];
        [rootLayer insertSublayer:previewLayer atIndex:0];
        //[rootLayer addSublayer:previewLayer];
        [session startRunning];
    }
    
	//[session release];
    
	if (error)
    {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Failed with error %d", (int)[error code]]
															message:[error localizedDescription]
														   delegate:nil
												  cancelButtonTitle:@"Dismiss"
												  otherButtonTitles:nil];
		[alertView show];
		//[alertView release];
		[self pauseAVCapture];
	}
}

-(void)pauseAVCapture
{
    AVCaptureSession * currentSession  = previewLayer.session;
    if (currentSession !=nil && [currentSession isRunning])
    {
        [currentSession stopRunning];
    }
}
-(void)restartAVCapture
{
    AVCaptureSession * currentSession  = previewLayer.session;
    if (currentSession !=nil  && ![currentSession isRunning])
    {
        [currentSession startRunning];
    }
}

#pragma mark - orientation and rotation
// Presenting mapview if current view is switching
- (BOOL) shouldAutorotate
{
    return YES;
}

- (NSUInteger) supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation))
    {
        changeToOrientation = toInterfaceOrientation;
        
        if (popover != nil)
        {
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
    [self setupLayer];
    [self setupContext];
    [self setupAVCapture];

    // Start the location manager service which will continue for the life of the app
    locationManager = [FluxLocationServicesSingleton sharedManager];
    [locationManager startLocating];
    
    [self setupNetworkServices];
    
    self.imageDict = [[NSMutableDictionary alloc]init];
    
    //temporarily set the date range label to today's date
    NSDateFormatter *formatter  = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd MMM, YYYY"];
    [dateRangeLabel setText:[formatter stringFromDate:[NSDate date]]];
}

- (void)viewWillAppear:(BOOL)animated{
    if (locationManager != nil)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdatePlacemark:) name:FluxLocationServicesSingletonDidUpdatePlacemark object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateHeading:) name:FluxLocationServicesSingletonDidUpdateHeading object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateLocation:) name:FluxLocationServicesSingletonDidUpdateLocation object:nil];
        [self didUpdatePlacemark:nil];
        [self didUpdateHeading:nil];
        [self didUpdateLocation:nil];
    }
    [self restartAVCapture];
}

- (void)viewWillDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxLocationServicesSingletonDidUpdatePlacemark object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxLocationServicesSingletonDidUpdateHeading object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxLocationServicesSingletonDidUpdateLocation object:nil];
    [self pauseAVCapture];
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

- (void)dealloc
{
    locationManager = nil;
}

@end



