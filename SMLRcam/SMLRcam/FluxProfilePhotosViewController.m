//
//  FluxProfilePhotosViewController.m
//  Flux
//
//  Created by Kei Turner on 10/28/2013.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxProfilePhotosViewController.h"
#import "KTCheckboxButton.h"
#import "FluxProfileImageObject.h"
#import "FluxNetworkServices.h"
#import "UICKeyChainStore.h"
#import "FluxPhotoCollectionCell.h"
#import "ProgressHUD.h"

@interface FluxProfilePhotosViewController ()

@end

@implementation FluxProfilePhotosViewController

@synthesize delegate;

#pragma mark - View Init

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
    removedImages = [[NSMutableArray alloc]init];
    
    picturesArray = [[NSMutableArray alloc]init];
    
    [garbageButton setEnabled:NO];
    [editBarButton setEnabled:NO];
    [editBarButton setTintColor:[UIColor colorWithWhite:1.0 alpha:0.6]];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];

    [self.navigationController setToolbarHidden:YES animated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)prepareViewWithImagesUserID:(int)userID{
    theUserID = userID;
    FluxDataRequest*request = [[FluxDataRequest alloc]init];
    [request setUserImagesReady:^(NSArray * imageList, FluxDataRequest*completedDataRequest){
        picturesArray = [imageList mutableCopy];
        if (picturesArray.count > 0) {
            [theCollectionView reloadData];
            [editBarButton setEnabled:YES];
        }
        else{
            UILabel*noImagesLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 300, 100)];
            [noImagesLabel setCenter:self.view.center];
            [noImagesLabel setNumberOfLines:3];
            [noImagesLabel setText:@"No images yet...\n \nGo snap some!"];
            [noImagesLabel setTextAlignment:NSTextAlignmentCenter];
            [noImagesLabel setFont:[UIFont fontWithName:@"Akkurat" size:20.0]];
            [noImagesLabel setTextColor:[UIColor colorWithRed:74/255.0 green:92/255.0 blue:104/255.0 alpha:1.0]];
            [self.view addSubview:noImagesLabel];
        }
        
    }];
    [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
        NSString*str = [NSString stringWithFormat:@"Images failed to load failed with error %d", (int)[e code]];
        [ProgressHUD showError:str];
    }];
    [self.fluxDataManager requestImageListForUserWithID:userID withDataRequest:request];
}

- (void)deleteImages{
    [ProgressHUD show:@"Deleting..."];
    [self.view setUserInteractionEnabled:NO];
    deletedImages = 0;
    
    for (int i = 0; i<removedImages.count; i++) {
        FluxDataRequest*request = [[FluxDataRequest alloc]init];
        [request setDeleteImageCompleteBlock:^(int imageID, FluxDataRequest*completedRequest){
            [self addToDeleteQueue];
        }];
        
        [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
            [self swapEditModes];
            [self prepareViewWithImagesUserID:theUserID];
            NSString*str = [NSString stringWithFormat:@"Failed to delete one or more images"];
            [ProgressHUD showError:str];
            [self unfreezeUI];
        }];
        int index = [(NSNumber*)[removedImages objectAtIndex:i]integerValue];
        int imageID = [(FluxProfileImageObject*)[picturesArray objectAtIndex:index] imageID];
        [self.fluxDataManager deleteImageWithImageID:imageID  withDataRequest:request];
    }
}

- (void)addToDeleteQueue{
    deletedImages++;
    if (deletedImages == removedImages.count) {
        [ProgressHUD showSuccess:@"Deleted"];
        [self unfreezeUI];
        
        if ([delegate respondsToSelector:@selector(FluxProfilePhotosViewController:didPopAndDeleteImages:)]) {
            [delegate FluxProfilePhotosViewController:self didPopAndDeleteImages:deletedImages];
        }
        
        NSMutableArray *indexPaths = [[NSMutableArray alloc]initWithCapacity:removedImages.count];
        NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc]init];
        for (int i = 0; i<removedImages.count; i++) {
            NSIndexPath*indexPath = [NSIndexPath indexPathForRow:[[removedImages objectAtIndex:i]integerValue] inSection:0];
            [indexPaths addObject:indexPath];
            [indexSet addIndex:indexPath.row];
        }
        [picturesArray removeObjectsAtIndexes:indexSet];
        [removedImages removeAllObjects];
        
        [self.collectionView performBatchUpdates:^{
            [self.collectionView deleteItemsAtIndexPaths:indexPaths];
            
        } completion:^(BOOL finished) {
            [self swapEditModes];
        }];
        
    }
}

-(void)unfreezeUI{
    [self.view setUserInteractionEnabled:YES];
}

#pragma mark - CollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return picturesArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"myCell";
    
    FluxPhotoCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    if (isEditing) {
        [cell.checkboxButton setHidden:NO];
        if ([removedImages containsObject:[NSNumber numberWithInt:indexPath.row]]) {
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
    }
    if (![(FluxProfileImageObject*)[picturesArray objectAtIndex:indexPath.row]image]) {
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@images/%i/image?size=%@&auth_token='%@'",FluxProductionServerURL,[[picturesArray objectAtIndex:indexPath.row]imageID],fluxImageTypeStrings[thumb], [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService]]]];
        [cell.imageView setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.1]];
        [cell.imageView setImageWithURLRequest:request placeholderImage:[UIImage imageNamed:@"nothing"]
             success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
//                 CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], CGRectMake(0, (image.size.height) - (image.size.width), image.size.width*0.68, image.size.width*0.68));
//                 // or use the UIImage wherever you like
//                 UIImage*cropppedImg = [UIImage imageWithCGImage:imageRef];
//                 CGImageRelease(imageRef);
//
//                 [(FluxProfileImageObject*)[picturesArray objectAtIndex:indexPath.row]setImage:cropppedImg];
                 [(FluxProfileImageObject*)[picturesArray objectAtIndex:indexPath.row]setImage:image];
                 [collectionView reloadItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
             }
             failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error){
                 NSLog(@"failed image loading: %@", error);
             }];
    }
    cell.imageView.image = [(FluxProfileImageObject*)[picturesArray objectAtIndex:indexPath.row]image];
    [cell.imageView setAlpha:1.0];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (isEditing) {
        if ([removedImages containsObject:[NSNumber numberWithInt:indexPath.row]]) {
            [removedImages removeObject:[NSNumber numberWithInt:indexPath.row]];
            if (removedImages.count == 0) {
                [garbageButton setEnabled:NO];
            }
            [collectionView reloadData];
        }
        else{
            [removedImages addObject:[NSNumber numberWithInt:indexPath.row]];
            [collectionView reloadData];
            [garbageButton setEnabled:YES];
        }

    }
    //else present a photo viewer
    else{
        NSMutableArray*photoURLs = [[NSMutableArray alloc]init];
        NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
        for (int i = 0; i<picturesArray.count; i++) {
            NSString*urlString = [NSString stringWithFormat:@"%@images/%i/image?size=%@&auth_token=%@",FluxProductionServerURL, [[picturesArray objectAtIndex:i]imageID], fluxImageTypeStrings[quarterhd],token];
            [photoURLs addObject:urlString];
        }
        IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotoURLs:photoURLs animatedFromView:[collectionView cellForItemAtIndexPath:indexPath].contentView];
        //[browser setDisplaysProfileInfo:NO];
        [browser setDisplayToolbar:NO];
        [browser setDisplayDoneButtonBackgroundImage:NO];
        [browser setInitialPageIndex:indexPath.row];
        [browser setDelegate:self];
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        [self presentViewController:browser animated:YES completion:nil];
    }
}

- (void)photoBrowser:(IDMPhotoBrowser *)photoBrowser didDismissAtPageIndex:(NSUInteger)index{
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

#pragma mark - IB Actions

- (IBAction)garbageButtonAction:(id)sender {
    UIActionSheet *areYouSureSheet = [[UIActionSheet alloc]initWithTitle:(removedImages.count > 1 ? @"Are you sure you want to delete these images from Flux? This action cannot be undone." : @"Are you sure you'd like to delete this image? This action cannot be undone.") delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles: nil];
    [areYouSureSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [self deleteImages];
    }
}

- (IBAction)editButtonAction:(id)sender {
    [self swapEditModes];
}

- (void)swapEditModes{
    isEditing = !isEditing;
    if (isEditing) {
        [editBarButton setTitle:@"Cancel"];
        [self.navigationController setToolbarHidden:NO animated:YES];
    }
    else{
        [editBarButton setTitle:@"Edit"];
        [self.navigationController setToolbarHidden:YES animated:YES];
    }
    
    [theCollectionView reloadData];
}
@end
