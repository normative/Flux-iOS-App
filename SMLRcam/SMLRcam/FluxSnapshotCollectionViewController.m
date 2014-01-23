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
    
    imagesIndexArray = [[NSMutableArray alloc]init];


    isSelecting = NO;
    
    //For retrieving
    imageURLArray = [NSArray arrayWithArray:[defaults objectForKey:@"snapshotImages"]];
    if (imageURLArray) {
        [self.collectionView reloadData];
    }
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    [[self navigationController] setToolbarHidden:YES animated:NO];
    [shareButton setEnabled:NO];
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
    [self.collectionView insertSubview:bgView atIndex:0];
}

#pragma mark - CollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return imageURLArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"myCell";
    
    FluxPhotoCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    if (isSelecting) {
        [cell.checkboxButton setHidden:NO];
        if ([imagesIndexArray containsObject:[NSNumber numberWithInt:indexPath.row]]) {
            [cell.checkboxButton setChecked:YES];
            [cell.imageView setAlpha:0.8];
        }
        else{
            [cell.checkboxButton setChecked:NO];
            [cell.imageView setAlpha:1.0];
        }
    }
    else{
        [cell.checkboxButton setHidden:YES];
        [cell.imageView setAlpha:1.0];
    }

    NSString *mediaurl = [imageURLArray objectAtIndex:indexPath.row];
    
    //
    ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset)
    {
        ALAssetRepresentation *rep = [myasset defaultRepresentation];
        CGImageRef iref = [rep fullResolutionImage];
        if (iref) {
            UIImage *image = [UIImage imageWithCGImage:iref];
            [cell setTheImage:image];
        }
    };
    
    //
    ALAssetsLibraryAccessFailureBlock failureblock  = ^(NSError *myerror)
    {
        NSLog(@"oops, cant get image - %@",[myerror localizedDescription]);
    };
    
    NSURL *asseturl = [NSURL URLWithString:mediaurl];
    ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
    [assetslibrary assetForURL:asseturl
                   resultBlock:resultblock
                  failureBlock:failureblock];
        
    

    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (isSelecting) {
        if ([imagesIndexArray containsObject:[NSNumber numberWithInt:indexPath.row]]) {
            [imagesIndexArray removeObject:[NSNumber numberWithInt:indexPath.row]];
            if (imagesIndexArray.count == 0) {
                [shareButton setEnabled:NO];
            }
            [collectionView reloadItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
        }
        else{
            [imagesIndexArray addObject:[NSNumber numberWithInt:indexPath.row]];
            [collectionView reloadItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
            [shareButton setEnabled:YES];
        }
    }
    else{
        NSMutableArray*photos = [[NSMutableArray alloc]init];
        for (int i = 0; i<imagesIndexArray.count; i++) {
            FluxPhotoCollectionCell*cell = (FluxPhotoCollectionCell*)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            IDMPhoto*photo = [[IDMPhoto alloc]initWithImage:cell.theImage];
            [photos addObject:photo];
        }
        IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:photos animatedFromView:[collectionView cellForItemAtIndexPath:indexPath].contentView];
        [browser setDisplayToolbar:NO];
        [browser setDisplayDoneButtonBackgroundImage:NO];
        [browser setInitialPageIndex:indexPath.row];
        [browser setDelegate:self];
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        [self presentViewController:browser animated:YES completion:nil];
    }
    
    //else present a photo viewer
//    else{

}

- (void)photoBrowser:(IDMPhotoBrowser *)photoBrowser didDismissAtPageIndex:(NSUInteger)index{
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
}

- (IBAction)cancelButtonAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)selectButtonAction:(id)sender {
    if (isSelecting) {
        isSelecting = NO;
        [[self navigationController] setToolbarHidden:YES animated:YES];
        [self.navigationItem.rightBarButtonItem setTitle:@"Select"];
        [self hideBackButton:NO];
    }
    else{
        isSelecting = YES;
        [[self navigationController] setToolbarHidden:NO animated:YES];
        [self.navigationItem.rightBarButtonItem setTitle:@"Cancel"];
        [self hideBackButton:YES];
    }
    [self.collectionView reloadData];
}

- (IBAction)shareButtonAction:(id)sender {
    NSMutableArray*imagesArray = [[NSMutableArray alloc]init];
    for (NSNumber*num in imagesIndexArray){
        FluxPhotoCollectionCell*cell = (FluxPhotoCollectionCell*)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:[num intValue] inSection:0]];
        [imagesArray addObject:cell.theImage];
    }
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:imagesArray applicationActivities:nil];
    activityVC.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll]; //or whichever you don't need
    [self presentViewController:activityVC animated:YES completion:nil];
}

- (void)hideBackButton:(BOOL)hide {
    
    if (hide) {
        self.navigationItem.leftBarButtonItem = nil;
    }
    else {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                                 initWithTitle:@"Back"
                                                 style:UIBarButtonItemStylePlain
                                                 target:self action:@selector(cancelButtonAction:)];
        
    }
}

@end
