//
//  FluxImageCaptureViewController.m
//  Flux
//
//  Created by Kei Turner on 2013-10-07.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxImageCaptureViewController.h"
#import "FluxOpenGLViewController.h"
#import "FluxScanViewController.h"


NSString* const FluxImageCaptureDidPop = @"FluxImageCaptureDidPop";
NSString* const FluxImageCaptureDidPush = @"FluxImageCaptureDidPush";
NSString* const FluxImageCaptureDidCaptureImage = @"FluxImageCaptureDidCaptureImage";
NSString* const FluxImageCaptureDidUndoCapture = @"FluxImageCaptureDidUndoCapture";

@interface FluxImageCaptureViewController ()

@end

@implementation FluxImageCaptureViewController

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
    [super viewDidLoad];
    [self.view setAlpha:0.0];
    [self.view setHidden:YES];
    
    blackView = [[UIView alloc]initWithFrame:imageCaptureSquareView.frame];
    [blackView setBackgroundColor:[UIColor blackColor]];
    [blackView setAlpha:0.0];
    [blackView setHidden:YES];
    [self.view addSubview:blackView];
    
    snapshotImageView = [[UIImageView alloc]initWithFrame:self.view.bounds];
    [snapshotImageView setAlpha:0.0];
    [snapshotImageView setBackgroundColor:[UIColor blackColor]];
    [self.view insertSubview:snapshotImageView belowSubview:topContainerView];
    
    capturedImageObjects = [[NSMutableArray alloc]init];
    capturedImages = [[NSMutableArray alloc]init];
    
    [self setupAVCapture];
    
    self.screenName = @"Image Capture View";
    
    [imageCountLabel setFont:[UIFont fontWithName:@"Akkurat" size:imageCountLabel.font.pointSize]];
    [photosLabel setFont:[UIFont fontWithName:@"Akkurat" size:photosLabel.font.pointSize]];
    [undoButton.titleLabel setFont:[UIFont fontWithName:@"Akkurat-Bold" size:undoButton.titleLabel.font.pointSize]];
    [approveButton.titleLabel setFont:[UIFont fontWithName:@"Akkurat-Bold" size:approveButton.titleLabel.font.pointSize]];
    
    motionManager = [FluxMotionManagerSingleton sharedManager];
    locationManager = [FluxLocationServicesSingleton sharedManager];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setHidden:(BOOL)hidden{
    if (!hidden) {
        [self.view setHidden:NO];
        [approveButton setHidden:YES];
        [undoButton setHidden:YES];
        [UIView animateWithDuration:0.3f
                         animations:^{
                             [self.view setAlpha:1.0];
                         }
                         completion:nil];
        [[self.view layer] insertSublayer:previewLayer atIndex:0];
    }
    else{
        [UIView animateWithDuration:0.3f
             animations:^{
                 [self.view setAlpha:0.0];
             }
             completion:^(BOOL finished){
                 [self.view setHidden:YES];
             }];
    }
}

- (IBAction)undoButtonAction:(id)sender {
    NSDictionary *userInfoDict = [[NSDictionary alloc]
                                  initWithObjectsAndKeys:[(FluxScanImageObject*)[capturedImageObjects lastObject]localID], @"localID",nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:FluxImageCaptureDidUndoCapture
                                                        object:self userInfo:userInfoDict];
    [capturedImageObjects removeLastObject];
    [capturedImages removeLastObject];
    [imageCountLabel setText:[NSString stringWithFormat:@"%i",capturedImageObjects.count]];
    if (capturedImageObjects.count == 0) {
        [approveButton setHidden:YES];
        [undoButton setHidden:YES];
    }
}

- (IBAction)closeButtonAction:(id)sender {
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    if (self.isSnapshot) {
        [bottomContainerView setHidden:NO];
        [topContainerView setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.5]];
        [topGradientView setHidden:YES];
        [approveButton setHidden:YES];
        [snapshotImageView setAlpha:0.0];
    }
    [self setHidden:YES];
    [capturedImageObjects removeAllObjects];
    [capturedImages removeAllObjects];
    [imageCountLabel setText:[NSString stringWithFormat:@"%i",capturedImageObjects.count]];
    [[NSNotificationCenter defaultCenter] postNotificationName:FluxImageCaptureDidPop
                                                        object:self userInfo:nil];
}

- (void)ImageAnnotationViewDidPop:(FluxImageAnnotationViewController *)imageAnnotationsViewController{
    [self closeButtonAction:nil];
}

- (void)ImageAnnotationViewDidPop:(FluxImageAnnotationViewController *)imageAnnotationsViewController andApproveWithChanges:(NSDictionary *)changes
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [snapshotImageView setAlpha:0.0];
    
    if ([changes objectForKey:@"removedImages"]) {
        NSIndexSet*removedImages = [changes objectForKey:@"removedImages"];
        [capturedImageObjects removeObjectsAtIndexes:removedImages];
        [capturedImages removeObjectsAtIndexes:removedImages];
    }
    for (int i = 0; i < [capturedImageObjects count]; i++)
    {
        FluxScanImageObject *imgObject = [capturedImageObjects objectAtIndex:i];
        UIImage *img = [capturedImages objectAtIndex:i];
        
        [imgObject setCategoryID:0];
        [imgObject setDescriptionString:[changes objectForKey:@"annotation"]];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        BOOL savelocally = [[defaults objectForKey:@"Save Pictures"]boolValue];
        if (savelocally)
        {
            UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil);
        }
    }
    NSDictionary *userInfoDict = [[NSDictionary alloc]
                                  initWithObjectsAndKeys:capturedImageObjects, @"capturedImageObjects", capturedImages, @"capturedImages", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:FluxImageCaptureDidPop
                                                        object:self userInfo:userInfoDict];
    [self setHidden:YES];
    [capturedImageObjects removeAllObjects];
    [capturedImages removeAllObjects];
    [imageCountLabel setText:[NSString stringWithFormat:@"%i",capturedImageObjects.count]];
}

- (IBAction)approveImageAction:(id)sender
{        
    
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    UINavigationController*tmp = segue.destinationViewController;
    FluxImageAnnotationViewController* annotationsVC = (FluxImageAnnotationViewController*)tmp.topViewController;
    if (self.isSnapshot) {
        [annotationsVC prepareSnapShotViewWithImage:snapshotImage withLocation:locationManager.subadministativearea andDate:[NSDate date]];
    }
    else{
        UIImage*bgImage = [(FluxOpenGLViewController*)self.parentViewController snapshot:self.parentViewController.view];
        [annotationsVC prepareViewWithBGImage:bgImage andCapturedImages:capturedImages withLocation:locationManager.subadministativearea andDate:[(FluxScanImageObject*)[capturedImageObjects objectAtIndex:0]timestamp]];
    }
    [annotationsVC setDelegate:self];
}



#pragma mark - Camera Methods

- (void)setupAVCapture
{
    AVCaptureBackgroundQueue = dispatch_queue_create("is.smlr.flux.bgqueue", NULL);
    cameraManager = [FluxAVCameraSingleton sharedCamera];
    previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:cameraManager.session];
    [previewLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [previewLayer setFrame:self.view.bounds];
}

- (void)takePicture{
    
    [(FluxScanViewController*)self.parentViewController.parentViewController setCameraButtonEnabled:NO];
    //google analytics
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"     // Event category (required)
                                                          action:@"action"  // Event action (required)
                                                           label:@"take picture"          // Event label
                                                           value:nil] build]];    // Event value
    
    __block NSDate *startTime = [NSDate date];
    
    
    //black Animation
    [self showFlash:[UIColor blackColor]];
    
    // Collect position and orientation information prior to copying image
    CLLocation *location = locationManager.rawlocation;
    //CLLocation *bestlocation = locationManager.location;
    CMAttitude *att = motionManager.attitude;
    CLLocationDirection heading = locationManager.heading;
    
    __block NSDate *endTime = [NSDate date];
    __block NSTimeInterval executionTime = [endTime timeIntervalSinceDate:startTime];
    NSLog(@"Execution Time (1): %f", executionTime);
    
    // Find out the current orientation and tell the still image output.
	AVCaptureConnection *stillImageConnection = [cameraManager.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
	UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
	AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForDeviceOrientation:curDeviceOrientation];
	[stillImageConnection setVideoOrientation:avcaptureOrientation];
	[stillImageConnection setVideoScaleAndCropFactor:1.0];
	[cameraManager.stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection
                                                                completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error)
     {
         if (error)
         {
             UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Image Capture Failed"]
                                                                 message:[error localizedDescription]
                                                                delegate:nil
                                                       cancelButtonTitle:@"Dismiss"
                                                       otherButtonTitles:nil];
             [alertView show];
         }
         else
         {
             endTime = [NSDate date];
             executionTime = [endTime timeIntervalSinceDate:startTime];
             NSLog(@"Execution Time (2): %f", executionTime);
             
             NSData *jpeg = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
             capturedImage = [UIImage imageWithData:jpeg];
             
             NSDateFormatter *outDateFormat = [[NSDateFormatter alloc] init];
             [outDateFormat setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
             outDateFormat.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
             NSString *dateString = [outDateFormat stringFromDate:startTime];
             
             int userID = 1;
             int cameraID = 1;
             int categoryID = 1;
             

             
            FluxScanImageObject*capturedImageObject = [[FluxScanImageObject alloc]initWithUserID:userID
                                                            atTimestampString:dateString
                                                                  andCameraID:cameraID
                                                                andCategoryID:categoryID
                                                        withDescriptionString:@""
                                                                  andlatitude:location.coordinate.latitude
                                                                 andlongitude:location.coordinate.longitude
                                                                  andaltitude:location.altitude
                                                                   andHeading:heading
                                                                       andYaw:att.yaw
                                                                     andPitch:att.pitch
                                                                      andRoll:att.roll
                                                                        andQW:att.quaternion.w
                                                                        andQX:att.quaternion.x
                                                                        andQY:att.quaternion.y
                                                                        andQZ:att.quaternion.z
                                                                        andHorizAccuracy:location.horizontalAccuracy
                                                                        andVertAccuracy:location.verticalAccuracy];
             
#warning We should probably consolidate all of the time variable. Probably create the object with the NSDate object.
             // Also set the internal timestamp variable to match the string representation
             [capturedImageObject setTimestamp:startTime];
             
             //set estimated location
             if(locationManager.kflocation.valid ==1)
             {
                 capturedImageObject.location_confidence =1.0;
                 capturedImageObject.ecefX = locationManager.kflocation.x;
                 capturedImageObject.ecefY = locationManager.kflocation.y;
                 capturedImageObject.ecefZ = locationManager.kflocation.z;
                            
             }
             
             
             [self saveImageObject:capturedImageObject];
             [self incrementCountLabel];
             
             //UI updates
             [approveButton setHidden:NO];
             [undoButton setHidden:NO];
         }
     }];
}

-(void)presentSnapshot:(UIImage *)snapshot{
    self.isSnapshot = YES;
    snapshotImage = snapshot;
    [snapshotImageView setImage:snapshot];
    [self showFlash:[UIColor whiteColor]];
    [topGradientView setHidden:NO];
    [bottomContainerView setHidden:YES];
    [topContainerView setBackgroundColor:[UIColor clearColor]];
    [approveButton setHidden:NO];
   
}

- (void)showFlash:(UIColor*)color{
    [blackView setHidden:NO];
    [blackView setBackgroundColor:color];
    [UIView animateWithDuration:0.09 animations:^{
        [blackView setAlpha:0.9];
    } completion:^(BOOL finished) {
        if (self.isSnapshot) {
            [UIView animateWithDuration:0.09 animations:^{
                [snapshotImageView setAlpha:1.0];
                [blackView setAlpha:0.0];
            } completion:^(BOOL finished) {
                [blackView setHidden:YES];
            }];
        }
        else{
            [UIView animateWithDuration:0.09 animations:^{
                [blackView setAlpha:0.0];
            } completion:^(BOOL finished) {
                [blackView setHidden:YES];
            }];
        }
    }];
}

- (void)saveImageObject:(FluxScanImageObject*)newImageObject
{
    // Generate a string image id for local use
    NSString *localID = [newImageObject generateUniqueStringID];
    [newImageObject setLocalID:localID];
    
    // Set the server-side image id to a negative value until server returns actual
    [newImageObject setImageID:-1];
    
    // HACK
    
    // spin the image CW by 90deg. prior to dumping into the cache;
    CGSize size = capturedImage.size;
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    //    CGContextTranslateCTM( context, 0.5f * size.width, 0.5f * size.height ) ;
    //    //CGContextRotateCTM( context, M_PI_2) ;
    //    [capturedImage drawInRect:(CGRect){ { -size.width * 0.5f, -size.height * 0.5f }, size } ] ;
    
    [capturedImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    UIImage *spunImage = UIGraphicsGetImageFromCurrentImageContext();
    CGContextRestoreGState(context);
    UIGraphicsEndImageContext();
    
    // END HACK

    if ([capturedImageObjects count]==0)
    {
        [previewLayer removeFromSuperlayer];
    }

    [self.fluxDisplayManager.fluxDataManager addCameraDataToStore:newImageObject withImage:spunImage];

    [capturedImageObjects addObject:newImageObject];
    [capturedImages addObject:spunImage];
    
    NSDictionary *userInfoDict = [[NSDictionary alloc]
                                  initWithObjectsAndKeys:localID, @"localID", spunImage, @"image", newImageObject, @"imageObject", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:FluxImageCaptureDidCaptureImage
                                                        object:self userInfo:userInfoDict];

}

// utility routing used during image capture to set up capture orientation
- (AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
    AVCaptureVideoOrientation result = AVCaptureVideoOrientationPortrait;
    
	if (deviceOrientation == AVCaptureVideoOrientationPortraitUpsideDown )
    {
		result = AVCaptureVideoOrientationPortraitUpsideDown;
    }
	else if (deviceOrientation == AVCaptureVideoOrientationLandscapeLeft )
    {
		result = AVCaptureVideoOrientationLandscapeRight;
    }
	else if ( deviceOrientation == UIDeviceOrientationLandscapeRight )
    {
		result = AVCaptureVideoOrientationLandscapeLeft;
    }
	return result;
}

- (void)incrementCountLabel{
    CGPoint center = imageCountLabel.center;
    imageCountLabel.transform = CGAffineTransformMakeScale(1.5, 1.5);
    [imageCountLabel setText:[NSString stringWithFormat:@"%i",capturedImageObjects.count]];
    [UIView animateWithDuration:0.3 animations:^{
        imageCountLabel.transform = CGAffineTransformMakeScale(1, 1);
        [imageCountLabel setCenter:center];
    } completion:nil];
}


- (void) dumpViews:(UIView*) view label:(NSString *) text indent:(NSString*) indent{
    Class cl = [view class];
    NSString *classDescription = [cl description];
    while ([cl superclass]) {
        cl = [cl superclass];
        classDescription = [classDescription stringByAppendingFormat:@":%@", [cl description]];
    }
    
    if ([text compare:@""] == NSOrderedSame) {
        NSLog(@"%@ %@, Alpha:%.2f", classDescription, NSStringFromCGRect(view.frame),view.alpha);
    } else {
        NSLog(@"%@ %@ %@, Alpha:%.2f", text, classDescription, NSStringFromCGRect(view.frame),view.alpha);
    }
    for (NSUInteger i = 0; i < [view.subviews count]; i++)
    {
        UIView *subView = [view.subviews objectAtIndex:i];
        NSString *newIndent = [[NSString alloc] initWithFormat:@"  %@", indent];
        NSString *msg = [[NSString alloc] initWithFormat:@"%@%d:", newIndent, i];
        [self dumpViews:subView label:msg indent:newIndent];
    }
}

- (void) dumpViews:(UIView*) view {
    [self dumpViews:view label:@"" indent:@""];
}

@end
