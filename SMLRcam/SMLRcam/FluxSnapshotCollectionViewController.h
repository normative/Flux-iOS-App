//
//  FluxSnapshotCollectionViewController.h
//  Flux
//
//  Created by Kei Turner on 1/21/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "IDMPhotoBrowser.h"

@interface FluxSnapshotCollectionViewController : UICollectionViewController <IDMPhotoBrowserDelegate>{
    NSArray*imageURLArray;
    NSMutableArray*imagesIndexArray;
    
    BOOL isSelecting;
    IBOutlet UIBarButtonItem *shareButton;
}

@property (nonatomic, retain) UIImage * BGImage;
- (IBAction)cancelButtonAction:(id)sender;
- (IBAction)selectButtonAction:(id)sender;
- (IBAction)shareButtonAction:(id)sender;

@end
