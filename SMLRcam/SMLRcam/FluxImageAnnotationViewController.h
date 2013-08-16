//
//  SMLRcamImageAnnotationViewController.h
//  SMLRcam
//
//  Created by Kei Turner on 2013-07-29.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "KTPlaceholderTextView.h"
#import "FluxLocationServicesSingleton.h"
#import "FluxScanImageObject.h"

#import "FluxAPIInteraction.h"

@interface FluxImageAnnotationViewController : UIViewController<KTPlaceholderTextViewDelegate, APIInteractionDelegate>{
    
    UIImage * capturedImage;
    NSMutableDictionary *imgMetadata;
    NSMutableData *imgData;
    NSDate *timestamp;
    CLLocation *location;
    FluxScanImageObject*imageObject;
    
    FluxLocationServicesSingleton*locationManager;
    
    __weak IBOutlet UIImageView *backgroundImageView;
    __weak IBOutlet KTPlaceholderTextView *annotationTextView;
    __weak IBOutlet UILabel *locationLabel;
    __weak IBOutlet UILabel *timestampLabel;
    __weak IBOutlet UIProgressView *progressView;
    __weak IBOutlet UIButton *acceptButton;
}

//init
- (void)setCapturedImage:(FluxScanImageObject*)imgObject andImageData:(NSMutableData*)imageData andImageMetadata:(NSMutableDictionary*)imageMetadata andTimestamp:(NSDate*)theTimestamp andLocation:(CLLocation*)theLocation;
- (void)LoadUI;
//image
- (UIImage *)BlurryImage:(UIImage *)image withBlurLevel:(CGFloat)blur;
- (void)AddGradientImageToBackgroundWithAlpha:(CGFloat)alpha;

//UIActions
- (IBAction)PopViewController:(id)sender;
- (IBAction)ConfirmImage:(id)sender;





@end
