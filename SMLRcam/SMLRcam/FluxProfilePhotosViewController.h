//
//  FluxProfilePhotosViewController.h
//  Flux
//
//  Created by Kei Turner on 10/28/2013.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IDMPhotoBrowser.h"

@interface FluxProfilePhotosViewController : UICollectionViewController<IDMPhotoBrowserDelegate>{
    NSMutableArray*picturesArray;
    
    IDMPhotoBrowser * photoViewerView;
    IBOutlet UIBarButtonItem *garbageButton;
    
    NSMutableArray*removedImages;
    IBOutlet UICollectionView*theCollectionView;
    IBOutlet UIBarButtonItem *editBarButton;
    BOOL isEditing;
}
- (IBAction)garbageButtonAction:(id)sender;
- (IBAction)editButtonAction:(id)sender;

@end
