//
//  SMLRcamCameraViewController.m
//  SMLRcam
//
//  Created by Kei Turner on 2013-07-29.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxCameraViewController.h"

#import "FluxImageAnnotationViewController.h"

#import <ImageIO/ImageIO.h>
#import <QuartzCore/CoreAnimation.h>



@interface FluxCameraViewController ()

@end

@implementation FluxCameraViewController




// used for KVO observation of the @"capturingStillImage" property to perform flash bulb animation
//static const NSString *AVCaptureStillImageIsCapturingStillImageContext = @"AVCaptureStillImageIsCapturingStillImageContext";

#pragma mark View Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [self setupLocationManager];
    [self startUpdatingLocationAndHeading];
    [self setupMotionManager];
    [self AddGridlinesToView];
    
    [retakeButton setHidden:YES];
    [useButton setHidden:YES];
    
    [self setupAVCapture];
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated{
    [self startDeviceMotion];
    [self startUpdatingLocationAndHeading];
    [self restartAVCapture];
    testTimer = [NSTimer scheduledTimerWithTimeInterval:1/60.0 target:self selector:@selector(UpdateMotionLabels:) userInfo:nil repeats:YES];
}

- (void)viewDidDisappear:(BOOL)animated{
    [testTimer invalidate];
}

- (void)dealloc{
    [self stopUpdatingLocationAndHeading];
    [self stopDeviceMotion];
    motionManager = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Camera Init

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
        isUsingFrontFacingCamera = NO;
        if ( [session canAddInput:deviceInput] )
            [session addInput:deviceInput];
        
        // Make a still image output
        stillImageOutput = [AVCaptureStillImageOutput new];
        //[stillImageOutput addObserver:self forKeyPath:@"capturingStillImage" options:NSKeyValueObservingOptionNew context:(__bridge void *)(AVCaptureStillImageIsCapturingStillImageContext)];
        if ( [session canAddOutput:stillImageOutput] )
            [session addOutput:stillImageOutput];
        
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
        effectiveScale = 1.0;
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

-(void)pauseAVCapture{
    AVCaptureSession * currentSession  = previewLayer.session;
    if (currentSession !=nil) {
        [currentSession stopRunning];
    }
}
-(void)restartAVCapture{
    AVCaptureSession * currentSession  = previewLayer.session;
    if (currentSession !=nil) {
        [currentSession startRunning];
    }
}

//- (void)teardownAVCapture
//{
//	//videoDataOutput = nil;
//    //videoDataOutputQueue = nil;
//	//[videoDataOutput release];
//    //[videoDataOutputQueue release];
//    AVCaptureSession * currentSession  = previewLayer.session;
//    if (currentSession !=nil) {
//        [currentSession stopRunning];
//    }
//    
//	//[stillImageOutput removeObserver:self forKeyPath:@"isCapturingStillImage"];
//	//[stillImageOutput release];
//	//stillImageOutput = nil;
//	[previewLayer removeFromSuperlayer];
//	//[previewLayer release];
//}

- (void)AddGridlinesToView{
    gridView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"CameraGridlines.png"]];
    [gridView setFrame:self.view.bounds];
    [gridView setContentMode:UIViewContentModeScaleAspectFill];
    [self.view insertSubview:gridView aboveSubview:retakeButton];
    [self.view insertSubview:gridView aboveSubview:useButton];
}

#pragma mark Location/Orientation Init

//allocates the location object and sets some parameters
- (void)setupLocationManager
{
    locationManager = [FluxLocationServicesSingleton sharedManager];
    
    if (locationManager != nil)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePositionLabels:) name:FluxLocationServicesSingletonDidUpdateLocation object:nil];
    }
}

- (void)startUpdatingLocationAndHeading
{
    [locationManager startLocating];
}


-(void)updatePositionLabels:(CLLocation *) newLocation
{
    latitudeLabel.text = [NSString stringWithFormat:@"%f",newLocation.coordinate.latitude];
    longitudeLabel.text = [NSString stringWithFormat:@"%f",newLocation.coordinate.longitude];
}

- (void)stopUpdatingLocationAndHeading
{
    [locationManager endLocating];
}

//starts the motion manager and sets an update interval
- (void)setupMotionManager{
    motionManager = [[CMMotionManager alloc] init];
	
	// Tell CoreMotion to show the compass calibration HUD when required to provide true north-referenced attitude
	motionManager.showsDeviceMovementDisplay = YES;
    motionManager.deviceMotionUpdateInterval = 1.0 / 60.0;
}


- (void)startDeviceMotion
{
    if (motionManager) {
        // New in iOS 5.0: Attitude that is referenced to true north
        [motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXTrueNorthZVertical];
    }
}

- (void)stopDeviceMotion
{
    if (motionManager) {
        [motionManager stopDeviceMotionUpdates];
    }
}

- (void)UpdateMotionLabels:(NSTimer*)timer{
    if (motionManager) {
        if ([motionManager isDeviceMotionActive]) {
            xLabel.text = [NSString stringWithFormat:@"%f",motionManager.deviceMotion.attitude.yaw];
            yLabel.text = [NSString stringWithFormat:@"%f",motionManager.deviceMotion.attitude.pitch];
            zLabel.text = [NSString stringWithFormat:@"%f",motionManager.deviceMotion.attitude.roll];
        }
    }
}

#pragma mark - UI Actions

- (IBAction)CloseCamera:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)TakePicture:(id)sender {
    
    __block NSDate *startTime = [NSDate date];
    
    // Collect position and orientation information prior to copying image
    CLLocation *location = locationManager.location;
    CMAttitude *att = motionManager.deviceMotion.attitude;
    
    __block NSDate *endTime = [NSDate date];
    __block NSTimeInterval executionTime = [endTime timeIntervalSinceDate:startTime];
    NSLog(@"Execution Time (1): %f", executionTime);
    
    // Find out the current orientation and tell the still image output.
	AVCaptureConnection *stillImageConnection = [stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
	UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
	AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForDeviceOrientation:curDeviceOrientation];
	[stillImageConnection setVideoOrientation:avcaptureOrientation];
	[stillImageConnection setVideoScaleAndCropFactor:effectiveScale];
	[stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection
                                                  completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error)
        {
             if (error)
             {
                 [self displayErrorOnMainQueue:error withMessage:@"Take picture failed"];
             }
             else
             {
                 endTime = [NSDate date];
                 executionTime = [endTime timeIntervalSinceDate:startTime];
                 NSLog(@"Execution Time (2): %f", executionTime);
                 
                 //save picture to photo album/locally
                 NSData *jpeg = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                 UIImage *theimg = [UIImage imageWithData:jpeg];
                 capturedImage = theimg;
                 
                 // Grab a copy of the current metadata dictionary for modification - will be saved in image
                 CFDictionaryRef metaDict = CMCopyDictionaryOfAttachments(NULL, imageDataSampleBuffer, kCMAttachmentMode_ShouldPropagate);
                 CFMutableDictionaryRef mutableMetadata = CFDictionaryCreateMutableCopy(NULL, 0, metaDict);
                 
                 // Create the metadata dictionary which is saved with image as XML
                 imgMetadata = [[NSMutableDictionary alloc] init];
                 
                 // Create formatted date
                 NSTimeZone      *timeZone   = [NSTimeZone timeZoneWithName:@"UTC"];
                 NSDateFormatter *formatter  = [[NSDateFormatter alloc] init];
                 [formatter setTimeZone:timeZone];
                 [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
                 
                 NSMutableDictionary *GPSDictionary = [[NSMutableDictionary alloc] init];
                 timestampString = nil;
                 
                 if (location != nil)
                 {
                     // Create GPS Dictionary
                     [GPSDictionary setValue:[NSNumber numberWithDouble:fabs(location.coordinate.latitude)] forKey:(NSString *)kCGImagePropertyGPSLatitude];
                     [GPSDictionary setValue:((location.coordinate.latitude >= 0) ? @"N" : @"S") forKey:(NSString *)kCGImagePropertyGPSLatitudeRef];
                     [GPSDictionary setValue:[NSNumber numberWithDouble:fabs(location.coordinate.longitude)] forKey:(NSString *)kCGImagePropertyGPSLongitude];
                     [GPSDictionary setValue:((location.coordinate.longitude >= 0) ? @"E" : @"W") forKey:(NSString *)kCGImagePropertyGPSLongitudeRef];
                     [GPSDictionary setValue:[formatter stringFromDate:[location timestamp]] forKey:(NSString *)kCGImagePropertyGPSDateStamp];
                     [GPSDictionary setValue:[NSNumber numberWithDouble:fabs(location.altitude)] forKey:(NSString *)kCGImagePropertyGPSAltitude];
                     [GPSDictionary setValue:[NSNumber numberWithDouble:fabs(location.horizontalAccuracy)] forKey:(NSString *)(NSString *)@"HorizontalAccuracy"];
                     [GPSDictionary setValue:[NSNumber numberWithDouble:fabs(location.verticalAccuracy)] forKey:(NSString *)(NSString *)@"VerticalAccuracy"];
                     [GPSDictionary setValue:[NSNumber numberWithDouble:fabs(location.speed)] forKey:(NSString *)(NSString *)kCGImagePropertyGPSSpeed];
                     [GPSDictionary setValue:[NSNumber numberWithDouble:fabs(location.course)] forKey:(NSString *)(NSString *)kCGImagePropertyGPSDestBearing];

                     [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss:SS"];
                     //timestampstr = [formatter stringFromDate:loc.timestamp];
                     theDate = [[NSDate alloc]init];
                     timestampString = [formatter stringFromDate:theDate];
                 }
                 else
                 {
                     NSLog(@"No location data to store with image");
                 }
                 
                 // Overwrite updated GPS information
                 CFDictionarySetValue(mutableMetadata, kCGImagePropertyGPSDictionary, (void *)GPSDictionary);
                 
                 // Add GPSDictionary to Position section of XML
                 [imgMetadata setValue:GPSDictionary forKey:(NSString *)@"Position"];
                 
                 //add heading
                 [imgMetadata setValue:[NSNumber numberWithDouble:locationManager.heading] forKey:(NSString *)@"Heading"];
                 
                 NSMutableDictionary *EXIFDictionary = (NSMutableDictionary*)CFDictionaryGetValue(mutableMetadata, kCGImagePropertyExifDictionary);
                 //NSMutableDictionary *EXIFAuxDictionary = (NSMutableDictionary*)CFDictionaryGetValue(mutable, kCGImagePropertyExifAuxDictionary);
                 
                 CFDictionarySetValue(mutableMetadata, kCGImagePropertyExifDictionary, (void *)EXIFDictionary);

                 // Orientation Section
                 CMRotationMatrix m = att.rotationMatrix;
                 
                 // dump the rotation matrix as a 2-d array
                 NSMutableDictionary *OrientDictionary = [[NSMutableDictionary alloc] init];
                 NSArray *rmr1 = [NSArray arrayWithObjects:[NSNumber numberWithDouble:m.m11], [NSNumber numberWithDouble:m.m12],
                                  [NSNumber numberWithDouble:m.m13], [NSNumber numberWithDouble:0.0], nil];
                 NSArray *rmr2 = [NSArray arrayWithObjects:[NSNumber numberWithDouble:m.m21], [NSNumber numberWithDouble:m.m22],
                                  [NSNumber numberWithDouble:m.m23], [NSNumber numberWithDouble:0.0], nil];
                 NSArray *rmr3 = [NSArray arrayWithObjects:[NSNumber numberWithDouble:m.m31], [NSNumber numberWithDouble:m.m32],
                                  [NSNumber numberWithDouble:m.m33], [NSNumber numberWithDouble:0.0], nil];
                 NSArray *rmr4 = [NSArray arrayWithObjects:[NSNumber numberWithDouble:0.0], [NSNumber numberWithDouble:0.0],
                                  [NSNumber numberWithDouble:0.0], [NSNumber numberWithDouble:1.0], nil];
                 NSArray *rm = [NSArray arrayWithObjects:rmr1, rmr2, rmr3, rmr4, nil];
                 [OrientDictionary setValue:rm forKey:(NSString *)@"AttitudeRotationMatrix"];
                 
                 // dump the euler angles as an array
                 NSArray *ev = [NSArray arrayWithObjects:[NSNumber numberWithDouble:att.yaw], [NSNumber numberWithDouble:att.pitch],
                                [NSNumber numberWithDouble:att.roll], nil];
                 [OrientDictionary setValue:ev forKey:(NSString *)@"EulerAngles"];
                 
                 // dump the quaternion portion as an array
                 NSArray *qv = [NSArray arrayWithObjects:[NSNumber numberWithDouble:att.quaternion.w],
                                [NSNumber numberWithDouble:att.quaternion.x], [NSNumber numberWithDouble:att.quaternion.y],
                                [NSNumber numberWithDouble:att.quaternion.z], nil];
                 [OrientDictionary setValue:qv forKey:(NSString *)@"Quaternion"];
                 
                 // Add OrientDictionary to Orientation section of XML
                 [imgMetadata setValue:OrientDictionary forKey:(NSString *)@"Orientation"];
                 
                 // Device Section
                 NSMutableDictionary *DeviceDictionary = [[NSMutableDictionary alloc] init];
                 
                 NSUUID *duid = [[UIDevice currentDevice] identifierForVendor];
                 NSString *model = [[UIDevice currentDevice] model];
                 [DeviceDictionary setValue:[duid UUIDString] forKey:(NSString *)@"DeviceID"];
                 [DeviceDictionary setValue:model forKey:(NSString *)@"Model"];
                 [DeviceDictionary setValue:(isUsingFrontFacingCamera?@"Front":@"Back") forKey:(NSString *)@"Camera"];
                 [DeviceDictionary setValue:NSStringFromUIInterfaceOrientation([UIApplication sharedApplication].statusBarOrientation) forKey:@"Orientation"];
                 [imgMetadata setValue:DeviceDictionary forKey:(NSString *)@"Device"];
                 
                 // Image Section
                 NSMutableDictionary *ImageDictionary = [[NSMutableDictionary alloc] init];
                 
                 [ImageDictionary setValue:timestampString forKey:(NSString *)@"TimeStamp"];
                 [ImageDictionary setValue:@"SelectedCategory" forKey:(NSString *)@"Category"];
                 [ImageDictionary setValue:@"Arbitrary Description, optionally containing #tags or @userlinks" forKey:(NSString *)@"Description"];
                 
                 [imgMetadata setValue:ImageDictionary forKey:(NSString *)@"Image"];
                 
                 
                 // write the file with exif data
                 CGImageSourceRef  source;
                 source = CGImageSourceCreateWithData((__bridge CFDataRef)jpeg, NULL);
                 
                 CFStringRef UTI = CGImageSourceGetType(source); //this is the type of image (e.g., public.jpeg)
                 
                 // this will be the data CGImageDestinationRef will write into
                 imgData = [NSMutableData data];
                 
                 CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imgData,UTI,1,NULL);
                 
                 if(!destination)
                 {
                     NSLog(@"***Could not create image destination ***");
                 }
                 
                 // add the image contained in the image source to the destination, over-writing the old metadata with our modified metadata
                 CGImageDestinationAddImageFromSource(destination,source,0, (CFDictionaryRef) mutableMetadata);
                 
                 // tell the destination to write the image data and metadata into our data object.
                 // It will return false if something goes wrong
                 BOOL success = NO;
                 success = CGImageDestinationFinalize(destination);
                 
                 if(!success)
                 {
                     NSLog(@"***Could not create data from image destination ***");
                 }
                 
                 //cleanup
                 CFRelease(destination);
                 CFRelease(source);
                 
                 //UI Updates
                 [self pauseAVCapture];
                 [useButton setHidden:NO];
                 [retakeButton setHidden:NO];
                 [cameraButton setHidden:YES];
                 [gridView setHidden:YES];
             }
         }];
}

- (IBAction)RetakePictureAction:(id)sender {
    [self restartAVCapture];
    [useButton setHidden:YES];
    [retakeButton setHidden:YES];
    [cameraButton setHidden:NO];
    [gridView setHidden:NO];
    
    //clear all metadata
    [imgMetadata removeAllObjects];
}

- (IBAction)ConfirmImage:(id)sender {
    
    [self pauseAVCapture];
    [self stopDeviceMotion];
    [self stopUpdatingLocationAndHeading];
    
    //clean up UI
    [gridView setHidden:NO];
    [useButton setHidden:YES];
    [retakeButton setHidden:YES];
    [cameraButton setHidden:NO];
    
    
    FluxImageAnnotationViewController *annotationsView = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"FluxImageAnnotationViewController"];
    
    [annotationsView setCapturedImage:capturedImage andImageData:imgData andImageMetadata:imgMetadata andTimestamp:theDate andLocation:locationManager.location];
    
    annotationsView.view.backgroundColor = [UIColor clearColor];
    
//    self.navigationController.modalPresentationStyle = UIModalPresentationCurrentContext;
//    annotationsView.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
//    [self presentViewController:annotationsView animated:YES completion:NULL];
    
    
    annotationsView.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    //self.navigationController.modalPresentationStyle = UIModalPresentationCurrentContext;
    //annotationsView.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    //self.modalPresentationStyle = UIModalPresentationCurrentContext;
    
    [self presentViewController:annotationsView animated:YES completion:nil];
}

// perform a flash bulb animation using KVO to monitor the value of the capturingStillImage property of the AVCaptureStillImageOutput class
//** was commented out because it happened before actual image capture, causiing a delay for the animation
 
//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
//{
//	if ( context == (__bridge void *)(AVCaptureStillImageIsCapturingStillImageContext) ) {
//		BOOL isCapturingStillImage = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
//		
//		if ( isCapturingStillImage ) {
//			// do flash bulb like animation
//			flashView = [[UIView alloc] initWithFrame:[self.view frame]];
//			[flashView setBackgroundColor:[UIColor whiteColor]];
//			[flashView setAlpha:0.f];
//			[[[self view] window] addSubview:flashView];
//			
//			[UIView animateWithDuration:.4f
//							 animations:^{
//								 [flashView setAlpha:1.f];
//							 }
//			 ];
//		}
//		else {
//			[UIView animateWithDuration:.4f
//							 animations:^{
//								 [flashView setAlpha:0.f];
//							 }
//							 completion:^(BOOL finished){
//								 [flashView removeFromSuperview];
//                                 //[flashView release];
//								 flashView = nil;
//							 }
//			 ];
//		}
//	}
//}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // only check for the annotations segue
    if ([[segue identifier] isEqualToString:@"cameraPush"])
    {
        //cleanup this view
        [self pauseAVCapture];
        [self stopDeviceMotion];
        [self stopUpdatingLocationAndHeading];
        
        //clean up UI
        [gridView setHidden:NO];
        [useButton setHidden:YES];
        [retakeButton setHidden:YES];
        [cameraButton setHidden:NO];
        
        // Get reference to the destination view controller
        FluxImageAnnotationViewController *vc = [segue destinationViewController];
        // Set the captured image + metadata
        [vc setCapturedImage:capturedImage andImageData:imgData andImageMetadata:imgMetadata andTimestamp:theDate andLocation:locationManager.location];
    }
}

#pragma mark - Utilities
// utility routing used during image capture to set up capture orientation
- (AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
	AVCaptureVideoOrientation result = deviceOrientation;
	if (deviceOrientation == AVCaptureVideoOrientationLandscapeLeft )
		result = AVCaptureVideoOrientationLandscapeRight;
	else if ( deviceOrientation == UIDeviceOrientationLandscapeRight )
		result = AVCaptureVideoOrientationLandscapeLeft;
	return result;
}

// utility routine to display error aleart if takePicture fails
- (void)displayErrorOnMainQueue:(NSError *)error withMessage:(NSString *)message
{
	dispatch_async(dispatch_get_main_queue(), ^(void) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%d)", message, (int)[error code]]
															message:[error localizedDescription]
														   delegate:nil
												  cancelButtonTitle:@"Dismiss"
												  otherButtonTitles:nil];
		[alertView show];
        //[alertView release];
	});
}

//utility to convert orientation to a string to safely compare against
static inline NSString *NSStringFromUIInterfaceOrientation(UIInterfaceOrientation orientation) {
	switch (orientation) {
		case UIInterfaceOrientationPortrait:           return @"UIInterfaceOrientationPortrait";
		case UIInterfaceOrientationPortraitUpsideDown: return @"UIInterfaceOrientationPortraitUpsideDown";
		case UIInterfaceOrientationLandscapeLeft:      return @"UIInterfaceOrientationLandscapeLeft";
		case UIInterfaceOrientationLandscapeRight:     return @"UIInterfaceOrientationLandscapeRight";
	}
	return @"Unexpected";
}

@end
