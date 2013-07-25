//
//  SMLRcamViewController.m
//  SMLRcam
//
//  Created by Denis Delorme on 7/4/13.
//  Copyright (c) 2013 Denis Delorme. All rights reserved.
//

#import "SMLRcamViewController.h"
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <AssertMacros.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreMotion/CMAttitude.h>
#import <GLKit/GLKMath.h>


#pragma mark-

static CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};
static CGFloat RadiansToDegrees(CGFloat radians) {return radians * 180.0 / M_PI;};

// used for KVO observation of the @"capturingStillImage" property to perform flash bulb animation
static const NSString *AVCaptureStillImageIsCapturingStillImageContext = @"AVCaptureStillImageIsCapturingStillImageContext";


@interface SMLRcamViewController ()
{
    AVCaptureDevice *device;
    NSTimer         *updateTimer;

}
- (void)setupAVCapture;
- (void)teardownAVCapture;
//- (void)drawFaceBoxesForFeatures:(NSArray *)features forVideoBox:(CGRect)clap orientation:(UIDeviceOrientation)orientation;
- (void)setFocusMode:(AVCaptureFocusMode)mode;
- (void)updateCurrentTime;
- (void)setupTimer;

@end


@implementation SMLRcamViewController


 - (void)setFocusMode:(AVCaptureFocusMode)mode
 {
     BOOL locked = [device lockForConfiguration:nil];
     if (locked)
     {
         device.focusMode = mode;
         [device unlockForConfiguration];
     }
 }


- (void)setupAVCapture
{
	NSError *error = nil;
	
	AVCaptureSession *session = [AVCaptureSession new];
    [session setSessionPreset:AVCaptureSessionPresetPhoto]; // full resolution photo...
	
    // Select a video device, make an input
    device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

    [self setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
 	
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];

    if (error == nil)
    {
        isUsingFrontFacingCamera = NO;
        if ( [session canAddInput:deviceInput] )
            [session addInput:deviceInput];
        
        // Make a still image output
        stillImageOutput = [AVCaptureStillImageOutput new];
        [stillImageOutput addObserver:self forKeyPath:@"capturingStillImage" options:NSKeyValueObservingOptionNew context:(__bridge void *)(AVCaptureStillImageIsCapturingStillImageContext)];
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
        
        if ( [session canAddOutput:videoDataOutput] )
            [session addOutput:videoDataOutput];
        [[videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:NO];
        
        effectiveScale = 1.0;
        previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
        [previewLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
        [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
        CALayer *rootLayer = [previewView layer];
        [rootLayer setMasksToBounds:YES];
        [previewLayer setFrame:[rootLayer bounds]];
        [rootLayer addSublayer:previewLayer];
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
		[self teardownAVCapture];
	}
}

// clean up capture setup
- (void)teardownAVCapture
{
	//videoDataOutput = nil;
    //videoDataOutputQueue = nil;
	//[videoDataOutput release];
    //[videoDataOutputQueue release];

	[stillImageOutput removeObserver:self forKeyPath:@"isCapturingStillImage"];
	//[stillImageOutput release];
	//stillImageOutput = nil;
	[previewLayer removeFromSuperlayer];
	//[previewLayer release];
}

// perform a flash bulb animation using KVO to monitor the value of the capturingStillImage property of the AVCaptureStillImageOutput class
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ( context == (__bridge void *)(AVCaptureStillImageIsCapturingStillImageContext) ) {
		BOOL isCapturingStillImage = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
		
		if ( isCapturingStillImage ) {
			// do flash bulb like animation
			flashView = [[UIView alloc] initWithFrame:[previewView frame]];
			[flashView setBackgroundColor:[UIColor whiteColor]];
			[flashView setAlpha:0.f];
			[[[self view] window] addSubview:flashView];
			
			[UIView animateWithDuration:.4f
							 animations:^{
								 [flashView setAlpha:1.f];
							 }
			 ];
		}
		else {
			[UIView animateWithDuration:.4f
							 animations:^{
								 [flashView setAlpha:0.f];
							 }
							 completion:^(BOOL finished){
								 [flashView removeFromSuperview];
                                 //[flashView release];
								 flashView = nil;
							 }
			 ];
		}
	}
}


// utility routing used during image capture to set up capture orientation
- (AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
	AVCaptureVideoOrientation result = deviceOrientation;
	if ( deviceOrientation == UIDeviceOrientationLandscapeLeft )
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


// main action method to take a still image -- if face detection has been turned on and a face has been detected
// the square overlay will be composited on top of the captured image and saved to the camera roll
- (IBAction)takePicture:(id)sender
{
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
                 
                 // The gps info goes into the gps metadata part
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
             [xml setValue:DeviceDictionary forKey:(NSString *)@"Device"];
             
             // Image Section
             NSMutableDictionary *ImageDictionary = [[NSMutableDictionary alloc] init];
             
             [ImageDictionary setValue:[[NSDate alloc] init] forKey:(NSString *)@"TimeStamp"];
             [ImageDictionary setValue:@"SelectedCategory" forKey:(NSString *)@"Category"];
             [ImageDictionary setValue:@"Arbitrary Description, optionally containing #tags or @userlinks" forKey:(NSString *)@"Description"];
             
             [xml setValue:ImageDictionary forKey:(NSString *)@"Image"];
             

             NSData *jpeg = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
             
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
         }
     }
     ];
}

// turn on/off face detection
- (IBAction)toggleAutoFocus:(id)sender
{
    switch([sender isOn])
    {
        case YES:
            [self setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            break;
        case NO:
            [self setFocusMode:AVCaptureFocusModeLocked];
            break;
    }
}

/*
// turn on/off face detection
- (IBAction)toggleFaceDetect:(id)sender
{
	detectFaces = [(UISwitch *)sender isOn];
	[[videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:detectFaces];
	if (!detectFaces) {
		dispatch_async(dispatch_get_main_queue(), ^(void) {
			// clear out any squares currently displaying.
			[self drawFaceBoxesForFeatures:[NSArray array] forVideoBox:CGRectZero orientation:UIDeviceOrientationPortrait];
		});
	}
}
*/

/*
//ncb-preview
// find where the video box is positioned within the preview layer based on the video size and gravity
+ (CGRect)videoPreviewBoxForGravity:(NSString *)gravity frameSize:(CGSize)frameSize apertureSize:(CGSize)apertureSize
{
    CGFloat apertureRatio = apertureSize.height / apertureSize.width;
    CGFloat viewRatio = frameSize.width / frameSize.height;
    
    CGSize size = CGSizeZero;
    if ([gravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        if (viewRatio > apertureRatio) {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        } else {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
        if (viewRatio > apertureRatio) {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        } else {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResize]) {
        size.width = frameSize.width;
        size.height = frameSize.height;
    }
	
	CGRect videoBox;
	videoBox.size = size;
	if (size.width < frameSize.width)
		videoBox.origin.x = (frameSize.width - size.width) / 2;
	else
		videoBox.origin.x = (size.width - frameSize.width) / 2;
	
	if ( size.height < frameSize.height )
		videoBox.origin.y = (frameSize.height - size.height) / 2;
	else
		videoBox.origin.y = (size.height - frameSize.height) / 2;
    
	return videoBox;
}

//ncb-preview
// called asynchronously as the capture output is capturing sample buffers, this method asks the face detector (if on)
// to detect features and for each draw the red square in a layer and set appropriate orientation
- (void)drawFaceBoxesForFeatures:(NSArray *)features forVideoBox:(CGRect)clap orientation:(UIDeviceOrientation)orientation
{
	NSArray *sublayers = [NSArray arrayWithArray:[previewLayer sublayers]];
	NSInteger sublayersCount = [sublayers count], currentSublayer = 0;
	NSInteger featuresCount = [features count], currentFeature = 0;
	
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	
	// hide all the face layers
	for ( CALayer *layer in sublayers ) {
		if ( [[layer name] isEqualToString:@"FaceLayer"] )
			[layer setHidden:YES];
	}
	
	if ( featuresCount == 0 || !detectFaces ) {
		[CATransaction commit];
		return; // early bail.
	}
    
	CGSize parentFrameSize = [previewView frame].size;
	NSString *gravity = [previewLayer videoGravity];
	BOOL isMirrored = previewLayer.connection.videoMirrored;
	CGRect previewBox = [SMLRcamViewController videoPreviewBoxForGravity:gravity
                                                                 frameSize:parentFrameSize
                                                              apertureSize:clap.size];
	
	for ( CIFaceFeature *ff in features ) {
		// find the correct position for the square layer within the previewLayer
		// the feature box originates in the bottom left of the video frame.
		// (Bottom right if mirroring is turned on)
		CGRect faceRect = [ff bounds];
        
		// flip preview width and height
		CGFloat temp = faceRect.size.width;
		faceRect.size.width = faceRect.size.height;
		faceRect.size.height = temp;
		temp = faceRect.origin.x;
		faceRect.origin.x = faceRect.origin.y;
		faceRect.origin.y = temp;
		// scale coordinates so they fit in the preview box, which may be scaled
		CGFloat widthScaleBy = previewBox.size.width / clap.size.height;
		CGFloat heightScaleBy = previewBox.size.height / clap.size.width;
		faceRect.size.width *= widthScaleBy;
		faceRect.size.height *= heightScaleBy;
		faceRect.origin.x *= widthScaleBy;
		faceRect.origin.y *= heightScaleBy;
        
		if ( isMirrored )
			faceRect = CGRectOffset(faceRect, previewBox.origin.x + previewBox.size.width - faceRect.size.width - (faceRect.origin.x * 2), previewBox.origin.y);
		else
			faceRect = CGRectOffset(faceRect, previewBox.origin.x, previewBox.origin.y);
		
		CALayer *featureLayer = nil;
		
		// re-use an existing layer if possible
		while ( !featureLayer && (currentSublayer < sublayersCount) ) {
			CALayer *currentLayer = [sublayers objectAtIndex:currentSublayer++];
			if ( [[currentLayer name] isEqualToString:@"FaceLayer"] ) {
				featureLayer = currentLayer;
				[currentLayer setHidden:NO];
			}
		}
		
		// create a new one if necessary
		if ( !featureLayer ) {
			featureLayer = [CALayer new];
			[featureLayer setContents:(id)[square CGImage]];
			[featureLayer setName:@"FaceLayer"];
			[previewLayer addSublayer:featureLayer];
            //[featureLayer release];
		}
		[featureLayer setFrame:faceRect];
		
		switch (orientation) {
			case UIDeviceOrientationPortrait:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(0.))];
				break;
			case UIDeviceOrientationPortraitUpsideDown:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(180.))];
				break;
			case UIDeviceOrientationLandscapeLeft:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(90.))];
				break;
			case UIDeviceOrientationLandscapeRight:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(-90.))];
				break;
			case UIDeviceOrientationFaceUp:
			case UIDeviceOrientationFaceDown:
			default:
				break; // leave the layer in its last known orientation
		}
		currentFeature++;
	}
	
	[CATransaction commit];
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
	// got an image
	CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
	CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(__bridge NSDictionary *)attachments];
	if (attachments)
		CFRelease(attachments);
	NSDictionary *imageOptions = nil;
	UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
	int exifOrientation;
	
    / * kCGImagePropertyOrientation values
     The intended display orientation of the image. If present, this key is a CFNumber value with the same value as defined
     by the TIFF and EXIF specifications -- see enumeration of integer constants.
     The value specified where the origin (0,0) of the image is located. If not present, a value of 1 is assumed.
     
     used when calling featuresInImage: options: The value for this key is an integer NSNumber from 1..8 as found in kCGImagePropertyOrientation.
     If present, the detection will be done based on that orientation but the coordinates in the returned features will still be based on those of the image. * /
    
	enum {
		PHOTOS_EXIF_0ROW_TOP_0COL_LEFT			= 1, //   1  =  0th row is at the top, and 0th column is on the left (THE DEFAULT).
		PHOTOS_EXIF_0ROW_TOP_0COL_RIGHT			= 2, //   2  =  0th row is at the top, and 0th column is on the right.
		PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT      = 3, //   3  =  0th row is at the bottom, and 0th column is on the right.
		PHOTOS_EXIF_0ROW_BOTTOM_0COL_LEFT       = 4, //   4  =  0th row is at the bottom, and 0th column is on the left.
		PHOTOS_EXIF_0ROW_LEFT_0COL_TOP          = 5, //   5  =  0th row is on the left, and 0th column is the top.
		PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP         = 6, //   6  =  0th row is on the right, and 0th column is the top.
		PHOTOS_EXIF_0ROW_RIGHT_0COL_BOTTOM      = 7, //   7  =  0th row is on the right, and 0th column is the bottom.
		PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM       = 8  //   8  =  0th row is on the left, and 0th column is the bottom.
	};
	
	switch (curDeviceOrientation)
    {
        case UIDeviceOrientationPortraitUpsideDown:  // Device oriented vertically, home button on the top
			exifOrientation = PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM;
			break;
		case UIDeviceOrientationLandscapeLeft:       // Device oriented horizontally, home button on the right
			if (isUsingFrontFacingCamera)
				exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
			else
				exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
			break;
		case UIDeviceOrientationLandscapeRight:      // Device oriented horizontally, home button on the left
			if (isUsingFrontFacingCamera)
				exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
			else
				exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
			break;
		case UIDeviceOrientationPortrait:            // Device oriented vertically, home button on the bottom
		default:
			exifOrientation = PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP;
			break;
	}
    
	imageOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:exifOrientation] forKey:CIDetectorImageOrientation];
	NSArray *features = [faceDetector featuresInImage:ciImage options:imageOptions];
	//[ciImage release];
	
    // get the clean aperture
    // the clean aperture is a rectangle that defines the portion of the encoded pixel dimensions
    // that represents image data valid for display.
    CMFormatDescriptionRef fdesc = CMSampleBufferGetFormatDescription(sampleBuffer);
	CGRect clap = CMVideoFormatDescriptionGetCleanAperture(fdesc, false / *originIsTopLeft == false* /);
	
	dispatch_async(dispatch_get_main_queue(), ^(void) {
		[self drawFaceBoxesForFeatures:features forVideoBox:clap orientation:curDeviceOrientation];
	});
     
}
*/
/*
- (void)dealloc
{
	//[self teardownAVCapture];
	//[faceDetector release];
	//[square release];
	//[super dealloc];
}
 */

// use front/back camera
- (IBAction)switchCameras:(id)sender
{
	AVCaptureDevicePosition desiredPosition;
	if (isUsingFrontFacingCamera)
		desiredPosition = AVCaptureDevicePositionBack;
	else
		desiredPosition = AVCaptureDevicePositionFront;
	
	for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
		if ([d position] == desiredPosition) {
			[[previewLayer session] beginConfiguration];
			AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:nil];
			for (AVCaptureInput *oldInput in [[previewLayer session] inputs]) {
				[[previewLayer session] removeInput:oldInput];
			}
			[[previewLayer session] addInput:input];
			[[previewLayer session] commitConfiguration];
			break;
		}
	}
	isUsingFrontFacingCamera = !isUsingFrontFacingCamera;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - view lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // Do any additional setup after loading the view, typically from a nib.
    
	[self setupAVCapture];
//	//square = [[UIImage imageNamed:@"squarePNG"] retain];
//	square = [UIImage imageNamed:@"squarePNG"];
//	NSDictionary *detectorOptions = [[NSDictionary alloc] initWithObjectsAndKeys:CIDetectorAccuracyLow, CIDetectorAccuracy, nil];
//	//faceDetector = [[CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions] retain];
//	faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
//    //	[detectorOptions release];
    
    [self setupLocationManager];
    [self startUpdatingLocation];
    [self startDeviceMotion];
}

- (void)viewDidUnload
{
    
    [self stopUpdatingLocation];
    [self stopDeviceMotion];
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
	if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] ) {
		beginGestureScale = effectiveScale;
	}
	return YES;
}

// scale image depending on users pinch gesture
- (IBAction)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer
{
	BOOL allTouchesAreOnThePreviewLayer = YES;
	NSUInteger numTouches = [recognizer numberOfTouches], i;
	for ( i = 0; i < numTouches; ++i ) {
		CGPoint tlocation = [recognizer locationOfTouch:i inView:previewView];
		CGPoint convertedLocation = [previewLayer convertPoint:tlocation fromLayer:previewLayer.superlayer];
		if ( ! [previewLayer containsPoint:convertedLocation] ) {
			allTouchesAreOnThePreviewLayer = NO;
			break;
		}
	}
	
	if ( allTouchesAreOnThePreviewLayer ) {
		effectiveScale = beginGestureScale * recognizer.scale;
		if (effectiveScale < 1.0)
			effectiveScale = 1.0;
		CGFloat maxScaleAndCropFactor = [[stillImageOutput connectionWithMediaType:AVMediaTypeVideo] videoMaxScaleAndCropFactor];
		if (effectiveScale > maxScaleAndCropFactor)
			effectiveScale = maxScaleAndCropFactor;
		[CATransaction begin];
		[CATransaction setAnimationDuration:.025];
		[previewLayer setAffineTransform:CGAffineTransformMakeScale(effectiveScale, effectiveScale)];
		[CATransaction commit];
	}
}


#pragma mark Location Manager Interactions

/*
 * This method is invoked when the user hits "Done" in the setup view controller. The options chosen by the user are
 * passed in as a dictionary. The keys for this dictionary are declared in SetupViewController.h.
 */
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
    
    fprintf(stderr, "\nAdding new location (%f, %f, %f, %f)", [newLocation.timestamp  timeIntervalSinceReferenceDate], newLocation.coordinate.latitude, newLocation.coordinate.longitude, newLocation.altitude);
    
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

#pragma mark Motion Manager Interactions


- (void)startDeviceMotion
{
	motionManager = [[CMMotionManager alloc] init];
	
	// Tell CoreMotion to show the compass calibration HUD when required to provide true north-referenced attitude
	motionManager.showsDeviceMovementDisplay = YES;
    
	
    motionManager.deviceMotionUpdateInterval = 1.0 / 60.0;
	
	// New in iOS 5.0: Attitude that is referenced to true north
	[motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXTrueNorthZVertical];
    //[self setupTimer];    // call this to enable logging of current orientation at 4Hz. 
}

- (void)stopDeviceMotion
{
	[motionManager stopDeviceMotionUpdates];
	motionManager = nil;
}


- (void)updateCurrentTime
{
    // fetch current orientation and dump it out...
    // grab motion
    CMAttitude *att = motionManager.deviceMotion.attitude;
    fprintf(stderr, "\nOrientation (Y,P,R):(%f, %f, %f)", RadiansToDegrees(att.yaw), RadiansToDegrees(att.pitch), RadiansToDegrees(att.roll));
}

- (void)setupTimer
{
    
    if (updateTimer)
        [updateTimer invalidate];
    
    updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(updateCurrentTime) userInfo:nil repeats:YES];
}

@end



