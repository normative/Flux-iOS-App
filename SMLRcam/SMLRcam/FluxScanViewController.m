//
//  SMLRcamViewController.m
//  SMLRcam
//
//  Created by Kei Turner on 7/4/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxScanViewController.h"

#import "FluxAnnotationTableViewCell.h"
#import "FluxDebugViewController.h"
#import "FluxImageRenderElement.h"
#import "FluxImageTools.h"
#import "FluxLeftDrawerViewController.h"
#import "FluxPedometer.h"
#import "FluxTimeFilterControl.h"
#import "ProgressHUD.h"
#import "UICKeyChainStore.h"
#import "FluxDeviceInfoSingleton.h"

#import <ImageIO/ImageIO.h>
#import "GAI.h"
#import "GAIDictionaryBuilder.h"

#define IS_RETINA ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && ([UIScreen mainScreen].scale == 2.0))
#define IS_4INCHSCREEN  ([[UIScreen mainScreen] bounds].size.height == 568)?TRUE:FALSE

NSString* const FluxScanViewDidAcquireNewPicture = @"FluxScanViewDidAcquireNewPicture";
NSString* const FluxScanViewDidAcquireNewPictureLocalIDKey = @"FluxScanViewDidAcquireNewPictureLocalIDKey";

@implementation FluxScanViewController

@synthesize timeFilterControl;

- (void)didUpdateNearbyImageList:(NSNotification *)notification{
    [filterButton setTitle:[NSString stringWithFormat:@"%i",self.fluxDisplayManager.nearbyListCount] forState:UIControlStateNormal];
    if (firstContent && self.fluxDisplayManager.nearbyListCount > 5) {
        NSLog(@"FIRST TIME");
        firstContent = NO;
        [timeFilterControl setViewForContentCount:self.fluxDisplayManager.nearbyListCount reverseAnimated:YES];
        
//        [UIView animateWithDuration:3.0
//                              delay:0
//                            options:UIViewAnimationOptionCurveEaseInOut
//                         animations:^{ [timeFilterControl.timeScrollView scrollRectToVisible:CGRectMake(0, 0, 320, 5) animated:NO]; }
//                         completion:NULL];
    }
    else{
        [timeFilterControl setViewForContentCount:self.fluxDisplayManager.nearbyListCount reverseAnimated:NO];
    }
}

#pragma mark - Location Services

- (void)kalmanStateChange
{
    bool currentKalmanStateValid = [self.fluxDisplayManager.locationManager isKalmanSolutionValid];
    if (currentKalmanStateValid) {
        [self.cameraButton setAlpha:1.0];
    }
    else{
        [self.cameraButton setAlpha:0.4];
    }
    NSLog(@"Kalman state changed. Photo acquisition %@.", currentKalmanStateValid ? @"enabled" : @"disabled");
}

- (void)didTakeStepWithPedometer:(NSNotification*)notification
{
    if ([notification userInfo])
    {
        NSNumber *stepCount = [[notification userInfo] objectForKey:FluxPedometerDidTakeStepCountKey];
        [pedometerLabel setText:[stepCount stringValue]];
    }
}

- (void)setupDebugPedometerCountDisplay
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    bool enablePedometerDisplay = [[defaults objectForKey:FluxDebugPedometerCountDisplayKey] boolValue];
    
    [pedometerLabel setHidden:(!enablePedometerDisplay)];
}

#pragma mark - Drawer Methods

// Left Drawer
- (IBAction)showLeftDrawer:(id)sender {
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(setSettingsViewBG:) name:@"didCaptureBackgroundSnapshot" object:nil];
    [openGLController setBackgroundSnapFlag];
}


- (void)setSettingsViewBG:(NSNotification*)notification{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"didCaptureBackgroundSnapshot" object:nil];
    
    snapshotBGImage = (UIImage*)[[notification userInfo] objectForKey:@"snapshot"];
    FluxImageTools *imageTools = [[FluxImageTools alloc]init];
    snapshotBGImage = [imageTools blurImage:snapshotBGImage withBlurLevel:0.6];

    [self performSegueWithIdentifier:@"pushSettingsView" sender:self];
    
}



#pragma mark - Annotations Feed Methods

//show list of images currently visible.
- (void)setupAnnotationsTableView{
    annotationsTableView = [[UITableView alloc]initWithFrame:CGRectMake(7, 80, self.view.frame.size.width-14, self.view.frame.size.height-200)];
    [annotationsTableView setHidden:YES];
    [annotationsTableView setAlpha:0.0];
    [annotationsTableView setBackgroundColor:[UIColor clearColor]];
    [annotationsTableView setSeparatorColor:[UIColor clearColor]];
    [annotationsTableView setAllowsSelection:NO];
    [annotationsTableView setDelegate:self];
    [annotationsTableView setDataSource:self];
    
    [annotationsTableView registerNib:[UINib nibWithNibName:@"FluxAnnotationTableViewCell" bundle:nil] forCellReuseIdentifier:@"annotationsFeedCell"];

    [self.view addSubview:annotationsTableView];
}


- (IBAction)annotationsButtonAction:(id)sender {
    if ([annotationsTableView isHidden]) {
        if (self.fluxDisplayManager.nearbyListCount > 0) {
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
        [imageCaptureButton setUserInteractionEnabled:NO];
    }
    else{
        [UIView animateWithDuration:0.3f
                         animations:^{
                             [annotationsTableView setAlpha:0.0];
                         }
                         completion:^(BOOL finished){
                             [annotationsTableView setHidden:YES];
                             [imageCaptureButton setUserInteractionEnabled:YES];
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
    label.frame = CGRectMake(12, 0, 100, 22);
    label.textColor = [UIColor lightGrayColor];
    [label setFont:[UIFont fontWithName:@"Akkurat" size:14]];
    label.text = [self tableView:tableView titleForHeaderInSection:section];
    label.backgroundColor = [UIColor clearColor];
    
    UIView*backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, annotationsTableView.frame.size.width, 24)];
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
    return self.fluxDisplayManager.nearbyListCount;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
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
    
    //hack to prevent crashes
    if (indexPath.row > self.fluxDisplayManager.nearbyListCount-1) {
        return cell;
    }
//    NSNumber *objkey = [self.fluxDisplayManager.nearbyList objectAtIndex:indexPath.row];
    FluxImageRenderElement *ire = [self.fluxDisplayManager.nearbyList objectAtIndex:indexPath.row];
    FluxScanImageObject *rowObject = ire.imageMetadata;
    
    cell.imageID = rowObject.imageID;
    
# warning Currently extra overhead. Should fix this to get it locally first before requesting.
    FluxDataRequest *dataRequest = [[FluxDataRequest alloc] init];
    [dataRequest setRequestedIDs:[NSMutableArray arrayWithObject:rowObject.localID]];
    [dataRequest setImageReady:^(FluxLocalID *localID, FluxCacheImageObject *imageCacheObj, FluxDataRequest *completedDataRequest){
        [cell.contentImageView setImage:imageCacheObj.image];
    }];
    [self.fluxDisplayManager.fluxDataManager requestImagesByLocalID:dataRequest withSize:thumb];

    cell.descriptionLabel.text = rowObject.descriptionString;
    cell.userLabel.text = [NSString stringWithFormat:@"User %i",rowObject.userID];
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

# pragma mark - MapView
- (void)presentMapView{
    [self performSegueWithIdentifier:@"pushMapModalView" sender:self];
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
    [timeFilterControl setScrollIndicatorCenter:CGPointMake(self.view.center.x, radarButton.center.y)];
    [timeFilterControl setDelegate:self];
}

-(void)userIsTimeSliding{
    NSString*startDate = [dateFormatter stringFromDate:[self.fluxDisplayManager earliestDisplayDate]];
    NSString*endDate = [dateFormatter stringFromDate:[self.fluxDisplayManager latestDisplayDate]];
    if (startDate && endDate) {
        if ([startDate isEqualToString:endDate]) {
            [dateRangeLabel setText:[NSString stringWithFormat:@"%@", startDate] animated:YES];
        }
        else{
            [dateRangeLabel setText:[NSString stringWithFormat:@"%@ - %@",startDate, endDate] animated:YES];
        }
        
        //set it visible
        if (dateRangeLabel.alpha == 0) {
            [UIView animateWithDuration:0.2 animations:^{
                [dateRangeLabel setAlpha:1.0];
            }];
        }
        
        //update hide timer
        [dateRangeLabelHideTimer invalidate];
        dateRangeLabelHideTimer = nil;
        dateRangeLabelHideTimer = [NSTimer scheduledTimerWithTimeInterval:0.7 target:self selector:@selector(hideDateRangeLabel) userInfo:nil repeats:NO];
    }
}

- (void)hideDateRangeLabel{
    [UIView animateWithDuration:1.0 animations:^{
        [dateRangeLabel setAlpha:0.0];
    }];
}

#pragma mark - Tapping images
- (void)timeFilterControl:(FluxTimeFilterControl *)timeControl didTapAtPoint:(CGPoint)point{
    if (IS_RETINA) {
        [openGLController imageTappedAtPoint:CGPointMake(point.x*2, point.y*2)];
        _point = CGPointMake(point.x*2, point.y*2);
    }
    else{
        [openGLController imageTappedAtPoint:point];
        _point = point;
    }
}

- (void)photoBrowser:(IDMPhotoBrowser *)photoBrowser didDismissAtPageIndex:(NSUInteger)index{
    [photoViewerPlacementView removeFromSuperview];
}

-(void) didTapImageFunc:(FluxScanImageObject*)tappedImageObject withBGImage:(UIImage *)bgImage
{
    FluxImageTools *imageTools = [[FluxImageTools alloc]init];
    snapshotBGImage = [imageTools blurImage:bgImage withBlurLevel:0.6];
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"     // Event category (required)
                                                          action:@"action"  // Event action (required)
                                                           label:@"tap image"          // Event label
                                                           value:nil] build]];    // Event value
    if(tappedImageObject == nil)
        return;
    
    FluxImageType actualType = none;
    
    IDMPhoto *photo = nil;
    
    FluxImageType ghrq = [[FluxDeviceInfoSingleton sharedDeviceInfo] highestResToQuery];

    FluxCacheImageObject *imageCacheObj = [self.fluxDisplayManager.fluxDataManager fetchImageByImageID:tappedImageObject.imageID withSize:ghrq returnSize:&actualType];
    if (actualType >= ghrq)
    {
        photo = [[IDMPhoto alloc]initWithImage:imageCacheObj.image];
        [imageCacheObj endContentAccess];
    }
    else if (tappedImageObject.imageID > 0)
    {
        // last resort
        NSString*urlString = [NSString stringWithFormat:@"%@images/%i/renderimage?size=%@",FluxServerURL,tappedImageObject.imageID, fluxImageTypeStrings[ghrq]];
        photo = [[IDMPhoto alloc] initWithURL:[NSURL URLWithString:urlString]];
    }
    
    photo.userID = tappedImageObject.userID;
    photo.caption = tappedImageObject.descriptionString;
    photo.username = tappedImageObject.username;
    NSDateFormatter*tmpdateFormatter = [[NSDateFormatter alloc]init];
    [tmpdateFormatter setDateFormat:@"MMM dd, yyyy - h:mma"];
    photo.timestring = [tmpdateFormatter stringFromDate:tappedImageObject.timestamp];
    NSMutableArray *photos = [[NSMutableArray alloc]initWithObjects:photo, nil];
    
    if (!photoViewerPlacementView) {
        photoViewerPlacementView = [[UIView alloc]init];
    }
    [ScanUIContainerView addSubview:photoViewerPlacementView];
    if (IS_RETINA) {
        _point = CGPointMake(_point.x/2, _point.y/2);
    }
    [photoViewerPlacementView setFrame:CGRectMake(0, 0, 40, 40)];
    [photoViewerPlacementView setCenter:CGPointMake(_point.x, _point.y)];
    IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:photos animatedFromView:photoViewerPlacementView];
    [browser setDelegate:self];
    [browser setDisplayToolbar:NO];
    //[browser setDisplayDoneButtonBackgroundImage:NO];
    UINavigationController*nav = [[UINavigationController alloc]initWithRootViewController:browser];
    [nav.view setBackgroundColor:[UIColor clearColor]];
    
    UIImageView*bgView = [[UIImageView alloc]initWithFrame:self.view.frame];
    [bgView setImage:snapshotBGImage];
    [bgView setBackgroundColor:[UIColor darkGrayColor]];
    [nav.view insertSubview:bgView atIndex:0];
    
    [self presentViewController:nav animated:YES completion:nil];
   
}

#pragma mark Camera View

- (void)setupCameraView{
    
    [progressView setAlpha:0.0];
    
    blurView = [[UIImageView alloc]initWithFrame:self.view.bounds];
    [blurView setBackgroundColor:[UIColor clearColor]];
    [blurView setAlpha:0.0];
    [blurView setHidden:YES];
    [self.view addSubview:blurView];
    dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"MMM dd, yyyy"];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    
    filterButton.contentEdgeInsets = UIEdgeInsetsMake(0.0, 1.0, 0.0, 0.0);
    
    [dateRangeLabel setFont:[UIFont fontWithName:@"Akkurat" size:15]];
    [dateRangeLabel setTextColor:[UIColor whiteColor]];
    [dateRangeLabel setTextAlignment:NSTextAlignmentCenter];
    dateRangeLabel.transitionEffect = BBCyclingLabelTransitionEffectCrossFade;
    dateRangeLabel.transitionDuration = 0.2;
    
    [radarButton addTarget:self action:@selector(presentMapView) forControlEvents:UIControlEventTouchUpInside];
    
    [imageCaptureButton.button addTarget:self action:@selector(imageCaptureButtonAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (IBAction)cameraButtonAction:(id)sender {
    
    if (self.cameraButton.alpha < 1.0)
    {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Uh oh..."
                                                          message:@"Taking pictures is disabled because the device's location accuracy is poor. Try going outside, or avoid standing next to large metal objects."
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        [message show];
    }
    else
    {
        if (historicalPhotoPickerEnabled)
        {
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            picker.delegate = self;
            picker.allowsEditing = YES;
            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            
            [self presentViewController:picker animated:YES completion:NULL];
        }
        else
        {
            [self configureNewCameraCapture];
        }
    }
}

- (void)configureNewCameraCaptureWithImage:(UIImage *)image
{
    [openGLController activateNewImageCaptureWithImage:image];
    [self activateImageCaptureForMode:camera_mode];
}

- (void)configureNewCameraCapture
{
    [self configureNewCameraCaptureWithImage:nil];
}

- (IBAction)imageCaptureButtonAction:(id)sender {
    if (imageCaptureButton.captureMode == snapshot_mode) {
        [[NSNotificationCenter defaultCenter]addObserver:openGLController.snapshotViewController selector:@selector(addsnapshot:) name:@"didCaptureBackgroundSnapshot" object:nil];
    
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"     // Event category (required)
                                                              action:@"action"  // Event action (required)
                                                               label:@"take snapshot"          // Event label
                                                               value:nil] build]];    // Event value
        
        [openGLController setBackgroundSnapFlag];
        [imageCaptureButton setHidden:YES];
    }
    else{
        [openGLController.imageCaptureViewController takePicture];
        [imageCaptureButton addImageCapture];

    }
    
}

- (void)activateSnapshotView{
    [UIView animateWithDuration:0.3f
                     animations:^{
                         [ScanUIContainerView setAlpha:0.0];
                         [imageCaptureButton setAlpha:0.0];
                         
                         
                         
                     }
                     completion:^(BOOL finished){
                         //stops drawing them
                         [self.bottomToolbarView setHidden:YES];
                         [ScanUIContainerView setHidden:YES];
                         imageCaptureIsActive = YES;
                     }];
}

- (void)deactivateSnapshotView{
    [ScanUIContainerView setHidden:NO];
    [self.bottomToolbarView setHidden:NO];
    
    [UIView animateWithDuration:0.3f
                     animations:^{
                         
                         [self.bottomToolbarView setAlpha:1.0];
                         [ScanUIContainerView setAlpha:1.0];
                         [imageCaptureButton setAlpha:1.0];
                     }
                     completion:^(BOOL finished){
                     }];
    imageCaptureIsActive = NO;
}

- (void)activateImageCaptureForMode:(FluxImageCaptureMode)captureMode{
    [imageCaptureButton setHidden:NO];
    [imageCaptureButton setCaptureMode:captureMode];
    [imageCaptureButton setSingleImageCaptureMode:historicalPhotoPickerEnabled];
    [UIView animateWithDuration:0.3f
                     animations:^{
                         [imageCaptureButton setAlpha:1.0];
                         [ScanUIContainerView setAlpha:0.0];
                         if (IS_4INCHSCREEN) {
                             [imageCaptureButton setCenter:CGPointMake(imageCaptureButton.center.x, imageCaptureButton.center.y-21)];
                         }
                         else{
                             [imageCaptureButton setCenter:CGPointMake(imageCaptureButton.center.x, imageCaptureButton.center.y+2)];
                         }
                         
                         
                         [self.bottomToolbarView setAlpha:0.0];
                         self.bottomToolbarView.center = CGPointMake(self.bottomToolbarView.center.x, self.bottomToolbarView.center.y+30);
                     }
                     completion:^(BOOL finished){
                         //stops drawing them
                         [ScanUIContainerView setHidden:YES];
                         [self.bottomToolbarView setHidden:YES];
                         imageCaptureIsActive = YES;
                     }];
    
    CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    bounceAnimation.values = [NSArray arrayWithObjects:
                              [NSNumber numberWithFloat:1.0],
                              [NSNumber numberWithFloat:1.5],
                              [NSNumber numberWithFloat:0.8],
                              [NSNumber numberWithFloat:1.0], nil];
    bounceAnimation.duration = 0.3;
    
    [imageCaptureButton.layer addAnimation:bounceAnimation forKey:@"bounce_open"];
}

- (void)deactivateImageCapture
{
    //check if it's already de-activated
    if (ScanUIContainerView.isHidden) {
        [ScanUIContainerView setHidden:NO];
        [self.bottomToolbarView setHidden:NO];
        
        [UIView animateWithDuration:0.3f
                         animations:^{
                             [imageCaptureButton setAlpha:0.0];
                             [ScanUIContainerView setAlpha:1.0];
                             if (IS_4INCHSCREEN) {
                                 [imageCaptureButton setCenter:CGPointMake(imageCaptureButton.center.x, imageCaptureButton.center.y+21)];
                             }
                             else{
                                 [imageCaptureButton setCenter:CGPointMake(imageCaptureButton.center.x, imageCaptureButton.center.y-2)];
                             }
                             
                             
                             [self.bottomToolbarView setAlpha:1];
                             self.bottomToolbarView.center = CGPointMake(self.bottomToolbarView.center.x, self.bottomToolbarView.center.y-30);
                         }
                         completion:^(BOOL finished){
                             //stops drawing them
                             [imageCaptureButton setHidden:YES];
                         }];
        
        CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
        bounceAnimation.values = [NSArray arrayWithObjects:
                                  [NSNumber numberWithFloat:1.0],
                                  [NSNumber numberWithFloat:0.7],
                                  [NSNumber numberWithFloat:0.9],
                                  [NSNumber numberWithFloat:1.0], nil];
        bounceAnimation.duration = 0.3;
        [imageCaptureButton.layer addAnimation:bounceAnimation forKey:@"bounce_closed"];
        [imageCaptureButton restoreAllImages];
        
        imageCaptureIsActive = NO;
    }

}

- (void)imageCaptureDidPop:(NSNotification *)notification{

    if ([notification userInfo]) {
        if (![(NSNumber*)[[notification userInfo] objectForKey:@"snapshot"]boolValue]) {
            id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
            [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"event"     // Event category (required)
                                                                  action:@"action"  // Event action (required)
                                                                   label:@"uploaded image to flux"          // Event label
                                                                   value:nil] build]];    // Event value
            
            [self uploadImages:notification.userInfo];
        }
        
        if ([(NSArray*)[notification.userInfo objectForKey:@"social"]count] > 0) {
            FluxSocialManager*socialManager = [[FluxSocialManager alloc]init];
            [socialManager setDelegate:self];
            
            [socialManager socialPostTo:[notification.userInfo objectForKey:@"social"]
                             withStatus:[notification.userInfo objectForKey:@"annotation"]
                               andImage:(UIImage*)[(NSArray*)[notification.userInfo objectForKey:@"capturedImages"]firstObject] andSnapshot:[(NSNumber*)[[notification userInfo] objectForKey:@"snapshot"]boolValue]];
            
            if ([(NSArray*)[notification.userInfo objectForKey:@"social"]containsObject:TwitterService]) {
                id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
                [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"event"     // Event category (required)
                                                                      action:@"action"  // Event action (required)
                                                                       label:@"shared image to twitter"          // Event label
                                                                       value:nil] build]];    // Event value
            }
            if ([(NSArray*)[notification.userInfo objectForKey:@"social"]containsObject:FacebookService]) {
                id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
                [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"event"     // Event category (required)
                                                                      action:@"action"  // Event action (required)
                                                                       label:@"shared image to facebook"          // Event label
                                                                       value:nil] build]];    // Event value
            }
        }
    }    
    
    //view cleanup
    if (openGLController.imageCaptureViewController.isSnapshot) {
        [self deactivateImageCapture];
        openGLController.imageCaptureViewController.isSnapshot = NO;
    }
    else{
        [self deactivateImageCapture];
    }
}

- (void)uploadImages:(NSDictionary*)imagesDict{
    NSArray*objectsArr = [imagesDict objectForKey:@"capturedImageObjects"];
    NSArray*imagesArr = [imagesDict objectForKey:@"capturedImages"];
    UIImage *historicalImg = [imagesDict objectForKey:@"historicalImage"];
    
    [UIView animateWithDuration:0.1f
                     animations:^{
                         [progressView setAlpha:1.0];
                         [progressView setProgress:0.0];
                     }
                     completion:nil];
    
    uploadsCompleted = 0;
    totalUploads = (int)objectsArr.count;
    NSMutableArray*requestsArray = [[NSMutableArray alloc]init];
    __block float totalBytes = 0;
    __block float progress = 0;
    
    for (int i = 0; i<objectsArr.count; i++) {
        // Add the image and metadata to the local cache
        
        FluxDataRequest *dataRequest = [[FluxDataRequest alloc] init];
        [dataRequest setUploadComplete:^(FluxScanImageObject *updatedImageObject, FluxDataRequest *completedDataRequest){
            // FluxScanImageObject exists in the local cache. Replace it with updated object.
            // actually, no.  The current ire.imageMetadata is more up-to-date than the "updated" one as it has rendering and homography data, etc.
            // The imageID has already been updated
            // FluxImageRenderElement *ire = [self.fluxDisplayManager getRenderElementForKey:updatedImageObject.localID];
            // if (ire != nil)
            // {
            //     ire.imageMetadata = updatedImageObject;
            // }
            
            uploadsCompleted++;
            float doneTest = uploadsCompleted/totalUploads;
            
            if (doneTest == 1) {
                [progressView setProgress:1.0 animated:YES];
                [self performSelector:@selector(hideProgressView) withObject:nil afterDelay:0.5];
            }
        }];
        [dataRequest setUploadInProgress:^(FluxScanImageObject *imageObject, FluxDataRequest *inProgressDataRequest){
            if (requestsArray.count < totalUploads) {
                if (![requestsArray containsObject:[NSNumber numberWithInt:(int)inProgressDataRequest.totalByteSize]]) {
                    totalBytes += inProgressDataRequest.totalByteSize;
                    [requestsArray addObject:[NSNumber numberWithInt:(int)inProgressDataRequest.totalByteSize]];
                }
            }
            
            progress+=inProgressDataRequest.bytesUploaded;
            [progressView setProgress:(float)progress/totalBytes-0.10 animated:YES];
        }];
        [dataRequest setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Image Upload Failed :("
                                                                message:@"Something happened when uploading one of your images, we're really sorry about that."
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
        [self.fluxDisplayManager.fluxDataManager uploadImageryData:[objectsArr objectAtIndex:i] withImage:[imagesArr objectAtIndex:i] withDataRequest:dataRequest withHistoricalImage:historicalImg];
    }
}

#pragma mark Social Manager Delegate


-(void)SocialManager:(FluxSocialManager *)socialManager didMakeSocialPosts:(NSArray *)socialPartners{
    
}

- (void)SocialManager:(FluxSocialManager *)socialManager didFailToMakeSocialPostWithType:(NSString *)socialType{
    [ProgressHUD showError:[NSString stringWithFormat:@"Failed to post to %@",socialType]];
}

#pragma mark Friend Requests
- (void)checkForFollowerRequests{
    FluxDataRequest*request = [[FluxDataRequest alloc]init];
    
    [request setUserFollowerRequestsReady:^(NSArray*requestsArr, FluxDataRequest*completedRequest){
        //do something with the UserID
        if (requestsArr.count>0) {
            [friendRequestsBadge setBadgeText:[NSString stringWithFormat:@"%i",(int)requestsArr.count]];
            [friendRequestsBadge setFrame:CGRectMake(self.leftDrawerButton.frame.size.width-20-friendRequestsBadge.frame.size.width/2, self.leftDrawerButton.frame.origin.y+10, friendRequestsBadge.frame.size.width, friendRequestsBadge.frame.size.height)];
            if (!friendRequestsBadge.superview) {
                [self.leftDrawerButton addSubview:friendRequestsBadge];
            }
        }
        else{
            [friendRequestsBadge setBadgeText:@""];
            [friendRequestsBadge removeFromSuperview];
        }
    }];
    
    [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
        
        NSLog(@"follower request check failed with error %d",(int)[e code]);
    }];
    [self.fluxDisplayManager.fluxDataManager requestFollowingRequestsForUserWithDataRequest:request];
}

#pragma mark Other Camera view methods


-(void)hideProgressView{
    [UIView animateWithDuration:1.2f
                     animations:^{
                         [progressView setAlpha:0.0];
                     }];
}

- (void)setCameraButtonEnabled:(BOOL)enabled{
    [imageCaptureButton.button setEnabled:enabled];
}

- (IBAction)snapshotButtonAction:(id)sender {
    [openGLController activateSnapshotCapture];
    [self activateImageCaptureForMode:snapshot_mode];
}

- (void)setupHistoricalPhotoPicker
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    historicalPhotoPickerEnabled = [[defaults objectForKey:FluxDebugHistoricalPhotoPickerKey] boolValue];
    
    //    [pedometerLabel setHidden:(!enablePedometerDisplay)];
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

#pragma mark - FiltersView

- (IBAction)filterButtonAction:(id)sender {
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(setFiltersViewBG:) name:@"didCaptureBackgroundSnapshot" object:nil];
    [openGLController setBackgroundSnapFlag];
}

- (void)setFiltersViewBG:(NSNotification*)notification{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"didCaptureBackgroundSnapshot" object:nil];
    
    snapshotBGImage = (UIImage*)[[notification userInfo] objectForKey:@"snapshot"];
    FluxImageTools *imageTools = [[FluxImageTools alloc]init];
    snapshotBGImage = [imageTools blurImage:snapshotBGImage withBlurLevel:0.6];
    
    [self performSegueWithIdentifier:@"pushFiltersView" sender:self];
    
}

- (void)setCurrentDataFilter:(FluxDataFilter *)currentDataFilter{
    if (![_currentDataFilter isEqualToFilter:currentDataFilter]) {
        NSDictionary *userInfoDict = @{@"filter" : currentDataFilter};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FluxFilterViewDidChangeFilter" object:self userInfo:userInfoDict];
        _currentDataFilter = currentDataFilter;
    }
    _currentDataFilter = currentDataFilter;
    
    [self updateFilterIcon];
}

- (void)updateFilterIcon{
    if ([self.currentDataFilter isEqualToFilter:[[FluxDataFilter alloc]init]]) {
        [filterButton setBackgroundImage:[UIImage imageNamed:@"filterButton"] forState:UIControlStateNormal];
    }
    else{
        [filterButton setBackgroundImage:[UIImage imageNamed:@"FilterButton_active"] forState:UIControlStateNormal];
    }
}

#pragma mark Filters Delegate

- (void)FiltersTableViewDidPop:(FluxFiltersViewController *)filtersTable andChangeFilter:(FluxDataFilter *)dataFilter{

    if (![dataFilter isEqualToFilter:self.currentDataFilter] && dataFilter !=nil) {
        [self setCurrentDataFilter:dataFilter];
    }
    [self updateFilterIcon];
}

#pragma mark Tutorial View

- (void) didPressGetStartedBtn {
    [ScanUIContainerView setAlpha:0.0];
    [ScanUIContainerView setHidden:NO];
    
    [UIView animateWithDuration: 0.3
                     animations:^{
                         tutorialView.alpha = 0;
                         ScanUIContainerView.alpha = 1;
                     }
                     completion:^(BOOL finished){
                         [[NSNotificationCenter defaultCenter] postNotificationName:FluxImageCaptureDidPop
                                                                             object:self userInfo:nil];
                         NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                         [defaults setBool:YES forKey:@"showedTutorial"];
                         
                         [tutorialView removeFromSuperview];
                         tutorialView.delegate = NULL;
                     }];
}


#pragma mark - view lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.screenName = @"Scan View";
    
    self.fluxLoggerService = [FluxLoggerService sharedLoggerService];
    
    self.fluxDisplayManager = [[FluxDisplayManager alloc]init];
    
    [self setupCameraView];
    [self setupOpenGLView];
    [self setupTimeFilterControl];
    [self setupAnnotationsTableView];
    [self setupDebugView];

    self.currentDataFilter = [[FluxDataFilter alloc] init];
    
    [imageCaptureButton removeFromSuperview];
    [imageCaptureButton setTranslatesAutoresizingMaskIntoConstraints:YES];
    [imageCaptureButton setFrame:CGRectMake(imageCaptureButton.frame.origin.x, self.view.frame.size.height-imageCaptureButton.frame.size.height-2, imageCaptureButton.frame.size.width, imageCaptureButton.frame.size.height)];
    [self.view addSubview:imageCaptureButton];
    [imageCaptureButton setHidden:YES];
    
    [self.bottomToolbarView removeFromSuperview];
    [self.bottomToolbarView setTranslatesAutoresizingMaskIntoConstraints:YES];
    [self.bottomToolbarView setFrame:CGRectMake(0, self.view.frame.size.height-83, self.bottomToolbarView.frame.size.width, self.bottomToolbarView.frame.size.height)];
    [ScanUIContainerView addSubview:self.bottomToolbarView];
    
    friendRequestsBadge = [CustomBadge customBadgeWithString:@"0"
                                             withStringColor:[UIColor whiteColor]
                                              withInsetColor:[UIColor colorWithRed:234/255.0 green:63/255.0 blue:63/255.0 alpha:1.0]
                                              withBadgeFrame:NO
                                         withBadgeFrameColor:[UIColor clearColor]
                                                   withScale:1.0
                                                 withShining:NO];
    [friendRequestsBadge setFrame:CGRectMake(self.leftDrawerButton.frame.size.width-20-friendRequestsBadge.frame.size.width/2, self.leftDrawerButton.frame.origin.y+10, friendRequestsBadge.frame.size.width, friendRequestsBadge.frame.size.height)];

    
    if (![self.fluxDisplayManager.locationManager isKalmanSolutionValid])
    {
//        [self.cameraButton setAlpha:0.4];
    }
    
    debugPressCount = 0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateNearbyImageList:) name:FluxDisplayManagerDidUpdateNearbyList object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageCaptureDidPop:) name:FluxImageCaptureDidPop object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userIsTimeSliding) name:FluxOpenGLShouldRender object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(kalmanStateChange) name:FluxLocationServicesSingletonDidChangeKalmanFilterState object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didTakeStepWithPedometer:) name:FluxPedometerDidTakeStep object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupDebugPedometerCountDisplay) name:FluxDebugDidChangePedometerCountDisplay object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupHistoricalPhotoPicker) name:FluxDebugDidChangeHistoricalPhotoPicker object:nil];
    
    [self setupDebugPedometerCountDisplay];
    [self setupHistoricalPhotoPicker];
    
    firstContent = YES;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:@"showedTutorial"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:FluxImageCaptureDidPush
                                                            object:self userInfo:nil];
        
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenRect.size.width;
        CGFloat screenHeight = screenRect.size.height;
        tutorialView = [[FluxTutorialView alloc] initWithFrame: CGRectMake(0, 0, screenWidth, screenHeight)];
        tutorialView.delegate = self;
        
        [self.view addSubview:tutorialView];
        
        [ScanUIContainerView setHidden:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
        [self checkForFollowerRequests];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"pushMapModalView"])
    {
        FluxMapViewController *mapViewController = (FluxMapViewController *)segue.destinationViewController;
        mapViewController.fluxDisplayManager = self.fluxDisplayManager;
        [mapViewController setCurrentDataFilter:self.currentDataFilter];
    }
    else if ([[segue identifier] isEqualToString:@"pushFiltersView"]){
        //set the delegate of the navControllers top view (our filters View)
        FluxFiltersViewController* filtersVC = (FluxFiltersViewController*)[(UINavigationController*)segue.destinationViewController topViewController];
        [filtersVC setDelegate:self];
        [filtersVC setFluxDataManager:self.fluxDisplayManager.fluxDataManager];
        [filtersVC setLocation:self.fluxDisplayManager.locationManager.location];
        [filtersVC prepareViewWithFilter:self.currentDataFilter andInitialCount:self.fluxDisplayManager.nearbyListCount];
        [filtersVC setBackgroundView:snapshotBGImage];
        
        //[self animationPushBackScaleDown];
    }
    else if ([[segue identifier] isEqualToString:@"pushSettingsView"]){
        
        UIImageView*bgView = [[UIImageView alloc]initWithFrame:self.view.frame];
        [bgView setImage:snapshotBGImage];
        [bgView setBackgroundColor:[UIColor darkGrayColor]];
        [[(UINavigationController*)segue.destinationViewController view] insertSubview:bgView atIndex:0];
        
        FluxLeftDrawerViewController* settingsVC = (FluxLeftDrawerViewController*)[(UINavigationController*)segue.destinationViewController topViewController];
        [settingsVC setBadgeCount:friendRequestsBadge.badgeText.intValue];
        [settingsVC setFluxDataManager:self.fluxDisplayManager.fluxDataManager];
        
    }
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxDisplayManagerDidUpdateNearbyList object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxImageCaptureDidPop object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxOpenGLShouldRender object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxLocationServicesSingletonDidChangeKalmanFilterState object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxPedometerDidTakeStep object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxDebugDidChangePedometerCountDisplay object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FluxDebugDidChangeHistoricalPhotoPicker object:nil];
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

#pragma mark - ImagePicker delegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
    
    [self configureNewCameraCaptureWithImage:chosenImage];
}

//Tells the delegate that the user cancelled the pick operation.
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Debug Menu

- (void)setupDebugView{
    UIStoryboard *myStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard"
                                                           bundle:[NSBundle mainBundle]];
    // setup the opengl controller
    // first get an instance from storyboard
    self.debugViewController = [myStoryboard instantiateViewControllerWithIdentifier:@"debugViewController"];
    
    // then add the imageCaptureView as the subview of the parent view
    [self.view addSubview:self.debugViewController.view];
    // add the glkViewController as the child of self
    [self addChildViewController:self.debugViewController];
    [self.debugViewController didMoveToParentViewController:self];
    self.debugViewController.view.frame = self.view.bounds;
    [self.debugViewController.view setHidden:YES];
    
    [debugButton1 setTitle:@"" forState:UIControlStateNormal];
    [debugButton2 setTitle:@"" forState:UIControlStateNormal];
    [debugButton3 setTitle:@"" forState:UIControlStateNormal];
    [debugButton4 setTitle:@"" forState:UIControlStateNormal];
}

- (void)showDebugMenu{
    [self.debugViewController.view setHidden:NO];
    //google analytics
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"ui_action"     // Event category (required)
                                                          action:@"action"  // Event action (required)
                                                           label:@"show debug menu"          // Event label
                                                           value:nil] build]];    // Event value
}
- (void)hideDebugMenu{
    [self.debugViewController.view setHidden:YES];
}

- (IBAction)debugButton1Pressed:(id)sender {
    NSLog(@"Button1 Pressed");
    debugPressCount++;
    [self checkToDisplayDebugMenu];
}

- (IBAction)debugButton1Cancelled:(id)sender {
    NSLog(@"Button1 cancelled");
    debugPressCount--;
}

- (IBAction)debugButton2Pressed:(id)sender {
    NSLog(@"Button2 Pressed");
    debugPressCount++;
    [self checkToDisplayDebugMenu];
}

- (IBAction)debugButton2Cancelled:(id)sender {
    NSLog(@"Button2 cancelled");
    debugPressCount--;
}

- (IBAction)debugButton3Pressed:(id)sender {
    NSLog(@"Button3 Pressed");
    debugPressCount++;
    [self checkToDisplayDebugMenu];
}

- (IBAction)debugButton3Cancelled:(id)sender {
    NSLog(@"Button4 cancelled");
    debugPressCount--;
}

- (IBAction)debugButton4Pressed:(id)sender {
    NSLog(@"Button4 Pressed");
    debugPressCount++;
    [self checkToDisplayDebugMenu];
}

- (IBAction)debugButton4Cancelled:(id)sender {
    NSLog(@"Button3 cancelled");
    debugPressCount--;
}

- (void)checkToDisplayDebugMenu{
    if (debugPressCount == 4) {
        [self showDebugMenu];
    }
}

@end



