//
//  SMLRcamViewController.m
//  SMLRcam
//
//  Created by Kei Turner on 7/4/13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxScanViewController.h"

#import "UIViewController+MMDrawerController.h"
#import "FluxAnnotationTableViewCell.h"
#import "FluxTimeFilterControl.h"

#import <ImageIO/ImageIO.h>
#import "GAI.h"
#import "GAIDictionaryBuilder.h"

NSString* const FluxScanViewDidAcquireNewPicture = @"FluxScanViewDidAcquireNewPicture";
NSString* const FluxScanViewDidAcquireNewPictureLocalIDKey = @"FluxScanViewDidAcquireNewPictureLocalIDKey";

@implementation FluxScanViewController

@synthesize timeFilterControl;

#pragma mark - Network Services

//called by annotationsTableview
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices
         didreturnImage:(UIImage *)image
             forImageID:(int)imageID
{
#warning FIXME - Make sure these get called
// Need to trigger these somehow - probably from OpenGL VC
    [radarButton updateRadarWithNewMetaData:self.fluxDisplayManager.fluxNearbyMetadata];
    [annotationsTableView reloadData];
}

- (void)didUpdateImageList:(NSNotification *)notification{
    [filterButton setTitle:[NSString stringWithFormat:@"%i",self.fluxDisplayManager.fluxNearbyMetadata.count] forState:UIControlStateNormal];
    if (self.fluxDisplayManager.fluxNearbyMetadata.count<=5) {
        if (![timeFilterControl isHidden]) {
            [UIView animateWithDuration:0.2f
                             animations:^{
                                 [timeFilterControl setAlpha:0.0];
                             }
                             completion:^(BOOL finished){
                                 [timeFilterControl setHidden:YES];
                             }];
        }
    }
    else{
        if ([timeFilterControl isHidden]) {
            [timeFilterControl setHidden:NO];
            [UIView animateWithDuration:0.2f
                             animations:^{
                                 [timeFilterControl setAlpha:1.0];
                             }
                             completion:nil];
        }
    }
}

#pragma mark - Location Manager

-(void)didUpdatePlacemark:(NSNotification *)notification
{
    [locationLabel setText:[NSString stringWithFormat:@"%@",locationManager.subadministativearea]];
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

////show list of images currently visible.
//- (void)setupAnnotationsTableView{
//    annotationsTableView = [[UITableView alloc]initWithFrame:CGRectMake(7, 80, self.view.frame.size.width-14, self.view.frame.size.height-200)];
//    [annotationsTableView setHidden:YES];
//    [annotationsTableView setAlpha:0.0];
//    [annotationsTableView setBackgroundColor:[UIColor clearColor]];
//    [annotationsTableView setSeparatorColor:[UIColor clearColor]];
//    [annotationsTableView setAllowsSelection:NO];
//    [annotationsTableView setDelegate:self];
//    [annotationsTableView setDataSource:self];
//    
//    [annotationsTableView registerNib:[UINib nibWithNibName:@"FluxAnnotationTableViewCell" bundle:nil] forCellReuseIdentifier:@"annotationsFeedCell"];
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
//    maskLayer.bounds = annotationsTableView.layer.bounds;
//    maskLayer.anchorPoint = CGPointZero;
//    annotationsTableView.layer.mask = maskLayer;
//
//    [self.view addSubview:annotationsTableView];
//}
//
//
//- (IBAction)annotationsButtonAction:(id)sender {
//    [CameraButton setEnabled:YES];
//    if ([annotationsTableView isHidden]) {
//        if ([fluxNearbyMetadata count]>0) {
//            [annotationsTableView reloadData];
//            //if there are any rows, scroll to the top of them
//            if ([annotationsTableView numberOfRowsInSection:0]>0) {
//                            [annotationsTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
//            }
//        }
//            [annotationsTableView setHidden:NO];
//            [UIView animateWithDuration:0.3f
//                             animations:^{
//                                 [annotationsTableView setAlpha:1.0];
//                             }
//                             completion:nil];
//        [CameraButton setUserInteractionEnabled:NO];
//    }
//    else{
//        [UIView animateWithDuration:0.3f
//                         animations:^{
//                             [annotationsTableView setAlpha:0.0];
//                         }
//                         completion:^(BOOL finished){
//                             [annotationsTableView setHidden:YES];
//                             [CameraButton setUserInteractionEnabled:YES];
//                         }];
//    }
//}
//
//
//#pragma mark TableView Methods
//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//{
//    // Return the number of sections.
//    return 1;
//}
//
//- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
//    return @"Tags Nearby";
//}
//
//- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
//    UILabel *label = [[UILabel alloc] init];
//    label.frame = CGRectMake(12, 0, 100, 22);
//    label.textColor = [UIColor lightGrayColor];
//    [label setFont:[UIFont fontWithName:@"Akkurat" size:14]];
//    label.text = [self tableView:tableView titleForHeaderInSection:section];
//    label.backgroundColor = [UIColor clearColor];
//    
//    UIView*backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, annotationsTableView.frame.size.width, 24)];
//    [backgroundView setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.65]];
//    
//    // Create header view and add label as a subview
//    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 22)];
//    [view setBackgroundColor:[UIColor clearColor]];
//    [view addSubview:backgroundView];
//    [view addSubview:label];
//    
//    return view;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
//{
//    // Return the number of rows in the section.
//    return [fluxNearbyMetadata count];
//}
//
//- (float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
//    FluxAnnotationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"annotationsFeedCell"];
//    return cell.frame.size.height;
//}
//
//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    static NSString *CellIdentifier = @"annotationsFeedCell";
//    FluxAnnotationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
//    
//    if (cell == nil)
//    {
//        cell = [[FluxAnnotationTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
//                                                  reuseIdentifier:CellIdentifier];
//    }
//    [cell initCell];
//    
//    //hack to prevent crashes
//    if (indexPath.row > fluxNearbyMetadata.count-1) {
//        return cell;
//    }
//    NSNumber *objkey = [[fluxNearbyMetadata allKeys] objectAtIndex:indexPath.row];
//    FluxScanImageObject *rowObject = [fluxNearbyMetadata objectForKey: objkey];
//    
//    cell.imageID = rowObject.imageID;
//    
//# warning Currently extra overhead. Should fix this to get it locally first before requesting.
//    FluxDataRequest *dataRequest = [[FluxDataRequest alloc] init];
//    [dataRequest setRequestedIDs:[NSArray arrayWithObject:rowObject.localID]];
//    [dataRequest setImageReady:^(FluxLocalID *localID, UIImage *image, FluxDataRequest *completedDataRequest){
//        [cell.contentImageView setImage:image];
//    }];
//    [self.fluxDisplayManager.fluxDataManager requestImagesByLocalID:dataRequest withSize:thumb];
//
//    cell.descriptionLabel.text = rowObject.descriptionString;
//    cell.userLabel.text = [NSString stringWithFormat:@"User %i",rowObject.userID];
//    [cell.timestampLabel setText:[dateFormatter stringFromDate:rowObject.timestamp]];
//    [cell setCategory:rowObject.categoryID];
//    
//    return cell;
//}
//
////remove all but selected cell - not called right now
//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
//    //    NSMutableArray *cellIndicesToBeDeleted = [[NSMutableArray alloc] init];
//    //    for (int i = 0; i < [tableView numberOfRowsInSection:0]; i++) {
//    //        if (i != indexPath.row) {
//    //            NSIndexPath *p = [NSIndexPath indexPathForRow:i inSection:1];
//    //            [cellIndicesToBeDeleted addObject:p];
//    //        }
//    //    }
//    //    [tableView deleteRowsAtIndexPaths:cellIndicesToBeDeleted
//    //                     withRowAnimation:UITableViewRowAnimationFade];
//    //    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
//}
//
//- (void)scrollViewDidScroll:(UIScrollView *)scrollView
//{
//    [CATransaction begin];
//    [CATransaction setDisableActions:YES];
//    annotationsTableView.layer.mask.position = CGPointMake(0, scrollView.contentOffset.y);
//    [CATransaction commit];
//}

# pragma mark - View Transitions
- (void)presentMapView{
    [self performSegueWithIdentifier:@"pushMapModalView" sender:self];
}

- (void)pushImageAnnotationView{
    [self performSegueWithIdentifier:@"pushAnnotationModalView" sender:self];
}
- (IBAction)filterButtonAction:(id)sender {
    //[self performSegueWithIdentifier:@"pushFiltersView" sender:self];
}

#pragma mark - OpenGLView

-(void)setupOpenGLView{
    UIStoryboard *myStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard"
                                                           bundle:[NSBundle mainBundle]];

    
    
    // setup the opengl controller
    // first get an instance from storyboard
    openGLController = [myStoryboard instantiateViewControllerWithIdentifier:@"openGLViewController"];
    
    // then add the glkview as the subview of the parent view
    [self.view insertSubview:openGLController.view belowSubview:ScanUIContainerView];
    // add the glkViewController as the child of self
    [self addChildViewController:openGLController];
    //[openGLController didMoveToParentViewController:self];
    openGLController.view.frame = self.view.bounds;
    
    openGLController.fluxDisplayManager = self.fluxDisplayManager;
}

//this section commented out as the circular time slider was removed from the designs (perhaps temporarily)
#pragma mark - Time Filtering
- (void)setupTimeFilterControl{
    timeFilterControl.fluxDisplayManager = self.fluxDisplayManager;
}

- (void)setupGestureHandlers{
//    //pan
//    panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
//    [panGesture setMaximumNumberOfTouches:1];
//    [panGesture setDelegate:self];
//    [self.view addGestureRecognizer:panGesture];
//    
//    //longpress
//    longPressGesture = [[UILongPressGestureRecognizer alloc]
//                                               initWithTarget:self
//                                               action:@selector(handleLongPress:)];
//    [longPressGesture setNumberOfTouchesRequired:1];
//    longPressGesture.minimumPressDuration = 0.5;
//    [self.view addGestureRecognizer:longPressGesture];
}


//- (void)handleLongPress:(UILongPressGestureRecognizer *) sender{
//    //prevent multiple touches
//    if (![sender isEnabled]) return;
//    
//    if(sender.state == UIGestureRecognizerStateBegan)
//    {
//        [timeFilterControl showQuickPanCircleAtPoint:[sender locationInView:self.view]];
//    }
//    else if(sender.state == UIGestureRecognizerStateChanged)
//    {
//        [timeFilterControl quickPanDidSlideToPoint:[sender locationInView:self.view]];
//    }
//    
//    else if((sender.state == UIGestureRecognizerStateEnded) || ([sender state] == UIGestureRecognizerStateCancelled))
//    {
//        [timeFilterControl hideQuickPanCircle];
//    }
//    
//}
//
//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
//    return YES;
//}
//
////called during pan gesture, location is available as well as translation.
//- (void)handlePanGesture:(UIPanGestureRecognizer *)sender{
//
//    [timeFilterControl quickPanDidSlideToPoint:[sender locationInView:self.view]];
//    //close it if the gesture has ended
//    if (([sender state] == UIGestureRecognizerStateEnded) || ([sender state] == UIGestureRecognizerStateCancelled)) {
//        [timeFilterControl hideQuickPanCircle];
//    }
//    
//}
//
////limit to only vertical panning
//- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)panGestureRecognizer {
//    CGPoint translation = [panGestureRecognizer translationInView:self.view];
//    //if its vertical
//    if (fabs(translation.y) > fabs(translation.x)) {
//        [timeFilterControl showQuickPanCircleAtPoint:[panGestureRecognizer locationInView:self.view]];
//        return YES;
//    }
//    return NO;
//}






//
//-(void)pauseAVCapture
//{
//    [cameraManager pauseAVCapture];
//}

//restarts the capture session. The actual restart is an async call, with the UI adding a blur for the wait.
//-(void)restartAVCaptureWithBlur:(BOOL)blur
//{
//    //don't add a blur if we haven't captured an image yet.
//    if (capturedImage != nil && blur) {
//        [CameraButton setAlpha:0.0];
//        [blurView setImage:[self blurImage:capturedImage]];
//        [blurView setHidden:NO];
//        [UIView animateWithDuration:0.2 animations:^{
//            [blurView setAlpha:1.0];
//        }completion:nil];
//    }
//    
//    dispatch_async(AVCaptureBackgroundQueue, ^{
//        //start AVCapture
//        [cameraManager restartAVCapture];
//        dispatch_sync(dispatch_get_main_queue(), ^{
//            //completion callback
//            if (blur && capturedImage) {
//                [UIView animateWithDuration:0.2 animations:^{
//                    [blurView setAlpha:0.0];
//                    [CameraButton setAlpha:1.0];
//                }completion:^(BOOL finished){
//                    [blurView setHidden:YES];
//                    capturedImage = nil;
//                }];
//            }
//        });
//    });
//}

#pragma mark Camera View

- (void)setupCameraView{
    
    [progressView setAlpha:0.0];

    
    
    
    blurView = [[UIImageView alloc]initWithFrame:self.view.bounds];
    [blurView setBackgroundColor:[UIColor clearColor]];
    [blurView setAlpha:0.0];
    [blurView setHidden:YES];
    [self.view addSubview:blurView];
    
    [self performSelector:@selector(fixCameraButtonPosition) withObject:nil afterDelay:0.0f];
    [radarButton addTarget:self action:@selector(presentMapView) forControlEvents:UIControlEventTouchUpInside];
}

- (void)fixCameraButtonPosition{
    [CameraButton removeFromSuperview];
    [CameraButton setTranslatesAutoresizingMaskIntoConstraints:YES];
    [self.view insertSubview:CameraButton aboveSubview:ScanUIContainerView];
}

- (IBAction)cameraButtonAction:(id)sender {
    if (!imageCaptureIsActive) {
        [openGLController showImageCapture];
        [self activateImageCapture];
    }
    else{
        [openGLController.imageCaptureViewController takePicture];
    }
}

- (void)activateImageCapture{
    [[CameraButton getThumbView] setHidden:NO];
    [UIView animateWithDuration:0.3f
                     animations:^{
                         [ScanUIContainerView setAlpha:0.0];
                         [[CameraButton getThumbView] setAlpha:1.0];
                         [CameraButton setCenter:CGPointMake(CameraButton.center.x, CameraButton.center.y-21)];
                     }
                     completion:^(BOOL finished){
                         //stops drawing them
                         [ScanUIContainerView setHidden:YES];
                         [self startDeviceMotion];
                         imageCaptureIsActive = YES;
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

- (void)deactivateImageCapture{
    [self stopDeviceMotion];
    [ScanUIContainerView setHidden:NO];
    
    [UIView animateWithDuration:0.3f
                     animations:^{
                         [ScanUIContainerView setAlpha:1.0];
                         [CameraButton setCenter:CGPointMake(CameraButton.center.x, CameraButton.center.y+21)];
                         [[CameraButton getThumbView] setAlpha:0.0];
                     }
                     completion:^(BOOL finished){
                         //stops drawing them
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
    
    imageCaptureIsActive = NO;
}

- (void)imageCaptureDidPop:(NSNotification *)notification{
    if ([notification userInfo]) {
        NSArray*objectsArr = [notification.userInfo objectForKey:@"capturedImageObjects"];
        NSArray*imagesArr = [notification.userInfo objectForKey:@"capturedImages"];
        
        [UIView animateWithDuration:0.1f
                         animations:^{
                             [progressView setAlpha:1.0];
                             [progressView setProgress:0.0];
                         }
                         completion:nil];
        
        uploadsCompleted = 0;
        totalUploads = objectsArr.count;
        
        for (int i = 0; i<objectsArr.count; i++) {
            // Add the image and metadata to the local cache
            FluxDataRequest *dataRequest = [[FluxDataRequest alloc] init];
            [dataRequest setUploadComplete:^(FluxScanImageObject *updatedImageObject, FluxDataRequest *completedDataRequest){
                if ([self.fluxDisplayManager.fluxNearbyMetadata objectForKey:updatedImageObject.localID] != nil)
                {
                    // FluxScanImageObject exists in the local cache. Replace it with updated object.
                    [self.fluxDisplayManager.fluxNearbyMetadata setObject:updatedImageObject forKey:updatedImageObject.localID];
                }
                uploadsCompleted++;
                progressView.progress = uploadsCompleted/totalUploads;
                
                if (progressView.progress == 1) {
                    [self performSelector:@selector(hideProgressView) withObject:nil afterDelay:0.5];
                }
            }];
            [dataRequest setUploadInProgress:^(FluxScanImageObject *imageObject, FluxDataRequest *inProgressDataRequest){
                
            }];
            [dataRequest setErrorOccurred:^(NSError *e, FluxDataRequest *errorDataRequest){
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Image Upload Failed with error %d", (int)[e code]]
                                                                    message:[e localizedDescription]
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                [alertView show];
                
                [UIView animateWithDuration:0.2f
                                 animations:^{
                                     [progressView setAlpha:0.0];
                                 }
                                 completion:^(BOOL finished){
                                     progressView.progress = 0;
                                 }];
            }];
            
            // Post notification for observers prior to upload
//            NSDictionary *userInfoDict = @{FluxScanViewDidAcquireNewPictureLocalIDKey : capturedImageObject.localID};
//            [[NSNotificationCenter defaultCenter] postNotificationName:FluxScanViewDidAcquireNewPicture
//                                                                object:self userInfo:userInfoDict];
            
            [self.fluxDisplayManager.fluxDataManager addDataToStore:[objectsArr objectAtIndex:i] withImage:[imagesArr objectAtIndex:i] withDataRequest:dataRequest];
        }
        

    }
    [self deactivateImageCapture];
}

-(void)hideProgressView{
    [UIView animateWithDuration:1.2f
                     animations:^{
                         [progressView setAlpha:0.0];
                     }];
}



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

#pragma mark - view lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    //[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateImageList:) name:FluxDisplayManagerDidUpdateOpenGLDisplayList object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdatePlacemark:) name:FluxLocationServicesSingletonDidUpdatePlacemark object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageCaptureDidPop:) name:FluxImageCaptureDidPop object:nil];
    [locationLabel setFont:[UIFont fontWithName:@"Akkurat" size:locationLabel.font.pointSize]];
    [timeFilterControl setHidden:YES];
    [timeFilterControl setAlpha:0.0];
    
    [self setupGestureHandlers];
    [self setupCameraView];
    [self setupMotionManager];
    [self setupOpenGLView];
    [self setupTimeFilterControl];

    // Start the location manager service which will continue for the life of the app
    locationManager = [FluxLocationServicesSingleton sharedManager];
    [locationManager startLocating];
    
    currentDataFilter = [[FluxDataFilter alloc] init];
    
    self.screenName = @"Scan View";
}

- (void)viewWillAppear:(BOOL)animated{
    [radarButton updateRadarWithNewMetaData:self.fluxDisplayManager.fluxNearbyMetadata];
    //[self restartAVCaptureWithBlur:YES];
}

- (void)FiltersTableViewDidPop:(FluxFiltersTableViewController *)filtersTable andChangeFilter:(FluxDataFilter *)dataFilter{
    [self animationPopFrontScaleUp];
    
    if (![dataFilter isEqualToFilter:currentDataFilter] && dataFilter !=nil) {
        NSDictionary *userInfoDict = @{@"filter" : dataFilter};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FluxFilterViewDidChangeFilter" object:self userInfo:userInfoDict];
        currentDataFilter = [dataFilter copy];
    }
    
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"pushMapModalView"])
    {
        mapViewController = (FluxMapViewController *)segue.destinationViewController;
        mapViewController.fluxDisplayManager = self.fluxDisplayManager;
    }
    else if ([[segue identifier] isEqualToString:@"pushFiltersView"]){
        //set the delegate of the navControllers top view (our filters View)
        UINavigationController*tmp = segue.destinationViewController;
        FluxFiltersTableViewController* filtersVC = (FluxFiltersTableViewController*)tmp.topViewController;
        [filtersVC setDelegate:self];
        [filtersVC setFluxDataManager:self.fluxDisplayManager.fluxDataManager];
        [filtersVC prepareViewWithFilter:currentDataFilter];
        
        [self animationPushBackScaleDown];
    }
}

- (void)viewWillDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxLocationServicesSingletonDidUpdatePlacemark object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc
{
    [locationManager endLocating];
    locationManager = nil;
}



#pragma mark - View Transition Animations
/*
 UIViewController+HCPushBackAnimation is licensed under MIT License Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#define HC_DEFINE_TO_SCALE (CATransform3DMakeScale(0.95, 0.95, 0.95))
#define HC_DEFINE_TO_OPACITY (0.4f)


-(void) animationPushBackScaleDown {
	CABasicAnimation* scaleDown = [CABasicAnimation animationWithKeyPath:@"transform"];
	scaleDown.toValue = [NSValue valueWithCATransform3D:HC_DEFINE_TO_SCALE];
	scaleDown.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
	scaleDown.removedOnCompletion = YES;
	
	CABasicAnimation* opacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
	opacity.fromValue = [NSNumber numberWithFloat:1.0f];
	opacity.toValue = [NSNumber numberWithFloat:HC_DEFINE_TO_OPACITY];
	opacity.removedOnCompletion = YES;
	
	CAAnimationGroup* group = [CAAnimationGroup animation];
	group.duration = 0.4;
	group.animations = [NSArray arrayWithObjects:scaleDown, opacity, nil];
	
	UIView* view = self.navigationController.view?self.navigationController.view:self.view;
	[view.layer addAnimation:group forKey:nil];
}

-(void) animationPopFrontScaleUp {
	CABasicAnimation* scaleUp = [CABasicAnimation animationWithKeyPath:@"transform"];
	scaleUp.toValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
	scaleUp.fromValue = [NSValue valueWithCATransform3D:HC_DEFINE_TO_SCALE];
	scaleUp.removedOnCompletion = YES;
	
	CABasicAnimation* opacity = [CABasicAnimation animationWithKeyPath:@"opacity"];
	opacity.fromValue = [NSNumber numberWithFloat:HC_DEFINE_TO_OPACITY];
	opacity.toValue = [NSNumber numberWithFloat:1.0f];
	opacity.removedOnCompletion = YES;
	
	CAAnimationGroup* group = [CAAnimationGroup animation];
	group.duration = 0.43;
	group.animations = [NSArray arrayWithObjects:scaleUp, opacity, nil];
	
	UIView* view = self.navigationController.view?self.navigationController.view:self.view;
	[view.layer addAnimation:group forKey:nil];
}



@end



