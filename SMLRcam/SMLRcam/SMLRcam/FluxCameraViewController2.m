//
//  SMLRcamCameraViewController.m
//  SMLRcam
//
//  Created by Kei Turner on 2013-07-29.
//  Copyright (c) 2013 Denis Delorme. All rights reserved.
//

#import "FluxCameraViewController2.h"

#import <ImageIO/ImageIO.h>
#import <QuartzCore/CoreAnimation.h>

@interface FluxCameraViewController2 ()

@end

@implementation FluxCameraViewController2


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
    [self startUpdatingLocation];
    [self startDeviceMotion];
    
    [imageToolbar setHidden:YES];
    [self setupAVCapture];
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)dealloc{
    [self stopUpdatingLocation];
    [self stopDeviceMotion];
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
    [session setSessionPreset:AVCaptureSessionPresetPhoto]; // full resolution photo...
	
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
        [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
        CALayer *rootLayer = [self.view layer];
        //[rootLayer setMasksToBounds:YES];
        [previewLayer setFrame:self.view.bounds];
        [rootLayer insertSublayer:previewLayer atIndex:0];
        //[rootLayer addSublayer:previewLayer];
        [session startRunning];
        
        //        //add gridlines.. needs to be in a drawrect method. Might switch to png method.
        //        CGContextRef context = UIGraphicsGetCurrentContext();
        //        CGContextSetLineWidth(context, 1.0);
        //        CGFloat components[] = {70/255.0, 70/255.0, 70/255.0, 1.0};
        //        CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
        //        CGColorRef color = CGColorCreate(colorspace, components);
        //        CGContextSetStrokeColorWithColor(context, color);
        //
        //        CGContextMoveToPoint(context, self.view.center.y, 0);
        //        CGContextAddLineToPoint(context, self.view.center.x/2, self.view.frame.size.height);
        //        CGContextStrokePath(context);
        //
        //        CGContextMoveToPoint(context, self.view.center.x+(self.view.center.x/2), 0);
        //        CGContextAddLineToPoint(context, self.view.center.x+(self.view.center.x/2), self.view.frame.size.height);
        //        CGContextStrokePath(context);
        //
        //        CGContextMoveToPoint(context, 0, self.view.center.y);
        //        CGContextAddLineToPoint(context, self.view.frame.size.width, self.view.frame.size.height/2);
        //        CGContextStrokePath(context);
        //
        //        CGContextMoveToPoint(context, 0, self.view.frame.size.height/4);
        //        CGContextAddLineToPoint(context, self.view.frame.size.width, self.view.frame.size.height/4);
        //        CGContextStrokePath(context);
        //
        //        CGContextMoveToPoint(context, 0, self.view.frame.size.height/4*3);
        //        CGContextAddLineToPoint(context, self.view.frame.size.width, self.view.frame.size.height/4*3);
        //        CGContextStrokePath(context);
        //
        //        CGColorSpaceRelease(colorspace);
        //        CGColorRelease(color);
        
        
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
		[self teardownAVCapture];
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

- (void)teardownAVCapture
{
	//videoDataOutput = nil;
    //videoDataOutputQueue = nil;
	//[videoDataOutput release];
    //[videoDataOutputQueue release];
    AVCaptureSession * currentSession  = previewLayer.session;
    if (currentSession !=nil) {
        [currentSession stopRunning];
    }
    
	//[stillImageOutput removeObserver:self forKeyPath:@"isCapturingStillImage"];
	//[stillImageOutput release];
	//stillImageOutput = nil;
	[previewLayer removeFromSuperlayer];
	//[previewLayer release];
}

#pragma mark Location/Orientation Init

//allocates the location object and sets some parameters
- (void)setupLocationManager
{
    fprintf(stderr, "\nsetupLocationManager");
    
    locationMeasurements = [[NSMutableArray alloc] init];
    
    // Create the manager object
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    
    // This is the most important property to set for the manager. It ultimately determines how the manager will
    // attempt to acquire location and thus, the amount of power that will be consumed.
    locationManager.desiredAccuracy = 1.0;
    
    // When "tracking" the user, the distance filter can be used to control the frequency with which location measurements
    // are delivered by the manager. If the change in distance is less than the filter, a location will not be delivered.
    locationManager.distanceFilter = 0.1;
}

- (void)startUpdatingLocation
{
    // Once configured, the location manager must be "started".
    
    fprintf(stderr, "\nstartUpdatingLocation");
    [locationManager startUpdatingLocation];
}

/*
 * We want to get and store a location measurement that meets the desired accuracy. For this example, we are
 *      going to use horizontal accuracy as the deciding factor. In other cases, you may wish to use vertical
 *      accuracy, or both together.
 */
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    fprintf(stderr, "\ndidUpdateToLocation");
    // test that the horizontal accuracy does not indicate an invalid measurement
    if (newLocation.horizontalAccuracy < 0)
    {
        fprintf(stderr, "\nInvalid measurement (%f)", newLocation.horizontalAccuracy);
        return;
    }
    
    // test the age of the location measurement to determine if the measurement is cached
    // in most cases you will not want to rely on cached measurements
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge > 5.0)
    {
        fprintf(stderr, "\nlocation age too old (%f)", locationAge);
        return;
    }
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSLog(@"\n\nAdding new location  with date: %@ \nAnd Location: %f, %f, %f", [dateFormat stringFromDate:newLocation.timestamp], newLocation.coordinate.latitude, newLocation.coordinate.longitude, newLocation.altitude);
    
    // store all of the measurements, just so we can see what kind of data we might receive
    [locationMeasurements addObject:newLocation];
    
    while ([locationMeasurements count] > 1)
    {
        [locationMeasurements removeObjectAtIndex:0];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    // The location "unknown" error simply means the manager is currently unable to get the location.
    if ([error code] != kCLErrorLocationUnknown)
    {
        [self stopUpdatingLocation];
        [self stopDeviceMotion];
    }
}

- (void)stopUpdatingLocation;
{
    fprintf(stderr, "\nstopUpdatingLocation");
    [locationManager stopUpdatingLocation];
    
}

//starts the motion manager and sets an update interval
- (void)startDeviceMotion
{
	motionManager = [[CMMotionManager alloc] init];
	
	// Tell CoreMotion to show the compass calibration HUD when required to provide true north-referenced attitude
	motionManager.showsDeviceMovementDisplay = YES;
    motionManager.deviceMotionUpdateInterval = 1.0 / 60.0;
	
	// New in iOS 5.0: Attitude that is referenced to true north
	[motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXTrueNorthZVertical];
}

- (void)stopDeviceMotion
{
	[motionManager stopDeviceMotionUpdates];
	motionManager = nil;
}

#pragma mark - UI Actions

- (IBAction)CloseCamera:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)TakePicture:(id)sender {
    //make fake image for now
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
                 // code here
                 CFDictionaryRef metaDict = CMCopyDictionaryOfAttachments(NULL, imageDataSampleBuffer, kCMAttachmentMode_ShouldPropagate);
                 
                 //save picture to photo album/locally
                 NSData *jpeg = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                 UIImage *theimg = [UIImage imageWithData:jpeg];
                 UIImageWriteToSavedPhotosAlbum(theimg , nil, nil, nil);
                 capturedImage = theimg;
                 
                 CFMutableDictionaryRef mutable = CFDictionaryCreateMutableCopy(NULL, 0, metaDict);
                 NSMutableDictionary *xml = [[NSMutableDictionary alloc] init];
                 
                 // Create formatted date
                 NSTimeZone      *timeZone   = [NSTimeZone timeZoneWithName:@"UTC"];
                 NSDateFormatter *formatter  = [[NSDateFormatter alloc] init];
                 [formatter setTimeZone:timeZone];
                 [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
                 
                 NSMutableDictionary *GPSDictionary;
                 NSString *timestampstr = nil;
                 
                 if ([locationMeasurements count] > 0)
                 {
                     CLLocation *loc = [locationMeasurements objectAtIndex:([locationMeasurements count] - 1)];
                     
                     //fprintf(stderr, "\ntimestamp: %s", [[formatter stringFromDate:loc.timestamp] UTF8String]);
                     
                     // Create GPS Dictionary
                     GPSDictionary = [[NSMutableDictionary alloc] init];
                     [GPSDictionary setValue:[NSNumber numberWithFloat:fabs(loc.coordinate.latitude)] forKey:(NSString *)kCGImagePropertyGPSLatitude];
                     [GPSDictionary setValue:((loc.coordinate.latitude >= 0) ? @"N" : @"S") forKey:(NSString *)kCGImagePropertyGPSLatitudeRef];
                     [GPSDictionary setValue:[NSNumber numberWithFloat:fabs(loc.coordinate.longitude)] forKey:(NSString *)kCGImagePropertyGPSLongitude];
                     [GPSDictionary setValue:((loc.coordinate.longitude >= 0) ? @"E" : @"W") forKey:(NSString *)kCGImagePropertyGPSLongitudeRef];
                     [GPSDictionary setValue:[formatter stringFromDate:[loc timestamp]] forKey:(NSString *)kCGImagePropertyGPSDateStamp];
                     [GPSDictionary setValue:[NSNumber numberWithFloat:fabs(loc.altitude)] forKey:(NSString *)kCGImagePropertyGPSAltitude];
                     
                     [formatter setDateFormat:@"YYYYMMddHHmmssSS"];
                     //timestampstr = [formatter stringFromDate:loc.timestamp];
                     timestampstr = [formatter stringFromDate:[[NSDate alloc] init]];
                 }
                 else
                 {
                     fprintf(stderr, "\nNo location data to store with image");
                     GPSDictionary = [[NSMutableDictionary alloc] init];
                 }
                 
                 CFDictionarySetValue(mutable, kCGImagePropertyGPSDictionary, (void *)GPSDictionary);
                 
                 // Add GPSDictionary to Position Section of XML
                 [xml setValue:GPSDictionary forKey:(NSString *)@"Position"];
                 
                 NSMutableDictionary *EXIFDictionary = (NSMutableDictionary*)CFDictionaryGetValue(mutable, kCGImagePropertyExifDictionary);
                 //NSMutableDictionary *EXIFAuxDictionary = (NSMutableDictionary*)CFDictionaryGetValue(mutable, kCGImagePropertyExifAuxDictionary);
                 
                 // grab motion
                 CMAttitude *att = motionManager.deviceMotion.attitude;
                 
                 CMRotationMatrix m = att.rotationMatrix;
                 //GLKMatrix4 attMat = GLKMatrix4Make(m.m11, m.m12, m.m13, 0, m.m21, m.m22, m.m23, 0, m.m31, m.m32, m.m33, 0, 0, 0, 0, 1);
                 
                 // Orientation Section
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
                 
                 CFDictionarySetValue(mutable, kCGImagePropertyExifDictionary, (void *)EXIFDictionary);
                 [xml setValue:OrientDictionary forKey:(NSString *)@"Orientation"];
                 
                 // Device Section
                 NSMutableDictionary *DeviceDictionary = [[NSMutableDictionary alloc] init];
                 
                 NSUUID *duid = [[UIDevice currentDevice] identifierForVendor];
                 NSString *model = [[UIDevice currentDevice] model];
                 [DeviceDictionary setValue:[duid UUIDString] forKey:(NSString *)@"DeviceID"];
                 [DeviceDictionary setValue:model forKey:(NSString *)@"Model"];
                 [DeviceDictionary setValue:(isUsingFrontFacingCamera?@"Front":@"Back") forKey:(NSString *)@"Camera"];
                 [DeviceDictionary setValue:NSStringFromUIInterfaceOrientation([UIApplication sharedApplication].statusBarOrientation) forKey:@"Orientation"];
                 [xml setValue:DeviceDictionary forKey:(NSString *)@"Device"];
                 
                 // Image Section
                 NSMutableDictionary *ImageDictionary = [[NSMutableDictionary alloc] init];
                 
                 [ImageDictionary setValue:[[NSDate alloc] init] forKey:(NSString *)@"TimeStamp"];
                 [ImageDictionary setValue:@"SelectedCategory" forKey:(NSString *)@"Category"];
                 [ImageDictionary setValue:@"Arbitrary Description, optionally containing #tags or @userlinks" forKey:(NSString *)@"Description"];
                 
                 [xml setValue:ImageDictionary forKey:(NSString *)@"Image"];
                 
                 
                 // write the file with exif data
                 CGImageSourceRef  source ;
                 source = CGImageSourceCreateWithData((__bridge CFDataRef)jpeg, NULL);
                 
                 CFStringRef UTI = CGImageSourceGetType(source); //this is the type of image (e.g., public.jpeg)
                 
                 //this will be the data CGImageDestinationRef will write into
                 NSMutableData *dest_data = [NSMutableData data];
                 
                 CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)dest_data,UTI,1,NULL);
                 
                 if(!destination)
                 {
                     NSLog(@"***Could not create image destination ***");
                 }
                 
                 //add the image contained in the image source to the destination, overidding the old metadata with our modified metadata
                 CGImageDestinationAddImageFromSource(destination,source,0, (CFDictionaryRef) mutable);
                 
                 //tell the destination to write the image data and metadata into our data object.
                 //It will return false if something goes wrong
                 BOOL success = NO;
                 success = CGImageDestinationFinalize(destination);
                 
                 if(!success)
                 {
                     NSLog(@"***Could not create data from image destination ***");
                 }
                 
                 //now we have the data ready to go, so do whatever you want with it
                 //here we just write it to disk
                 
                 NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                 NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
                 NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"ImagesFolder"];
                 
                 NSError *error;
                 if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath])
                 {
                     [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error]; //Create folder
                 }
                 
                 //add our image to the path
                 NSString *fullPath = [dataPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", timestampstr]];
                 [dest_data writeToFile:fullPath atomically:YES];
                 
                 // build the metadata file...
                 NSString *fullPathMeta = [dataPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.xml", timestampstr]];
                 
                 [xml writeToFile:fullPathMeta atomically:YES];
                 
                 //cleanup
                 CFRelease(destination);
                 CFRelease(source);
                 
                 //UI Updates
                 [self pauseAVCapture];
                 [imageToolbar setHidden:NO];
                 [cameraButton setHidden:YES];
                 
             }
         }];
}

- (IBAction)RetakePictureAction:(id)sender {
    [self restartAVCapture];
    [imageToolbar setHidden:YES];
    [cameraButton setHidden:NO];
}

- (IBAction)AcceptPictureAction:(id)sender {
    
    //Stop motion/location services
    [self teardownAVCapture];
    [self stopDeviceMotion];
    [self stopUpdatingLocation];
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
        // Get reference to the destination view controller
        FLuxImageAnnotationViewController *vc = [segue destinationViewController];
        
        // Set the captured image
        [vc setCapturedImage:capturedImage];
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
