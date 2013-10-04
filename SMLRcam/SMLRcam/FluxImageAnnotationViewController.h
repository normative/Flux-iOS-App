//
//  FluxImageAnnotationViewController.h
//  Flux
//
//  Created by Kei Turner on 2013-10-03.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "KTPlaceholderTextView.h"
#import "KTSegmentedButtonControl.h"

@interface FluxImageAnnotationViewController : UIViewController<KTPlaceholderTextViewDelegate, KTSegmentedControlDelegate>{
    __weak IBOutlet KTPlaceholderTextView *ImageAnnotationTextView;
    __weak IBOutlet KTSegmentedButtonControl *categorySegmentedControl;
    __weak IBOutlet UIView *photoAnnotationContainerView;
}



@end
