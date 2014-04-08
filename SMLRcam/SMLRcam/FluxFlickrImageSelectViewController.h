//
//  FluxFlickrImageSelectViewController.h
//  Flux
//
//  Created by Ryan Martens on 3/24/14.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString* const FluxFlickrImageSelectCroppedImageKey;
extern NSString* const FluxFlickrImageSelectDescriptionKey;

@class FluxFlickrImageSelectViewController;

@protocol FluxFlickrImageSelectProtocol <NSObject>

- (void)FluxFlickrImageSelectViewController:(FluxFlickrImageSelectViewController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
- (void)FluxFlickrImageSelectViewControllerDidCancel:(FluxFlickrImageSelectViewController *)picker;

@end


@interface FluxFlickrImageSelectViewController : UITableViewController

@property (nonatomic, weak) id<FluxFlickrImageSelectProtocol> delegate;

- (IBAction)cancelButtonAction:(id)sender;
- (IBAction)selectButtonAction:(id)sender;

@end
