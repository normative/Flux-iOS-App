//
//  FluxProfilePhotosViewController.h
//  Flux
//
//  Created by Kei Turner on 10/28/2013.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IDMPhotoBrowser.h"
#import "FluxDataManager.h"

@class FluxProfilePhotosViewController;
@protocol PhotosViewDelegate <NSObject>
@optional
- (void)FluxProfilePhotosViewController:(FluxProfilePhotosViewController *)photosViewController didPopAndDeleteImages:(int)count;
@end

@interface FluxProfilePhotosViewController : UICollectionViewController<IDMPhotoBrowserDelegate, UIActionSheetDelegate>{
    NSMutableArray*picturesArray;
    NSMutableArray*idmPhotos;
    int deletedImages;
    int theUserID;
    
    IDMPhotoBrowser * photoViewerView;
    IBOutlet UIBarButtonItem *garbageButton;
    
    NSMutableArray*removedImages;
    IBOutlet UICollectionView*theCollectionView;
    IBOutlet UIBarButtonItem *editBarButton;
    BOOL isEditing;
    __weak id <PhotosViewDelegate> delegate;
}
    @property (nonatomic, weak) id <PhotosViewDelegate> delegate;
@property (nonatomic, strong)FluxDataManager *fluxDataManager;
- (void)prepareViewWithImagesUserID:(int)userID;
- (IBAction)garbageButtonAction:(id)sender;
- (IBAction)editButtonAction:(id)sender;

@end
