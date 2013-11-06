//
//  FluxEditCaptureViewController.h
//  Flux
//
//  Created by Kei Turner on 11/5/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FluxEditCaptureSetViewController;
@protocol EditCaptureSetViewDelegate <NSObject>
@optional
- (void)EditCaptureView:(FluxEditCaptureSetViewController *)editCaptureView didChangeImageSet:(NSMutableArray*)newImageList andRemovedIndexSet:(NSIndexSet*)indexset;
@end


@interface FluxEditCaptureSetViewController : UICollectionViewController{
    
    IBOutlet UIBarButtonItem *garbageBarButton;
    __weak id <EditCaptureSetViewDelegate> delegate;
}

@property (nonatomic, weak) id <EditCaptureSetViewDelegate> delegate;

@property (nonatomic, strong) NSArray* capturedImages;
@property (nonatomic, strong) NSMutableIndexSet* removedImagesIndexSet;

@property (nonatomic, strong) NSMutableArray* imagesArray;
@property (nonatomic, strong) NSMutableArray* removedImagesArray;


- (void)prepareViewWithImagesArray:(NSArray*)images andDeletionArray:(NSArray*)deletedArray;
- (IBAction)garbageButtonAction:(id)sender;

@end
