//
//  FluxSnapshotCaptureViewController.m
//  Flux
//
//  Created by Kei Turner on 1/21/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxSnapshotCaptureViewController.h"
#import "UIAlertView+Blocks.h"
#import "AssetsLibrary/AssetsLibrary.h"
#import "FluxImageCaptureViewController.h"


@interface FluxSnapshotCaptureViewController ()

@end

@implementation FluxSnapshotCaptureViewController


#pragma mark - Liew Lifecycle

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
    
    self.snapshotRollButton.layer.cornerRadius = 1.5;
    self.snapshotRollButton.layer.masksToBounds = YES;
    
    
    blackView = [[UIView alloc]initWithFrame:self.view.bounds];
    [blackView setBackgroundColor:[UIColor blackColor]];
    [blackView setAlpha:0.0];
    [blackView setHidden:YES];
    [self.view addSubview:blackView];
    
    newSnapshotView = [[UIImageView alloc]initWithFrame:self.view.bounds];
    [newSnapshotView setBackgroundColor:[UIColor blackColor]];
    [newSnapshotView setAlpha:0.0];
    [newSnapshotView setHidden:YES];
    [self.view insertSubview:newSnapshotView atIndex:0];
    
    if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) {
        NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
        NSArray*picsArr = [NSArray arrayWithArray:[defaults objectForKey:@"snapshotImages"]];
        if (picsArr.count) {
            [self setSnapshotButtonImage:[picsArr lastObject]];
        }
        else
        {
            [self.snapshotRollButton setHidden:YES];
        }
    }
    else{
        [self.snapshotRollButton setHidden:YES];
    }
    [shareButton.titleLabel setFont:[UIFont fontWithName:@"Akkurat" size:shareButton.titleLabel.font.pointSize]];

	// Do any additional setup after loading the view.
}

- (void)viewDidExit{
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [newSnapshotView setHidden:YES];
    [newSnapshotView setAlpha:0.0];
    
    [shareButton setHidden:YES];
    [self.snapshotRollButton setHidden:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([[segue identifier] isEqualToString:@"annotationSegue"]) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        UINavigationController*tmp = segue.destinationViewController;
        FluxImageAnnotationViewController* annotationsVC = (FluxImageAnnotationViewController*)tmp.topViewController;
        [annotationsVC prepareSnapShotViewWithImage:newSnapshot withLocation:nil andDate:[NSDate date]];
        [annotationsVC setDelegate:self];
    }

}


- (void)setSnapshotButtonImage:(NSString*)localURL{
    //
    ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset)
    {
        ALAssetRepresentation *rep = [myasset defaultRepresentation];
        CGImageRef iref = [rep fullResolutionImage];
        if (iref) {
            UIImage *image = [UIImage imageWithCGImage:iref];
            [self.snapshotRollButton addImage:image];
        }
    };
    
    //
    ALAssetsLibraryAccessFailureBlock failureblock  = ^(NSError *myerror)
    {
        NSLog(@"oops, cant get image - %@",[myerror localizedDescription]);
    };
    
    NSURL *asseturl = [NSURL URLWithString:localURL];
    ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
    [assetslibrary assetForURL:asseturl
                   resultBlock:resultblock
                  failureBlock:failureblock];
}

#pragma mark - Other
- (void)addsnapshot:(NSNotification*)notification{
    [self showFlash:[UIColor blackColor]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"didCaptureBackgroundSnapshot" object:nil];
    newSnapshot = (UIImage*)[[notification userInfo]objectForKey:@"snapshot"];
    [self addImageToSnapshotRoll:newSnapshot];
}


- (void)showNewSnapshot:(UIImage*)image{
    [newSnapshotView setImage:image];
    [newSnapshotView setHidden:NO];
    [UIView animateWithDuration:0.1 animations:^{
        [newSnapshotView setAlpha:1.0];
    } completion:^(BOOL finished) {
    }];
}


- (void)addImageToSnapshotRoll:(UIImage*)image{
    if (![ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusAuthorized) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"May We?"
                                                            message:@"In order to save your snapshots to your device, we need access to your photos"
                                                           delegate:nil
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Sure", nil];
        
        [alertView showWithCompletion:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex != alertView.cancelButtonIndex) {
                [self saveImageLocally:image];
            }
        }];
    }
    else{
        [self saveImageLocally:image];
    }
}

- (void)saveImageLocally: (UIImage*)image{
    [self.snapshotRollButton setHidden:NO];
    [self.snapshotRollButton addImage:image];
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    // Request to save the image to camera roll
    [library writeImageToSavedPhotosAlbum:[image CGImage] orientation:(ALAssetOrientation)[image imageOrientation] completionBlock:^(NSURL *assetURL, NSError *error){
        if (error) {
            NSLog(@"error saving snapshot");
        } else {
            NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
            NSMutableArray * picturesArray = [NSMutableArray arrayWithArray:[defaults objectForKey:@"snapshotImages"]];
            if (picturesArray) {
                [picturesArray addObject:[assetURL absoluteString]];
                [defaults setObject:picturesArray forKey:@"snapshotImages"];
            }
            else{
                NSMutableArray*pics = [NSMutableArray arrayWithObject:assetURL];
                [defaults setObject:pics forKey:@"snapshotImages"];
            }
            [defaults synchronize];
            
            
            NSLog(@"saved Image url %@", assetURL);
        }
    }];
}

//this method has been modified to eliminate the ability to share from the view. sharing can only be done via cameraRoll button or through the photos.app
- (void)showFlash:(UIColor*)color {
    [shareButton setHidden:NO];
    
    [blackView setHidden:NO];
    [blackView setBackgroundColor:color];

    [UIView animateWithDuration:0.15 animations:^{
        [blackView setAlpha:0.9];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.15 animations:^{
            [blackView setAlpha:0.0];
            [shareButton setAlpha:1.0];
            [self.snapshotRollButton setHidden:YES];
            } completion:^(BOOL finished) {
                [blackView setHidden:YES];
                [self showNewSnapshot:newSnapshot];
            }];
    }];
}

- (void)ImageAnnotationViewDidPop:(FluxImageAnnotationViewController *)imageAnnotationsViewController{
    [self closeButtonAction:nil];
}

- (void)ImageAnnotationViewDidPop:(FluxImageAnnotationViewController *)imageAnnotationsViewController andApproveWithChanges:(NSDictionary*)changes{
    
    
    NSArray*socialSelections = (NSArray*)[changes objectForKey:@"social"];
    
    if (socialSelections) {
        NSNumber*snapshot = (NSNumber*)[changes objectForKey:@"snapshot"];
        NSString*annotation = (NSString*)[changes objectForKey:@"annotation"];
        NSArray*capturedImages = [NSArray arrayWithObject:newSnapshot];
        
        
        NSDictionary *userInfoDict = [[NSDictionary alloc]
                                      initWithObjectsAndKeys:capturedImages, @"capturedImageObjects",
                                      capturedImages, @"capturedImages",
                                      socialSelections, @"social",
                                      snapshot, @"snapshot",
                                      annotation, @"annotation",
                                      nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:FluxImageCaptureDidPop
                                                            object:self userInfo:userInfoDict];
    }

    [self closeButtonAction:nil];
}


#pragma mark - IBActions
- (IBAction)closeButtonAction:(id)sender {
    [self.view setHidden:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FluxImageCaptureDidPop"
                                                        object:self userInfo:nil];
    [self viewDidExit];
}

- (IBAction)snapshotRollButtonAction:(id)sender {
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (IBAction)shareButtonAction:(id)sender {
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:[NSArray arrayWithObject:newSnapshot] applicationActivities:nil];
    activityVC.excludedActivityTypes = @[UIActivityTypeSaveToCameraRoll]; //or whichever you don't need
    [self presentViewController:activityVC animated:YES completion:nil];
    
    return;
    
    // Create an object
    if (!FBSession.activeSession.isOpen) {
        [FBSession openActiveSessionWithAllowLoginUI: NO];
    }
    
//    NSMutableDictionary<FBOpenGraphObject> *restaurant = [FBGraphObject openGraphObjectForPost];
//    
//    // specify that this Open Graph object will be posted to Facebook
//    restaurant.provisionedForPost = YES;
//    
//    // Add the standard object properties
//    restaurant[@"og"] = @{ @"title":@"Restaurant Name", @"type":@"fluxapp:picture.picture", @"description":@"a description"};
//    
//    // Add the properties restaurant inherits from place
//    //restaurant[@"place"] = @{ @"location" : @{ @"longitude": @"-58.381667", @"latitude":@"-34.603333"} };
//    
//    // Add the properties particular to the type restaurant.restaurant
////    restaurant[@"restaurant"] = @{@"category": @[@"Mexican"],
////                                  @"contact_info": @{@"street_address": @"123 Some st",
////                                                     @"locality": @"Menlo Park",
////                                                     @"region": @"CA",
////                                                     @"phone_number": @"555-555-555",
////                                                     @"website": @"http://www.example.com"}};
//    
//    // Make the Graph API request to post the object
//    FBRequest *request = [FBRequest requestForPostWithGraphPath:@"me/objects/fluxapp:picture.picture"
//                                                    graphObject:@{@"object":restaurant}];
//    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
//        if (!error) {
//            // Sucess! Include your code to handle the results here
//            NSLog(@"result: %@", result);
//            NSString* _objectID = [result objectForKey:@"id"];
//            NSString*alertTitle = @"Object successfully created";
//            NSString*alertText = [NSString stringWithFormat:@"An object with id %@ has been created", _objectID];
//            [[[UIAlertView alloc] initWithTitle:alertTitle
//                                        message:alertText
//                                       delegate:self
//                              cancelButtonTitle:@"OK!"
//                              otherButtonTitles:nil] show];
//        } else {
//            // An error occurred, we need to handle the error
//            
//            // See: https://developers.facebook.com/docs/ios/errors
//            NSLog(@"Error: %@, %@",error.description, error.debugDescription);
//        }
//    }];
    
    
//    NSMutableDictionary<FBGraphObject> *object =
//    [FBGraphObject openGraphObjectForPostWithType:@"fluxapp:picture"
//                                            title:@"Sample Picture"
//                                            image:@"https://fbstatic-a.akamaihd.net/images/devsite/attachment_blank.png"
//                                              url:@"http://samples.ogp.me/597664603651091"
//                                      description:@""];;
//    
//    [FBRequestConnection startForPostWithGraphPath:@"me/objects/fluxapp:picture"
//                                       graphObject:object
//                                 completionHandler:^(FBRequestConnection *connection,
//                                                     id result,
//                                                     NSError *error) {
//                                     if (!error) {
//                                        // Sucess! Include your code to handle the results here
//                                        NSLog(@"result: %@", result);
//                                        NSString* _objectID = [result objectForKey:@"id"];
//                                        NSString*alertTitle = @"Object successfully created";
//                                        NSString*alertText = [NSString stringWithFormat:@"An object with id %@ has been created", _objectID];
//                                        [[[UIAlertView alloc] initWithTitle:alertTitle
//                                                                    message:alertText
//                                                                   delegate:self
//                                                          cancelButtonTitle:@"OK!"
//                                                          otherButtonTitles:nil] show];
//                                    } else {
//                                        // An error occurred, we need to handle the error
//                                        
//                                        // See: https://developers.facebook.com/docs/ios/errors
//                                        NSLog(@"Error: %@, %@",error.description, error.debugDescription);
//                                    }
//                                 }];
//    [FBRequestConnection startForUploadStagingResourceWithImage:newSnapshot completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
//        if(!error) {
//            NSLog(@"Successfuly staged image with staged URI: %@", [result objectForKey:@"uri"]);
//            
//            // Package image inside a dictionary, inside an array like we'll need it for the object
//            NSArray *image = @[@{@"url": [result objectForKey:@"uri"], @"user_generated" : @"true" }];
//            
//            // Create an object
//            NSMutableDictionary<FBOpenGraphObject> *picture = [FBGraphObject openGraphObjectForPost];
//            
//            // specify that this Open Graph object will be posted to Facebook
//            picture.provisionedForPost = YES;
//            
//            // Add the standard object properties, including the image you just staged
//            picture[@"og"] = @{ @"title":@"Flux", @"type":@"picture.picture", @"description":@"", @"image":image };
//            
////            NSMutableDictionary<FBGraphObject> *object =
////            [FBGraphObject openGraphObjectForPostWithType:@"fluxapp:picture"
////                                                    title:@"My pic"
////                                                    image:image
////                                                      url:@"http://samples.ogp.me/597664603651091"
////                                              description:@""];
//            
//            picture[@"create_object"] = @"1";
//            picture[@"fbsdk:create_object"] = @"1";
//            
//            [FBRequestConnection startForPostWithGraphPath:@"me/objects/"
//                                               graphObject:picture
//                                         completionHandler:^(FBRequestConnection *connection,
//                                                             id result,
//                                                             NSError *error) {
//                                             if (!error) {
//                                                 // Sucess! Include your code to handle the results here
//                                                 NSLog(@"result: %@", result);
//                                                 NSString* _objectID = [result objectForKey:@"id"];
//                                                 NSString*alertTitle = @"Object successfully created";
//                                                 NSString*alertText = [NSString stringWithFormat:@"An object with id %@ has been created", _objectID];
//                                                 [[[UIAlertView alloc] initWithTitle:alertTitle
//                                                                             message:alertText
//                                                                            delegate:self
//                                                                   cancelButtonTitle:@"OK!"
//                                                                   otherButtonTitles:nil] show];
//                                             } else {
//                                                 // An error occurred, we need to handle the error
//                                                 
//                                                 // See: https://developers.facebook.com/docs/ios/errors
//                                                 NSLog(@"Error: %@, %@",error.description, error.debugDescription);
//                                             }
//                                             
//                                         }];
//            
//        } else {
//            // An error occurred, we need to handle the error
//            // See: https://developers.facebook.com/docs/ios/errors
//             NSLog(@"Error: %@, %@",error.description, error.debugDescription);
//        }
//    }];
    
    
    NSMutableDictionary<FBGraphObject> *action = [FBGraphObject graphObject];
    action[@"picture"] = @"http://samples.ogp.me/597664603651091";
    
//    NSMutableDictionary<FBGraphObject> *object =
//    [FBGraphObject openGraphObjectForPostWithType:@"fluxapp:picture"
//                                            title:@"Sample Picture"
//                                            image:@"https://fbstatic-a.akamaihd.net/images/devsite/attachment_blank.png"
//                                              url:@"http://samples.ogp.me/597664603651091"
//                                      description:@""];
    
    [FBRequestConnection startForPostWithGraphPath:@"me/fluxapp:take"
                                       graphObject:action
                                 completionHandler:^(FBRequestConnection *connection,
                                                     id result,
                                                     NSError *error) {
                                     if (!error) {
                                        // Sucess! Include your code to handle the results here
                                        NSLog(@"result: %@", result);
                                        NSString* _objectID = [result objectForKey:@"id"];
                                        NSString*alertTitle = @"Object successfully created";
                                        NSString*alertText = [NSString stringWithFormat:@"An object with id %@ has been created", _objectID];
                                        [[[UIAlertView alloc] initWithTitle:alertTitle
                                                                    message:alertText
                                                                   delegate:self
                                                          cancelButtonTitle:@"OK!"
                                                          otherButtonTitles:nil] show];
                                    } else {
                                        // An error occurred, we need to handle the error
                                        
                                        // See: https://developers.facebook.com/docs/ios/errors
                                        NSLog(@"Error: %@, %@",error.description, error.debugDescription);
                                    }

                                 }];
}
@end
