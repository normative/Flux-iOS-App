//
//  FluxImageAnnotationViewController.h
//  Flux
//
//  Created by Kei Turner on 2013-10-03.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "KTPlaceholderTextView.h"
#import "FluxCheckboxCell.h"

#import "FluxLocationServicesSingleton.h"

@class FluxImageAnnotationViewController;
@protocol ImageAnnotationDelegate <NSObject>
@optional
- (void)ImageAnnotationViewDidPop:(FluxImageAnnotationViewController *)imageAnnotationsViewController;
- (void)ImageAnnotationViewDidPop:(FluxImageAnnotationViewController *)imageAnnotationsViewController andApproveWithChanges:(NSDictionary*)changes;
@end


@interface FluxImageAnnotationViewController : UIViewController<KTPlaceholderTextViewDelegate,KTCheckboxButtonDelegate, UICollectionViewDataSource, UICollectionViewDelegate>{
    __weak IBOutlet KTPlaceholderTextView *ImageAnnotationTextView;
    __weak IBOutlet UIView *photoAnnotationContainerView;
    
    __weak id <ImageAnnotationDelegate> delegate;
    IBOutlet UIView *containerView;
    IBOutlet UICollectionView *imageCollectionView;
    IBOutlet UIImageView *usernameImageView;
    IBOutlet UILabel *usernameLabel;
    IBOutlet UILabel *dateLabel;
    

    IBOutlet UISegmentedControl *socialOptionSegmentedControl;
    IBOutlet UIBarButtonItem *saveButton;
    IBOutlet UIButton *facebookButton;
    IBOutlet UIButton *twitterButton;
    NSArray*images;
    NSMutableIndexSet*removedImages;
}


@property (nonatomic, weak) id <ImageAnnotationDelegate> delegate;
- (IBAction)socialOptionChanged:(id)sender;
- (IBAction)cancelButtonAction:(id)sender;
- (IBAction)saveButtonAction:(id)sender;
- (IBAction)facebookButtonAction:(id)sender;
- (IBAction)twitterButtonAction:(id)sender;

- (void)prepareViewWithBGImage:(UIImage*)image andCapturedImages:(NSMutableArray*)capturedObjects withLocation:(NSString*)location andDate:(NSDate*)capturedDate;



@end
