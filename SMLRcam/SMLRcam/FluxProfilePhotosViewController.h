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

@interface FluxProfilePhotosViewController : UICollectionViewController<IDMPhotoBrowserDelegate>{
    NSMutableArray*picturesArray;
    NSMutableArray*idmPhotos;
    
    IDMPhotoBrowser * photoViewerView;
    IBOutlet UIBarButtonItem *garbageButton;
    
    NSMutableArray*removedImages;
    IBOutlet UICollectionView*theCollectionView;
    IBOutlet UIBarButtonItem *editBarButton;
    BOOL isEditing;
}
@property (nonatomic, strong)FluxDataManager *fluxDataManager;
- (void)prepareViewWithImagesUserID:(int)userID;
- (IBAction)garbageButtonAction:(id)sender;
- (IBAction)editButtonAction:(id)sender;

@end
