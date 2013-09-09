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

@synthesize fluxImageCache;
@synthesize fluxMetadata;
@synthesize thumbView;

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
    [networkServices getImagesForLocation:loc.coordinate andRadius:25];
}

#pragma mark - Network Services

- (void)setupNetworkServices{
    networkServices = [[FluxNetworkServices alloc]init];
    [networkServices setDelegate:self];
}

#pragma Networking Delegate Methods

//called by annotationsTableview
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices
         didreturnImage:(UIImage *)image
             forImageID:(int)imageID
{
    for (NSString *currentKey in [fluxMetadata allKeys])
    {
        FluxScanImageObject* currentImageObject = [fluxMetadata objectForKey:currentKey];
            if (currentImageObject.imageID == imageID)
            {
                [fluxImageCache setObject:image forKey:currentImageObject.localThumbID];
                break;
            }
    }
    [annotationsTableView reloadData];
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
    [annotationsTableView setBackgroundColor:[UIColor clearColor]];
    [annotationsTableView setSeparatorColor:[UIColor clearColor]];
    [annotationsTableView setAllowsSelection:NO];
    [annotationsTableView setDelegate:self];
    [annotationsTableView setDataSource:self];
    
    [annotationsTableView registerNib:[UINib nibWithNibName:@"FluxAnnotationTableViewCell" bundle:nil] forCellReuseIdentifier:@"annotationsFeedCell"];
    
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
    [fakeGalleryView setAlpha:0.0];
    if ([annotationsTableView isHidden]) {
        if ([fluxMetadata count]>0) {
            [annotationsTableView reloadData];
            //if there are any rows, scroll to the top of them
            if ([annotationsTableView numberOfRowsInSection:0]>0) {
                            [annotationsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
            }
        }
            [annotationsTableView setHidden:NO];
            [UIView animateWithDuration:0.3f
                             animations:^{
                                 [annotationsTableView setAlpha:1.0];
                             }
                             completion:nil];
        
        [panGesture setEnabled:NO];
        [longPressGesture setEnabled:NO];
        [CameraButton setUserInteractionEnabled:NO];
    }
    else{
        [UIView animateWithDuration:0.3f
                         animations:^{
                             [annotationsTableView setAlpha:0.0];
                         }
                         completion:^(BOOL finished){
                             [annotationsTableView setHidden:YES];
                             [panGesture setEnabled:YES];
                             [longPressGesture setEnabled:YES];
                             [CameraButton setUserInteractionEnabled:YES];
                         }];
    }
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
    return [fluxMetadata count];
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
    [cell initCell];
    
    NSNumber *objkey = [[fluxMetadata allKeys] objectAtIndex:indexPath.row];
    FluxScanImageObject *rowObject = [fluxMetadata objectForKey: objkey];
    
    cell.imageID = rowObject.imageID;
    if ([fluxImageCache objectForKey:rowObject.localThumbID] == nil)
    {
        [networkServices getThumbImageForID:cell.imageID];
    }
    else{
         [cell.contentImageView setImage:[fluxImageCache objectForKey:rowObject.localThumbID]];
    }
    cell.descriptionLabel.text = rowObject.descriptionString;
    cell.userLabel.text = [NSString stringWithFormat:@"User %i",rowObject.userID];
    [cell.timestampLabel setText:[dateFormatter stringFromDate:rowObject.timestamp]];
    [cell setCategory:rowObject.categoryID];
    
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
    annotationsTableView.layer.mask.position = CGPointMake(0, scrollView.contentOffset.y);
    [CATransaction commit];
}

# pragma mark - Map View Transition
- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"pushMapModalView"])
    {
        FluxMapViewController *fluxMapViewController = (FluxMapViewController *)segue.destinationViewController;
        fluxMapViewController.myViewOrientation = changeToOrientation;
        
        fluxMapViewController.fluxImageCache = self.fluxImageCache;
        fluxMapViewController.fluxMetadata = self.fluxMetadata;
    }
}

- (IBAction)showFakeGallery:(id)sender {
    [annotationsTableView setAlpha:0.0];
    if (fakeGalleryView.alpha == 0.0) {
        [UIView animateWithDuration:0.3f
                         animations:^{
                             [fakeGalleryView setAlpha:1.0];
                         }];
        [CameraButton setEnabled:NO];
    }
    else{
        [UIView animateWithDuration:0.3f
                         animations:^{
                             [fakeGalleryView setAlpha:0.0];
                         }];
        [CameraButton setEnabled:YES];
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
    
    openGLController.fluxImageCache = self.fluxImageCache;
    openGLController.fluxMetadata = self.fluxMetadata;
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
        [thumbView.timeLabel setText:[thumbDateFormatter stringFromDate:[NSDate date]]];
        
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
        [thumbView.timeLabel setText:[thumbDateFormatter stringFromDate:[NSDate date]]];
        
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
        [thumbView changeTimeString:[thumbDateFormatter stringFromDate:newDate]adding:YES];
    }
    else{
        NSDate *now = [NSDate date];
        int daysToSubtract = roundf(yCoord)*-1;
        NSDate *newDate = [now dateByAddingTimeInterval:60*60*24*daysToSubtract];
        [thumbView changeTimeString:[thumbDateFormatter stringFromDate:newDate]adding:NO];
    }
    previousYCoord = yCoord;
}

#pragma mark - AV Capture Methods

- (void)setupAVCapture
{
    AVCaptureBackgroundQueue = dispatch_queue_create("com.normative.flux.bgqueue", NULL);

    cameraManager = [FluxAVCameraSingleton sharedCamera];
    previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:cameraManager.session];
    [previewLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    CALayer *rootLayer = [self.view layer];
    [previewLayer setFrame:self.view.bounds];
    [rootLayer insertSublayer:previewLayer atIndex:0];
    
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
                             [[CameraButton getThumbView] setAlpha:0.0];
                         }
                         completion:^(BOOL finished){
                             //stops drawing them
                             [panGesture setEnabled:YES];
                             [longPressGesture setEnabled:YES];
                             [gridView setHidden:YES];
                             [[CameraButton getThumbView] setHidden:NO];
                         }];
        
        CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
        bounceAnimation.values = [NSArray arrayWithObjects:
                                  [NSNumber numberWithFloat:1.0],
                                  [NSNumber numberWithFloat:0.7],
                                  [NSNumber numberWithFloat:0.9],
                                  [NSNumber numberWithFloat:1.0], nil];
        bounceAnimation.duration = 0.3;
        [CameraButton.layer addAnimation:bounceAnimation forKey:@"bounce_closed"];
        
        camMode = [NSNumber numberWithInt:0];
    }
    //going to active cam
    else if ([mode isEqualToNumber:[NSNumber numberWithInt:1]]){
        [panGesture setEnabled:NO];
        [longPressGesture setEnabled:NO];
        [gridView setHidden:NO];
        [[CameraButton getThumbView] setHidden:NO];
        [UIView animateWithDuration:0.3f
                         animations:^{
                             [headerView setAlpha:0.0];
                             [self.drawerContainerView setAlpha:0.0];
                             [gridView setAlpha:1.0];
                             [openGLController.view setAlpha:0.0];
                             [[CameraButton getThumbView] setAlpha:1.0];
                             [CameraButton setCenter:CGPointMake(CameraButton.center.x, CameraButton.center.y-21)];
                         }
                         completion:^(BOOL finished){
                             //stops drawing them
                             [headerView setHidden:YES];
                             [self.drawerContainerView setHidden:YES];
                             [self startDeviceMotion];
                             [openGLController.view setHidden:YES];
                             camMode = [NSNumber numberWithInt:1];
                         }];
        
        CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
        bounceAnimation.values = [NSArray arrayWithObjects:
                                  [NSNumber numberWithFloat:1.0],
                                  [NSNumber numberWithFloat:1.5],
                                  [NSNumber numberWithFloat:0.8],
                                  [NSNumber numberWithFloat:1.0], nil];
        bounceAnimation.duration = 0.3;
        
        [CameraButton.layer addAnimation:bounceAnimation forKey:@"bounce_open"];
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
             
             NSData *jpeg = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
             capturedImage = [UIImage imageWithData:jpeg];
             
             NSDateFormatter *outDateFormat = [[NSDateFormatter alloc] init];
             [outDateFormat setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
             outDateFormat.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
             NSString *dateString = [outDateFormat stringFromDate:startTime];
             
             int userID = 1;
             int cameraID = 1;
             int categoryID = 1;
             
             capturedImageObject = [[FluxScanImageObject alloc]initWithUserID:userID
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
                                                                        andQZ:att.quaternion.z];

#warning We should probably consolidate all of the time variable. Probably create the object with the NSDate object.
             // Also set the internal timestamp variable to match the string representation
             [capturedImageObject setTimestamp:startTime];
             
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


- (IBAction)approveImageAction:(id)sender
{
    [self pauseAVCapture];
    [self stopDeviceMotion];
    
    FluxImageAnnotationViewController *annotationsView = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"FluxImageAnnotationViewController"];
    
    NSString *locationString = locationManager.subadministativearea;
    NSString *sublocality = locationManager.sublocality;
    if (sublocality.length > 0)
    {
        locationString = [NSString stringWithFormat:@"%@, %@", sublocality, locationString];
    }

    annotationsView.fluxImageCache = self.fluxImageCache;
    annotationsView.fluxMetadata = self.fluxMetadata;
    [annotationsView setCapturedImage:capturedImageObject andImage:capturedImage andLocationDescription:locationString];
    
    annotationsView.view.backgroundColor = [UIColor clearColor];
    annotationsView.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:annotationsView animated:YES completion:nil];
}

- (IBAction)retakeImageAction:(id)sender
{
    [gridView setHidden:NO];
    [self.cameraApproveContainerView setHidden:YES];
    [CameraButton setHidden:NO];
    camMode = [NSNumber numberWithInt:1];
    [self restartAVCaptureWithBlur:YES];
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

    self.fluxImageCache = [[NSCache alloc] init];
    self.fluxMetadata = [[NSMutableDictionary alloc] init];
    
    [self setupAVCapture];
    [self setupGestureHandlers];
    [self setupCameraView];
    [self setupMotionManager];
    [self setupOpenGLView];
    [self setupAnnotationsTableView];

    // Start the location manager service which will continue for the life of the app
    locationManager = [FluxLocationServicesSingleton sharedManager];
    [locationManager startLocating];
    
    [self setupNetworkServices];
    
    [dateRangeLabel setFont:[UIFont fontWithName:@"Akkurat" size:dateRangeLabel.font.pointSize]];
    [locationLabel setFont:[UIFont fontWithName:@"Akkurat" size:dateRangeLabel.font.pointSize]];
    //temporarily set the date range label to today's date
    dateFormatter  = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMMM d, YYYY"];
    [dateRangeLabel setText:[dateFormatter stringFromDate:[NSDate date]]];
    
    thumbDateFormatter  = [[NSDateFormatter alloc] init];
    [thumbDateFormatter setDateFormat:@"MMM d, YYYY"];
    
    fakeGalleryView = [[UIImageView alloc]initWithFrame:CGRectMake(7, 70, 306, 161)];
    [fakeGalleryView setContentMode:UIViewContentModeScaleAspectFit];
    //[fakeGalleryView setClipsToBounds:YES];
    [fakeGalleryView setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.65]];
    [fakeGalleryView setImage:[UIImage imageNamed:@"fakeGallery"]];
    [fakeGalleryView setAlpha:0.0];
    [self.view addSubview:fakeGalleryView];
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



