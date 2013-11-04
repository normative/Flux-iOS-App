//
//  FluxImageAnnotationViewController.h
//  Flux
//
//  Created by Kei Turner on 2013-10-03.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "KTPlaceholderTextView.h"
#import "KTSegmentedButtonControl.h"

@class FluxImageAnnotationViewController;
@protocol ImageAnnotationDelegate <NSObject>
@optional
- (void)ImageAnnotationViewDidPop:(FluxImageAnnotationViewController *)imageAnnotationsViewController;
- (void)ImageAnnotationViewDidPop:(FluxImageAnnotationViewController *)imageAnnotationsViewController andApproveWithAnnotation:(NSDictionary*)annotations;
@end


@interface FluxImageAnnotationViewController : UIViewController<KTPlaceholderTextViewDelegate, KTSegmentedControlDelegate>{
    __weak IBOutlet KTPlaceholderTextView *ImageAnnotationTextView;
    __weak IBOutlet KTSegmentedButtonControl *categorySegmentedControl;
    __weak IBOutlet UIView *photoAnnotationContainerView;
    
    __weak id <ImageAnnotationDelegate> delegate;
}

@property (nonatomic, weak) id <ImageAnnotationDelegate> delegate;
- (IBAction)cancelButtonAction:(id)sender;
- (IBAction)saveButtonAction:(id)sender;

- (void)setBGImage:(UIImage*)image;



@end
