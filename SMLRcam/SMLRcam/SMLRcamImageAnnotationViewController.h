//
//  SMLRcamImageAnnotationViewController.h
//  SMLRcam
//
//  Created by Kei Turner on 2013-07-29.
//  Copyright (c) 2013 Denis Delorme. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SMLRcamImageAnnotationViewController : UIViewController{
    UIImage * capturedImage;
    __weak IBOutlet UIImageView *backgroundImageView;
}

- (void)setCapturedImage:(UIImage*)theCapturedImage;
- (IBAction)PopViewController:(id)sender;
- (IBAction)ConfirmImage:(id)sender;


@end
