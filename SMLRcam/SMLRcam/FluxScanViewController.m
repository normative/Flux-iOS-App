//
//  SMLRcamViewController.m
//  SMLRcam
//
//  Created by Kei Turner on 7/4/13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxScanViewController.h"

#import "UIViewController+MMDrawerController.h"
#import "FluxImageAnnotationViewController.h"
#import "FluxAnnotationTableViewCell.h"

#import <ImageIO/ImageIO.h>

@implementation FluxScanViewController

@synthesize imageDict,thumbView;

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

//called by annotationsTableview
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices
         didreturnImage:(UIImage *)image
             forImageID:(int)imageID
{
    NSNumber *objKey = [NSNumber numberWithInt: imageID];
    [[self.imageDict objectForKey:objKey] setContentImage:image];
    
    NSArray * arr = [self.imageDict allKeys];
    int index = [arr indexOfObject:objKey];
    [annotationsTableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:[NSIndexPath indexPathForRow:index inSection:0], nil] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - Motion Methods

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

#pragma mark - Drawer Methods

// Left Drawer
- (IBAction)showLeftDrawer:(id)sender {
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

// Right Drawer
- (IBAction)showRightDrawer:(id)sender {
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideRight animated:YES completion:nil];
}

#pragma mark - Annotations Feed Methods

//show list of images currently visible.
- (void)setupAnnotationsTableView{
    annotationsTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, headerView.frame.origin.y+headerView.frame.size.height+4, self.view.frame.size.width, self.view.frame.size.height-200)];
    [annotationsTableView setHidden:YES];
    [annotationsTableView setAlpha:0.0];
    
    //fade out the bottom of the feedView
    CAGradientLayer* maskLayer = [CAGradientLayer layer];
    NSObject*   transparent = (NSObject*) [[UIColor clearColor] CGColor];
    NSObject*   opaque = (NSObject*) [[UIColor blackColor] CGColor];
    [maskLayer setColors: [NSArray arrayWithObjects: opaque, opaque,opaque,opaque,transparent, nil]];
    maskLayer.locations = [NSArray arrayWithObjects:
                           [NSNumber numberWithFloat:0.0],
                           [NSNumber numberWithFloat:0.0],
                           [NSNumber numberWithFloat:0.0],
                           [NSNumber numberWithFloat:0.8],
                           [NSNumber numberWithFloat:1.0], nil];
    maskLayer.bounds = annotationsTableView.layer.bounds;
    maskLayer.anchorPoint = CGPointZero;
    annotationsTableView.layer.mask = maskLayer;

    [self.view addSubview:annotationsTableView];
}


- (IBAction)annotationsButtonAction:(id)sender {
    
//    if ([annotationsTableView isHidden]) {
//        if ([self.imageDict count]>0) {
//            [annotationsTableView reloadData];
//            [annotationsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
//        }
//            [annotationsTableView setHidden:NO];
//            [UIView animateWithDuration:0.3f
//                             animations:^{
//                                 [self.view setAlpha:1.0];
//                             }
//                             completion:nil];
//        
//        [panGesture setEnabled:NO];
//        [longPressGesture setEnabled:NO];
//        [CameraButton setUserInteractionEnabled:NO];
//    }
//    else{
//        [annotationsTableView setHidden:YES];
//        
//        [panGesture setEnabled:YES];
//        [longPressGesture setEnabled:YES];
//        [CameraButton setUserInteractionEnabled:YES];
//    }
}


#pragma mark TableView Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return @"Tags Nearby";
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(20, 0, 100, 22);
    label.textColor = [UIColor lightGrayColor];
    [label setFont:[UIFont fontWithName:@"Akkurat" size:14]];
    label.text = [self tableView:tableView titleForHeaderInSection:section];
    label.backgroundColor = [UIColor clearColor];
    
    UIView*backgroundView = [[UIView alloc] initWithFrame:CGRectMake(2, 0, 316, 24)];
    [backgroundView setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.65]];
    
    // Create header view and add label as a subview
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 22)];
    [view setBackgroundColor:[UIColor clearColor]];
    [view addSubview:backgroundView];
    [view addSubview:label];
    
    return view;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.imageDict count];
}

- (float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    FluxAnnotationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"annotationsFeedCell"];
    return cell.frame.size.height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"annotationsFeedCell";
    FluxAnnotationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[FluxAnnotationTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                  reuseIdentifier:CellIdentifier];
    }
    
    NSNumber *objkey = [[self.imageDict allKeys] objectAtIndex:indexPath.row];
    FluxScanImageObject *rowObject = [self.imageDict objectForKey: objkey];
    
    cell.imageID = rowObject.imageID;
    if (rowObject.contentImage == nil)
    {
        [networkServices getThumbImageForID:cell.imageID];
    }
    else
        [cell.contentImageView setImage:rowObject.contentImage];
    cell.descriptionLabel.text = rowObject.descriptionString;
    cell.userLabel.text = [NSString stringWithFormat:@"User: %i",rowObject.userID];
    cell.timestampLabel.text = rowObject.timestampString;
    
    return cell;
}

//remove all but selected cell - not called right now
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //    NSMutableArray *cellIndicesToBeDeleted = [[NSMutableArray alloc] init];
    //    for (int i = 0; i < [tableView numberOfRowsInSection:0]; i++) {
    //        if (i != indexPath.row) {
    //            NSIndexPath *p = [NSIndexPath indexPathForRow:i inSection:1];
    //            [cellIndicesToBeDeleted addObject:p];
    //        }
    //    }
    //    [tableView deleteRowsAtIndexPaths:cellIndicesToBeDeleted
    //                     withRowAnimation:UITableViewRowAnimationFade];
    //    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.view.layer.mask.position = CGPointMake(0, scrollView.contentOffset.y);
    [CATransaction commit];
}

# pragma mark - prepare segue action with identifer
- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"pushMapModalView"])
    {
        FluxMapViewController *fluxMapViewController = (FluxMapViewController *)segue.destinationViewController;
        fluxMapViewController.myViewOrientation = changeToOrientation;
        fluxMapViewController.mapAnnotationsDictionary = self.imageDict;
    }
}

#pragma mark - OpenGLView

-(void)setupOpenGLView{
    UIStoryboard *myStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard"
                                                           bundle:[NSBundle mainBundle]];

    
    
    // setup the opengl controller
    // first get an instance from storyboard
    openGLController = [myStoryboard instantiateViewControllerWithIdentifier:@"openGLViewController"];
    [openGLController setTheDelegate:self];
    
    // then add the glkview as the subview of the parent view
    [self.view insertSubview:openGLController.view belowSubview:headerView];
    // add the glkViewController as the child of self
    [self addChildViewController:openGLController];
    [openGLController didMoveToParentViewController:self];
    openGLController.view.frame = self.view.bounds;
}

- (void)OpenGLView:(FluxOpenGLViewController *)glView didUpdateImageList:(NSMutableDictionary *)aImageDict{
    self.imageDict = aImageDict;
}

#pragma mark - Gesture Recognizer
- (void)setupGestureHandlers{
    //pan
    panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [panGesture setMaximumNumberOfTouches:1];
    [panGesture setDelegate:self];
    [self.view addGestureRecognizer:panGesture];
    
    //longpress
    longPressGesture = [[UILongPressGestureRecognizer alloc]
                                               initWithTarget:self
                                               action:@selector(handleLongPress:)];
    [longPressGesture setNumberOfTouchesRequired:1];
    longPressGesture.minimumPressDuration = 0.5;
    [self.view addGestureRecognizer:longPressGesture];
    
    //thumb Circle
    thumbView = [[FluxClockSlidingControl alloc]initWithFrame:CGRectMake(0, 0, 100, 110)];
    thumbView.transform = CGAffineTransformScale(thumbView.transform, 0.5, 0.5);
    [thumbView setHidden:YES];
    [self.view addSubview:thumbView];
    
    //tap gesture to exit annotationView. This blocks the tableView taps as of now.
    tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTapGesture:)];
    [tapGesture setNumberOfTapsRequired:1];
    [self.view addGestureRecognizer:tapGesture];
}

- (void)handleTapGesture:(UITapGestureRecognizer*) sender{
//    if (![annotationsFeedView popoverIsHidden]) {
//        
//        CGPoint touchLoc = [sender locationInView:self.view];
//        BOOL isWithinAnnotationsView = CGRectContainsPoint(annotationsFeedView.view.frame, touchLoc);
//        BOOL isWithinCameraControlsView = CGRectContainsPoint(self.drawerContainerView.frame, touchLoc);
//        isWithinCameraControlsView = NO;
//        if (!isWithinAnnotationsView && !isWithinCameraControlsView) {
//            [self annotationsButtonAction:nil];
//        }
//    }
    
}


- (void)handleLongPress:(UILongPressGestureRecognizer *) sender{
    //prevent multiple touches
    if (![sender isEnabled]) return;
    
    if(sender.state == UIGestureRecognizerStateBegan)
    {
        [thumbView setStartingYCoord:[sender locationInView:self.view].y];
        [thumbView setHidden:NO];
        [thumbView setCenter:[sender locationInView:self.view]];
        //start with today's date
        [thumbView.timeLabel setText:[dateFormatter stringFromDate:[NSDate date]]];
        
        [UIView animateWithDuration:0.2f
                         animations:^{
                             //[thumbView setFrame:CGRectMake(thumbView.frame.origin.x, thumbView.frame.origin.y, 98, 98)];
                             thumbView.transform = CGAffineTransformScale(thumbView.transform, 2.0, 2.0);
                         }];
        startXCoord = [sender locationInView:self.view].x;
    }
    else if(sender.state == UIGestureRecognizerStateChanged)
    {
        NSLog(@"Gesture location: %f, %f",[sender locationInView:self.view].x,[sender locationInView:self.view].y);
        [thumbView setCenter:[sender locationInView:self.view]];
        [self setThumbViewDate:[sender locationInView:self.view].y];
        
        if (abs(startXCoord - [sender locationInView:self.view].x) > 75) {
            //we've gone too far to the right, kill it
        }
    }
    
    else if((sender.state == UIGestureRecognizerStateEnded) || ([sender state] == UIGestureRecognizerStateCancelled))
    {
        if ([thumbView isHidden]) {
            return;
        }
        [UIView animateWithDuration:0.05f
                         animations:^{
                             thumbView.transform = CGAffineTransformScale(thumbView.transform, 0.5, 0.5);
                         }
                         completion:^(BOOL finished){
                             [thumbView setHidden:YES];
                         }];
    }
    
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}

//called during pan gesture, location is available as well as translation.
- (void)handlePanGesture:(UIPanGestureRecognizer *)sender{

    NSLog(@"Gesture location: %f, %f",[sender locationInView:self.view].x,[sender locationInView:self.view].y);
    [self setThumbViewDate:[sender locationInView:self.view].y];
    
    [thumbView setCenter:[sender locationInView:self.view]];
    //close it if the gesture has ended
    if (([sender state] == UIGestureRecognizerStateEnded) || ([sender state] == UIGestureRecognizerStateCancelled)) {
        [UIView animateWithDuration:0.05f
                         animations:^{
                             thumbView.transform = CGAffineTransformScale(thumbView.transform, 0.5, 0.5);
                         }
                         completion:^(BOOL finished){
                             [thumbView setHidden:YES];
                         }];
    }
    
}

//limit to only vertical panning
- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)panGestureRecognizer {
    if (thumbView.frame.size.width>70) {
        return NO;
    }
    CGPoint translation = [panGestureRecognizer translationInView:self.view];
    //if its vertical
    if (fabs(translation.y) > fabs(translation.x)) {
        [thumbView setStartingYCoord:[panGestureRecognizer locationInView:self.view].y];
        [thumbView setHidden:NO];
        [thumbView setCenter:[panGestureRecognizer locationInView:self.view]];
        //start with today's date
        [thumbView.timeLabel setText:[dateFormatter stringFromDate:[NSDate date]]];
        
        [UIView animateWithDuration:0.2f
                         animations:^{
                             thumbView.transform = CGAffineTransformScale(thumbView.transform, 2.0, 2.0);
                         }];
        
        return YES;
    }
    return NO;
}

- (void)setThumbViewDate:(float)yCoord{
    
    //if adding
    if (previousYCoord>yCoord) {
        NSDate *now = [NSDate date];
        int daysToAdd = roundf(yCoord);
        NSDate *newDate = [now dateByAddingTimeInterval:60*60*24*daysToAdd];
        [thumbView changeTimeString:[dateFormatter stringFromDate:newDate]adding:YES];
    }
    else{
        NSDate *now = [NSDate date];
        int daysToSubtract = roundf(yCoord)*-1;
        NSDate *newDate = [now dateByAddingTimeInterval:60*60*24*daysToSubtract];
        [thumbView changeTimeString:[dateFormatter stringFromDate:newDate]adding:NO];
    }
    previousYCoord = yCoord;
}

#pragma mark - AV Capture Methods

- (void)setupAVCapture
{
    AVCaptureBackgroundQueue = dispatch_queue_create("com.normative.flux.bgqueue", NULL);
//    
//	NSError *error = nil;
//	
//	AVCaptureSession *session = [AVCaptureSession new];
//    [session setSessionPreset:AVCaptureSessionPresetHigh]; // full resolution photo...
//	
//    // Select a video device, make an input
//    device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
//    
//    //set autofocus
//    BOOL locked = [device lockForConfiguration:nil];
//    if (locked)
//    {
//        device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
//        [device unlockForConfiguration];
//    }
// 	
//    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
//    
//    if (error == nil)
//    {
//        if ( [session canAddInput:deviceInput] )
//            [session addInput:deviceInput];
//        
//        // Make a still image output
//        stillImageOutput = [AVCaptureStillImageOutput new];
//        //[stillImageOutput addObserver:self forKeyPath:@"capturingStillImage" options:NSKeyValueObservingOptionNew context:(__bridge void *)(AVCaptureStillImageIsCapturingStillImageContext)];
//        if ( [session canAddOutput:stillImageOutput] )
//            [session addOutput:stillImageOutput];
//        
//        // Make a video data output
//        videoDataOutput = [AVCaptureVideoDataOutput new];
//        
//        // we want BGRA, both CoreGraphics and OpenGL work well with 'BGRA'
//        NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:
//                                           [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
//        [videoDataOutput setVideoSettings:rgbOutputSettings];
//        [videoDataOutput setAlwaysDiscardsLateVideoFrames:YES]; // discard if the data output queue is blocked (as we process the still image)
//        
//        // create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured
//        // a serial dispatch queue must be used to guarantee that video frames will be delivered in order
//        // see the header doc for setSampleBufferDelegate:queue: for more information
//        videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
//        [videoDataOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];
//        
//        if ([session canAddOutput:videoDataOutput]){
//            [session addOutput:videoDataOutput];
//        }
//        [[videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:NO];
//        previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
//        [previewLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
//        [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
//        CALayer *rootLayer = [self.view layer];
//        //[rootLayer setMasksToBounds:YES];
//        [previewLayer setFrame:self.view.bounds];
//        [rootLayer insertSublayer:previewLayer atIndex:0];
//        //[rootLayer addSublayer:previewLayer];
//        [session startRunning];
//    }
//    
//	//[session release];
//    
//	if (error)
//    {
//		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Failed with error %d", (int)[error code]]
//															message:[error localizedDescription]
//														   delegate:nil
//												  cancelButtonTitle:@"Dismiss"
//												  otherButtonTitles:nil];
//		[alertView show];
//		//[alertView release];
//        [self pauseAVCapture];
//	}
    cameraManager = [FluxAVCameraSingleton sharedCamera];
    previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:cameraManager.session];
    [previewLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    CALayer *rootLayer = [self.view layer];
    //[rootLayer setMasksToBounds:YES];
    [previewLayer setFrame:self.view.bounds];
    [rootLayer insertSublayer:previewLayer atIndex:0];
    //[rootLayer addSublayer:previewLayer];
    //[cameraManager.videoDataOutput setSampleBufferDelegate:self queue:cameraManager.videoDataOutputQueue];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(annotationsViewDidPop:)  name:@"AnnotationViewPopped"  object:nil];
}

-(void)pauseAVCapture
{
    [cameraManager pauseAVCapture];
}

//restarts the capture session. The actual restart is an async call, with the UI adding a blur for the wait.
-(void)restartAVCaptureWithBlur:(BOOL)blur
{
    //don't add a blur if we haven't captured an image yet.
   
    if (capturedImage != nil && blur) {
        [gridView setAlpha:0.0];
        [CameraButton setAlpha:0.0];
        [blurView setImage:[self blurImage:capturedImage]];
        [blurView setHidden:NO];
        [UIView animateWithDuration:0.2 animations:^{
            [blurView setAlpha:1.0];
        }completion:nil];
    }
    dispatch_async(AVCaptureBackgroundQueue, ^{
        //start AVCapture
        [cameraManager restartAVCapture];
        dispatch_sync(dispatch_get_main_queue(), ^{
            //completion callback
            if (blur) {
                [UIView animateWithDuration:0.2 animations:^{
                    [blurView setAlpha:0.0];
                    [gridView setAlpha:1.0];
                    [CameraButton setAlpha:1.0];
                }completion:^(BOOL finished){
                    [blurView setHidden:YES];
                }];
            }
        });
    });
    
    
    
    
    
}

#pragma mark Camera View

- (void)setupCameraView{
    camMode = [NSNumber numberWithInt:0];
    [self.cameraApproveContainerView setHidden:YES];
    
    //add gridlines
    gridView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"CameraGridlines.png"]];
    [gridView setFrame:self.view.bounds];
    [gridView setHidden:YES];
    [gridView setAlpha:0.0];
    [gridView setContentMode:UIViewContentModeScaleAspectFill];
    [self.view insertSubview:gridView belowSubview:CameraButton];
    
    blackView = [[UIView alloc]initWithFrame:self.view.bounds];
    [blackView setBackgroundColor:[UIColor blackColor]];
    [blackView setAlpha:0.0];
    [blackView setHidden:YES];
    [self.view addSubview:blackView];
    
    blurView = [[UIImageView alloc]initWithFrame:self.view.bounds];
    [blurView setBackgroundColor:[UIColor clearColor]];
    [blurView setAlpha:0.0];
    [blurView setHidden:YES];
    [self.view addSubview:blurView];
    
#warning annotationsTableView is here, commented out
//    annotationsFeedView = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"FluxAnnotationsTableViewController"];
//    [annotationsFeedView.view setFrame:CGRectMake(0, headerView.frame.origin.y+headerView.frame.size.height+4, self.view.frame.size.width, self.view.frame.size.height-200)];
//    [annotationsFeedView.view setHidden:YES];
//    [annotationsFeedView.view setAlpha:0.0];
//    [self addChildViewController:annotationsFeedView];
//    [annotationsFeedView didMoveToParentViewController:self];
//    [self.view insertSubview:annotationsFeedView.view belowSubview:headerView];
//    
//    //fade out the bottom of the feedView
//    CAGradientLayer* maskLayer = [CAGradientLayer layer];
//    NSObject*   transparent = (NSObject*) [[UIColor clearColor] CGColor];
//    NSObject*   opaque = (NSObject*) [[UIColor blackColor] CGColor];
//    [maskLayer setColors: [NSArray arrayWithObjects: opaque, opaque,opaque,opaque,transparent, nil]];
//    maskLayer.locations = [NSArray arrayWithObjects:
//                           [NSNumber numberWithFloat:0.0],
//                           [NSNumber numberWithFloat:0.0],
//                           [NSNumber numberWithFloat:0.0],
//                           [NSNumber numberWithFloat:0.8],
//                           [NSNumber numberWithFloat:1.0], nil];
//    maskLayer.bounds = annotationsFeedView.view.layer.bounds;
//    maskLayer.anchorPoint = CGPointZero;
//    annotationsFeedView.view.layer.mask = maskLayer;
}

- (IBAction)cameraButtonAction:(id)sender {
    //camera is off, open it
    if ([camMode isEqualToNumber:[NSNumber numberWithInt:0]]) {
        
        [self setUIForCamMode:[NSNumber numberWithInt:1]];
    }
    else{
        [self takePicture];
    }
    
    //camView
}

- (void)setUIForCamMode:(NSNumber*)mode{
    //going to closed cam
    if ([mode isEqualToNumber:[NSNumber numberWithInt:0]]) {
        [self stopDeviceMotion];
        [self.cameraApproveContainerView setHidden:YES];
        [headerView setHidden:NO];
        [self.drawerContainerView setHidden:NO];
        [CameraButton setHidden:NO];
        [self restartAVCaptureWithBlur:NO];
        [openGLController.view setHidden:NO];
        
        [UIView animateWithDuration:0.3f
                         animations:^{
                             [headerView setAlpha:1.0];
                             [self.drawerContainerView setAlpha:1.0];
                             [CameraButton setCenter:CGPointMake(CameraButton.center.x, CameraButton.center.y+21)];
                             [gridView setAlpha:0.0];
                             [openGLController.view setAlpha:1.0];
                         }
                         completion:^(BOOL finished){
                             //stops drawing them
                             [panGesture setEnabled:YES];
                             [longPressGesture setEnabled:YES];
                             [gridView setHidden:YES];
                             //[cameraManager setSampleBufferDelegate:openGLController forViewController:openGLController];

                         }];
        
        CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
        bounceAnimation.values = [NSArray arrayWithObjects:
                                  [NSNumber numberWithFloat:2.0],
                                  [NSNumber numberWithFloat:0.9],
                                  [NSNumber numberWithFloat:1.1],
                                  [NSNumber numberWithFloat:1.0], nil];
        bounceAnimation.duration = 0.3;
        [CameraButton.layer addAnimation:bounceAnimation forKey:@"bounce_closed"];
        CameraButton.layer.transform = CATransform3DIdentity;
        
        camMode = [NSNumber numberWithInt:0];
    }
    //going to active cam
    else if ([mode isEqualToNumber:[NSNumber numberWithInt:1]]){
        [panGesture setEnabled:NO];
        [longPressGesture setEnabled:NO];
        [gridView setHidden:NO];
        [UIView animateWithDuration:0.3f
                         animations:^{
                             [headerView setAlpha:0.0];
                             [self.drawerContainerView setAlpha:0.0];
                             [gridView setAlpha:1.0];
                             [openGLController.view setAlpha:0.0];
                         }
                         completion:^(BOOL finished){
                             //stops drawing them
                             [headerView setHidden:YES];
                             [self.drawerContainerView setHidden:YES];
                             [self startDeviceMotion];
                             [openGLController.view setHidden:YES];
                             camMode = [NSNumber numberWithInt:1];
                             //[cameraManager setSampleBufferDelegate:self forViewController:self];
                         }];
        
        CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
        bounceAnimation.values = [NSArray arrayWithObjects:
                                  [NSNumber numberWithFloat:1.0],
                                  [NSNumber numberWithFloat:2.1],
                                  [NSNumber numberWithFloat:1.8],
                                  [NSNumber numberWithFloat:2.0], nil];
        bounceAnimation.duration = 0.3;

        [CameraButton.layer addAnimation:bounceAnimation forKey:@"bounce_open"];
        CameraButton.layer.transform = CATransform3DIdentity;
        CameraButton.transform = CGAffineTransformScale(CameraButton.transform, 2.0, 2.0);
    }
    //going to confirm cam
    else{
        [cameraManager pauseAVCapture];
        
        [self.cameraApproveContainerView setHidden:NO];
        [CameraButton setHidden:YES];
        [gridView setHidden:YES];
        
        camMode = [NSNumber numberWithInt:2];
    }
    
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    if ([camMode isEqualToNumber:[NSNumber numberWithInt:1]] || [camMode isEqualToNumber:[NSNumber numberWithInt:2]]) {
        UITouch *touch = [touches anyObject];
        if (![[touch class]isSubclassOfClass:[UIButton class]]) {
            [self setUIForCamMode:[NSNumber numberWithInt:0]];
        }

    }
}

- (void)annotationsViewDidPop:(NSNotification *)notification{
    if (notification.object != nil) {
        //theres a new image object here.
    }
    [self setUIForCamMode:[NSNumber numberWithInt:0]];
}

#pragma mark AVCam Methods
- (void)takePicture{
    
    
    __block NSDate *startTime = [NSDate date];
    
    
    //black Animation
    [blackView setHidden:NO];
    [UIView animateWithDuration:0.09 animations:^{
        [blackView setAlpha:0.9];
    }completion:^(BOOL finished){

    }];
    
    // Collect position and orientation information prior to copying image
    CLLocation *location = locationManager.location;
    CMAttitude *att = motionManager.deviceMotion.attitude;
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
             
             //save picture to photo album/locally
             NSData *jpeg = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
             UIImage *theimg = [UIImage imageWithData:jpeg];
             capturedImage = theimg;
             
//             // Grab a copy of the current metadata dictionary for modification - will be saved in image
//             CFDictionaryRef metaDict = CMCopyDictionaryOfAttachments(NULL, imageDataSampleBuffer, kCMAttachmentMode_ShouldPropagate);
//             CFMutableDictionaryRef mutableMetadata = CFDictionaryCreateMutableCopy(NULL, 0, metaDict);
//             
//             // Create the metadata dictionary which is saved with image as XML
//             imgMetadata = [[NSMutableDictionary alloc] init];
//             
//             // Create formatted date
//             NSTimeZone      *timeZone   = [NSTimeZone timeZoneWithName:@"UTC"];
//             NSDateFormatter *formatter  = [[NSDateFormatter alloc] init];
//             [formatter setTimeZone:timeZone];
//             [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
//             
//             NSMutableDictionary *GPSDictionary = [[NSMutableDictionary alloc] init];
//             timestampString = nil;
//             
//             if (location != nil)
//             {
//                 // Create GPS Dictionary
//                 [GPSDictionary setValue:[NSNumber numberWithDouble:fabs(location.coordinate.latitude)] forKey:(NSString *)kCGImagePropertyGPSLatitude];
//                 [GPSDictionary setValue:((location.coordinate.latitude >= 0) ? @"N" : @"S") forKey:(NSString *)kCGImagePropertyGPSLatitudeRef];
//                 [GPSDictionary setValue:[NSNumber numberWithDouble:fabs(location.coordinate.longitude)] forKey:(NSString *)kCGImagePropertyGPSLongitude];
//                 [GPSDictionary setValue:((location.coordinate.longitude >= 0) ? @"E" : @"W") forKey:(NSString *)kCGImagePropertyGPSLongitudeRef];
//                 [GPSDictionary setValue:[formatter stringFromDate:[location timestamp]] forKey:(NSString *)kCGImagePropertyGPSDateStamp];
//                 [GPSDictionary setValue:[NSNumber numberWithDouble:fabs(location.altitude)] forKey:(NSString *)kCGImagePropertyGPSAltitude];
//                 [GPSDictionary setValue:[NSNumber numberWithDouble:fabs(location.horizontalAccuracy)] forKey:(NSString *)(NSString *)@"HorizontalAccuracy"];
//                 [GPSDictionary setValue:[NSNumber numberWithDouble:fabs(location.verticalAccuracy)] forKey:(NSString *)(NSString *)@"VerticalAccuracy"];
//                 [GPSDictionary setValue:[NSNumber numberWithDouble:fabs(location.speed)] forKey:(NSString *)(NSString *)kCGImagePropertyGPSSpeed];
//                 [GPSDictionary setValue:[NSNumber numberWithDouble:fabs(location.course)] forKey:(NSString *)(NSString *)kCGImagePropertyGPSDestBearing];
//                 
//                 [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss:SS"];
//                 //timestampstr = [formatter stringFromDate:loc.timestamp];
//                 theDate = [[NSDate alloc]init];
//                 timestampString = [formatter stringFromDate:theDate];
//             }
//             else
//             {
//                 NSLog(@"No location data to store with image");
//             }
//             
//             // Overwrite updated GPS information
//             CFDictionarySetValue(mutableMetadata, kCGImagePropertyGPSDictionary, (void *)GPSDictionary);
//             
//             // Add GPSDictionary to Position section of XML
//             [imgMetadata setValue:GPSDictionary forKey:(NSString *)@"Position"];
//             
//             //add heading
//             [imgMetadata setValue:[NSNumber numberWithDouble:locationManager.heading] forKey:(NSString *)@"Heading"];
//             
//             NSMutableDictionary *EXIFDictionary = (NSMutableDictionary*)CFDictionaryGetValue(mutableMetadata, kCGImagePropertyExifDictionary);
//             //NSMutableDictionary *EXIFAuxDictionary = (NSMutableDictionary*)CFDictionaryGetValue(mutable, kCGImagePropertyExifAuxDictionary);
//             
//             CFDictionarySetValue(mutableMetadata, kCGImagePropertyExifDictionary, (void *)EXIFDictionary);
//             
//             // Orientation Section
//             CMRotationMatrix m = att.rotationMatrix;
//             
//             // dump the rotation matrix as a 2-d array
//             NSMutableDictionary *OrientDictionary = [[NSMutableDictionary alloc] init];
//             NSArray *rmr1 = [NSArray arrayWithObjects:[NSNumber numberWithDouble:m.m11], [NSNumber numberWithDouble:m.m12],
//                              [NSNumber numberWithDouble:m.m13], [NSNumber numberWithDouble:0.0], nil];
//             NSArray *rmr2 = [NSArray arrayWithObjects:[NSNumber numberWithDouble:m.m21], [NSNumber numberWithDouble:m.m22],
//                              [NSNumber numberWithDouble:m.m23], [NSNumber numberWithDouble:0.0], nil];
//             NSArray *rmr3 = [NSArray arrayWithObjects:[NSNumber numberWithDouble:m.m31], [NSNumber numberWithDouble:m.m32],
//                              [NSNumber numberWithDouble:m.m33], [NSNumber numberWithDouble:0.0], nil];
//             NSArray *rmr4 = [NSArray arrayWithObjects:[NSNumber numberWithDouble:0.0], [NSNumber numberWithDouble:0.0],
//                              [NSNumber numberWithDouble:0.0], [NSNumber numberWithDouble:1.0], nil];
//             NSArray *rm = [NSArray arrayWithObjects:rmr1, rmr2, rmr3, rmr4, nil];
//             [OrientDictionary setValue:rm forKey:(NSString *)@"AttitudeRotationMatrix"];
//             
//             // dump the euler angles as an array
//             NSArray *ev = [NSArray arrayWithObjects:[NSNumber numberWithDouble:att.yaw], [NSNumber numberWithDouble:att.pitch],
//                            [NSNumber numberWithDouble:att.roll], nil];
//             [OrientDictionary setValue:ev forKey:(NSString *)@"EulerAngles"];
//             
//             // dump the quaternion portion as an array
//             NSArray *qv = [NSArray arrayWithObjects:[NSNumber numberWithDouble:att.quaternion.w],
//                            [NSNumber numberWithDouble:att.quaternion.x], [NSNumber numberWithDouble:att.quaternion.y],
//                            [NSNumber numberWithDouble:att.quaternion.z], nil];
//             [OrientDictionary setValue:qv forKey:(NSString *)@"Quaternion"];
//             
//             // Add OrientDictionary to Orientation section of XML
//             [imgMetadata setValue:OrientDictionary forKey:(NSString *)@"Orientation"];
//             
//             // Device Section
//             NSMutableDictionary *DeviceDictionary = [[NSMutableDictionary alloc] init];
//             
//             NSUUID *duid = [[UIDevice currentDevice] identifierForVendor];
//             NSString *model = [[UIDevice currentDevice] model];
//             [DeviceDictionary setValue:[duid UUIDString] forKey:(NSString *)@"DeviceID"];
//             [DeviceDictionary setValue:model forKey:(NSString *)@"Model"];
//             [DeviceDictionary setValue:(isUsingFrontFacingCamera?@"Front":@"Back") forKey:(NSString *)@"Camera"];
//             [DeviceDictionary setValue:NSStringFromUIInterfaceOrientation([UIApplication sharedApplication].statusBarOrientation) forKey:@"Orientation"];
//             [imgMetadata setValue:DeviceDictionary forKey:(NSString *)@"Device"];
//             
//             // Image Section
//             NSMutableDictionary *ImageDictionary = [[NSMutableDictionary alloc] init];
//             
//             [ImageDictionary setValue:timestampString forKey:(NSString *)@"TimeStamp"];
//             [ImageDictionary setValue:@"SelectedCategory" forKey:(NSString *)@"Category"];
//             [ImageDictionary setValue:@"Arbitrary Description, optionally containing #tags or @userlinks" forKey:(NSString *)@"Description"];
//             
//             [imgMetadata setValue:ImageDictionary forKey:(NSString *)@"Image"];
//             
//             
//             // write the file with exif data
//             CGImageSourceRef  source;
//             source = CGImageSourceCreateWithData((__bridge CFDataRef)jpeg, NULL);
//             
//             CFStringRef UTI = CGImageSourceGetType(source); //this is the type of image (e.g., public.jpeg)
//             
//             // this will be the data CGImageDestinationRef will write into
//             imgData = [NSMutableData data];
//             
//             CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imgData,UTI,1,NULL);
//             
//             if(!destination)
//             {
//                 NSLog(@"***Could not create image destination ***");
//             }
//             
//             // add the image contained in the image source to the destination, over-writing the old metadata with our modified metadata
//             CGImageDestinationAddImageFromSource(destination,source,0, (CFDictionaryRef) mutableMetadata);
//             
//             // tell the destination to write the image data and metadata into our data object.
//             // It will return false if something goes wrong
//             BOOL success = NO;
//             success = CGImageDestinationFinalize(destination);
//             
//             if(!success)
//             {
//                 NSLog(@"***Could not create data from image destination ***");
//             }
             int userID = 1;
             int cameraID = 1;
             int categoryID = 1;
             
             capturedImageObject = [[FluxScanImageObject alloc]initWithImage:capturedImage
                                                              fromUserWithID:userID
                                                           atTimestampString:[[NSDate date]description]
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
                                                                       andQZ:att.quaternion.z];
             
             //cleanup
//             CFRelease(destination);
//             CFRelease(source);
             
             //UI Updates
             [self setUIForCamMode:[NSNumber numberWithInt:2]];
             [UIView animateWithDuration:0.09 animations:^{
                 [blackView setAlpha:0.0];
             } completion:^(BOOL finished) {
                 [blackView setHidden:YES];
             }];
         }
     }];
}

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


- (IBAction)approveImageAction:(id)sender {
    [self pauseAVCapture];
    [self stopDeviceMotion];
    
    //[self performSelector:@selector(setUIForCamMode:) withObject:[NSNumber numberWithInt:0] afterDelay:0.3];
    
    
    FluxImageAnnotationViewController *annotationsView = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"FluxImageAnnotationViewController"];
    [annotationsView setCapturedImage:capturedImageObject andLocation:locationManager.location];
    annotationsView.view.backgroundColor = [UIColor clearColor];
    annotationsView.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:annotationsView animated:YES completion:nil];
}

- (IBAction)retakeImageAction:(id)sender {
    [gridView setHidden:NO];
    [self.cameraApproveContainerView setHidden:YES];
    [CameraButton setHidden:NO];
    camMode = [NSNumber numberWithInt:1];
    [self restartAVCaptureWithBlur:YES];
    //[self setUIForCamMode:[NSNumber numberWithInt:1]];
}

//-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
//    UITouch *touch = [[event allTouches] anyObject];
//    if ([[touch.view class] ) {
//        <#statements#>
//    }
//    if ([[touch.view class] isSubclassOfClass:[UILabel class]]){
//        
//    }
//}

#pragma mark Image Capture Helper Methods
-(UIImage*)blurImage:(UIImage *)img{
    //CGImage blows away image metadata, keep orientation
    UIImageOrientation orientation = img.imageOrientation;
    
    CIImage *inputImage = [[CIImage alloc] initWithCGImage:img.CGImage];
    CIContext *context = [CIContext contextWithOptions:nil];
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    //clamp the borders so the blur doesnt shrink the borders of the image
    CIFilter *clampFilter = [CIFilter filterWithName:@"CIAffineClamp"];
    [clampFilter setValue:inputImage forKey:kCIInputImageKey];
    [clampFilter setValue:[NSValue valueWithBytes:&transform objCType:@encode(CGAffineTransform)] forKey:@"inputTransform"];
    CIImage *outputImage = [clampFilter outputImage];
    
    //adds gaussian blur to the image
    CIFilter *blurFilter = [CIFilter filterWithName:@"CIGaussianBlur" keysAndValues:kCIInputImageKey, outputImage, @"inputRadius", [NSNumber numberWithFloat:35], nil];
    outputImage = [blurFilter outputImage];
    
    //output the image
    CGImageRef cgimg = [context createCGImage:outputImage fromRect:inputImage.extent];
    UIImage *blurredImage = [UIImage imageWithCGImage:cgimg scale:1.0 orientation:orientation];
    CGImageRelease(cgimg);
    
    return blurredImage;
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
        
        if (![annotationsTableView isHidden])
        {
            [annotationsTableView setHidden:YES];
            [openGLController pauseOpenGLRender];
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
    [self setupAVCapture];
    [self setupGestureHandlers];
    [self setupCameraView];
    [self setupMotionManager];
    [self setupOpenGLView];

    // Start the location manager service which will continue for the life of the app
    locationManager = [FluxLocationServicesSingleton sharedManager];
    [locationManager startLocating];
    
    [self setupNetworkServices];
    
    self.imageDict = [[NSMutableDictionary alloc]init];
    [dateRangeLabel setFont:[UIFont fontWithName:@"Akkurat" size:dateRangeLabel.font.pointSize]];
    [locationLabel setFont:[UIFont fontWithName:@"Akkurat" size:dateRangeLabel.font.pointSize]];
    //temporarily set the date range label to today's date
    dateFormatter  = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd MMM, YYYY"];
    [dateRangeLabel setText:[dateFormatter stringFromDate:[NSDate date]]];
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
    [self restartAVCaptureWithBlur:YES];
    
    if (![openGLController openGLRenderIsActive]) {
        [openGLController restartOpenGLRender];
    }
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



