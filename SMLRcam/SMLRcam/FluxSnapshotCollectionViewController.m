//
//  FluxSnapshotCollectionViewController.m
//  Flux
//
//  Created by Kei Turner on 1/21/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxSnapshotCollectionViewController.h"

#import "KTCheckboxButton.h"
#import "FluxProfileImageObject.h"
#import "FluxPhotoCollectionCell.h"

#import "AssetsLibrary/AssetsLibrary.h"

@interface FluxSnapshotCollectionViewController ()

@end

@implementation FluxSnapshotCollectionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];

    
    //For retrieving
    picturesArray = [NSArray arrayWithArray:[defaults objectForKey:@"snapshotImages"]];
    if (picturesArray) {
        [self.collectionView reloadData];
    }
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setBGImage:(UIImage *)BGImage{
    _BGImage = BGImage;
    
    UIImageView*bgView = [[UIImageView alloc]initWithFrame:self.view.bounds];
    [bgView setImage:self.BGImage];
    [bgView setBackgroundColor:[UIColor darkGrayColor]];
    [self.view insertSubview:bgView atIndex:0];
}

#pragma mark - CollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return picturesArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"myCell";
    
    FluxPhotoCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    [cell.checkboxButton setHidden:NO];

    
    NSString *mediaurl = [picturesArray objectAtIndex:indexPath.row];
    
    //
    ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset)
    {
        ALAssetRepresentation *rep = [myasset defaultRepresentation];
        CGImageRef iref = [rep fullResolutionImage];
        if (iref) {
            UIImage *image = [UIImage imageWithCGImage:iref];
            [cell.imageView setImage:image];
        }
    };
    
    //
    ALAssetsLibraryAccessFailureBlock failureblock  = ^(NSError *myerror)
    {
        NSLog(@"booya, cant get image - %@",[myerror localizedDescription]);
    };
    
        NSURL *asseturl = [NSURL URLWithString:mediaurl];
        ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
        [assetslibrary assetForURL:asseturl
                       resultBlock:resultblock
                      failureBlock:failureblock];
    
    
    
    [cell.imageView setAlpha:1.0];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [collectionView reloadItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
    //else present a photo viewer
//    else{
//        NSMutableArray*photoURLs = [[NSMutableArray alloc]init];
//        for (int i = 0; i<picturesArray.count; i++) {
//            NSString*urlString = [NSString stringWithFormat:@"%@images/%i/image?size=%@",FluxProductionServerURL, [[picturesArray objectAtIndex:i]imageID], fluxImageTypeStrings[quarterhd]];
//            [photoURLs addObject:urlString];
//        }
//        IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotoURLs:photoURLs animatedFromView:[collectionView cellForItemAtIndexPath:indexPath].contentView];
//        //[browser setDisplaysProfileInfo:NO];
//        [browser setDisplayToolbar:NO];
//        [browser setDisplayDoneButtonBackgroundImage:NO];
//        [browser setInitialPageIndex:indexPath.row];
//        [browser setDelegate:self];
//        [self presentViewController:browser animated:YES completion:nil];
//    }
}

- (void)photoBrowser:(IDMPhotoBrowser *)photoBrowser didDismissAtPageIndex:(NSUInteger)index{
    
}

@end
