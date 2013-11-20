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
#import "FluxEditCaptureSetViewController.h"

#import "FluxLocationServicesSingleton.h"

@class FluxImageAnnotationViewController;
@protocol ImageAnnotationDelegate <NSObject>
@optional
- (void)ImageAnnotationViewDidPop:(FluxImageAnnotationViewController *)imageAnnotationsViewController;
- (void)ImageAnnotationViewDidPop:(FluxImageAnnotationViewController *)imageAnnotationsViewController andApproveWithChanges:(NSDictionary*)changes;
@end


@interface FluxImageAnnotationViewController : UIViewController<KTPlaceholderTextViewDelegate,KTCheckboxButtonDelegate, EditCaptureSetViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate>{
    __weak IBOutlet KTPlaceholderTextView *ImageAnnotationTextView;
    __weak IBOutlet UIView *photoAnnotationContainerView;
    
    __weak id <ImageAnnotationDelegate> delegate;
    IBOutlet UIView *containerView;
    IBOutlet UICollectionView *imageCollectionView;
    IBOutlet UILabel *imageCountLabel;
    IBOutlet UIImageView *usernameImageView;
    IBOutlet UILabel *usernameLabel;
    IBOutlet UILabel *dateLabel;
    
    IBOutlet UILabel *socialDescriptionLabel;
    IBOutlet UILabel *socialOptionLabel;
    IBOutlet KTCheckboxButton *socialOptionCheckbox;
    IBOutlet UILabel *shareOnLabel;
    IBOutlet UILabel *twitterLabel;
    IBOutlet UILabel *facebookLabel;
    IBOutlet KTCheckboxButton *twitterCheckbox;
    IBOutlet KTCheckboxButton *facebookCheckbox;
    NSArray*images;
    NSIndexSet*removedImages;
    NSMutableArray*imagesToBeDeleted;
}


@property (nonatomic, weak) id <ImageAnnotationDelegate> delegate;
- (IBAction)cancelButtonAction:(id)sender;
- (IBAction)saveButtonAction:(id)sender;

- (void)prepareViewWithBGImage:(UIImage*)image andCapturedImages:(NSMutableArray*)capturedObjects withLocation:(NSString*)location andDate:(NSDate*)capturedDate;



@end
