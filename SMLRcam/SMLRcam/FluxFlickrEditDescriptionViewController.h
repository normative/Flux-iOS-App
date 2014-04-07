//
//  FluxFlickrEditDescriptionViewController.h
//  Flux
//
//  Created by Ryan Martens on 4/7/14.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KTPlaceholderTextView.h"

extern NSString* const FluxFlickrEditDescriptionAnnotationKey;

@class FluxFlickrEditDescriptionViewController;

@protocol FluxFlickrEditDescriptionProtocol <NSObject>

- (void)FluxFlickrEditDescriptionViewController:(FluxFlickrEditDescriptionViewController *)picker didFinishEditingDescriptionWithInfo:(NSDictionary *)info;
- (void)FluxFlickrEditDescriptionViewControllerDidCancel:(FluxFlickrEditDescriptionViewController *)picker;

@end

@interface FluxFlickrEditDescriptionViewController : UIViewController <KTPlaceholderTextViewDelegate>

@property (nonatomic, strong) NSString *annotationText;
@property (nonatomic, weak) id<FluxFlickrEditDescriptionProtocol> delegate;

@property (strong, nonatomic) IBOutlet KTPlaceholderTextView *editAnnotationTextView;
@property (strong, nonatomic) IBOutlet UILabel *wordCount;

- (IBAction)cancelButtonAction:(id)sender;
- (IBAction)selectButtonAction:(id)sender;

@end
