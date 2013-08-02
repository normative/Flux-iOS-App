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

@interface FluxImageAnnotationViewController : UIViewController<KTPlaceholderTextViewDelegate>{
    
    UIImage * capturedImage;
    NSMutableDictionary *imgMetadata;
    NSMutableData *imgData;
    NSDate *timestamp;
    CLLocation *location;
    
    CLGeocoder *theGeocoder;
    
    __weak IBOutlet UIImageView *backgroundImageView;
    __weak IBOutlet KTPlaceholderTextView *annotationTextView;
    __weak IBOutlet UILabel *locationLabel;
    __weak IBOutlet UILabel *timestampLabel;
}

//init
- (void)setCapturedImage:(UIImage *)theCapturedImage andImageData:(NSMutableData*)imageData andImageMetadata:(NSMutableDictionary*)imageMetadata andTimestamp:(NSDate*)timestamp andLocation:(CLLocation*)theLocation;
- (void)LoadUI;
//location
- (void)reverseGeocodeLocation:(CLLocation*)thelocation;
//image
- (UIImage *)BlurryImage:(UIImage *)image withBlurLevel:(CGFloat)blur;
- (void)AddGradientImageToBackgroundWithAlpha:(CGFloat)alpha;

//UIActions
- (IBAction)PopViewController:(id)sender;
- (IBAction)ConfirmImage:(id)sender;





@end
