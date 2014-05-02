//
//  FluxEditCaptionViewController.h
//  Flux
//
//  Created by Kei Turner on 2014-04-30.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KTPlaceholderTextView.h"

@class FluxEditCaptionViewController;
@protocol FluxEditCaptionViewDelegate <NSObject>
@optional
- (void)EditCaptionViewDidClear:(FluxEditCaptionViewController *)editCaptionView;
- (void)EditCaptionView:(FluxEditCaptionViewController *)editCaptionView shouldEditCaption:(NSString*)newCaption forImageWithID:(int)imageID;
@end

@interface FluxEditCaptionViewController : UIViewController <KTPlaceholderTextViewDelegate>{
    CGRect finalTextFrame;
    
    NSString*existingString;
    
    UITapGestureRecognizer*tapGesture;

    id __unsafe_unretained delegate;
    
    int imageSize;
}

@property (unsafe_unretained) id <FluxEditCaptionViewDelegate> delegate;
@property (strong, nonatomic) IBOutlet UIImageView *underlyingImageView;
@property (strong, nonatomic) IBOutlet KTPlaceholderTextView *captionTextView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (nonatomic) int imageID;

- (IBAction)doneButtonAction:(id)sender;
- (IBAction)cancelButtonAction:(id)sender;

- (void)animateFromTextFrame:(CGRect)textFrame withCaption:(NSString*)caption andImageFrame:(CGRect)imageFrame andUnderlyingImage:(UIImage*)image;


@end
