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

#import "ProgressHUD.h"

@interface FluxProfilePhotosViewController ()

@end

@implementation FluxProfilePhotosViewController

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
    
	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated{

}

- (void)viewWillDisappear:(BOOL)animated{
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
    static NSString *identifier = @"cell";
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    UIImageView *theImageView = (UIImageView *)[cell viewWithTag:100];
    KTCheckboxButton*checkbox = (KTCheckboxButton*)[cell viewWithTag:200];
    if (isEditing) {
        [[cell viewWithTag:200]setHidden:NO];
        if ([removedImages containsObject:[NSNumber numberWithInt:indexPath.row]]) {
            [checkbox setChecked:YES];
            [theImageView setAlpha:0.8];
        }
        else{
            [checkbox setChecked:NO];
            [theImageView setAlpha:1.0];
        }
    }
    else{
        [[cell viewWithTag:200]setHidden:YES];
    }
    if (![(FluxProfileImageObject*)[picturesArray objectAtIndex:indexPath.row]image]) {
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@images/%i/image?size=quarterhd&auth_token='%@'",FluxProductionServerURL,[[picturesArray objectAtIndex:indexPath.row]imageID],[UICKeyChainStore stringForKey:FluxTokenKey service:FluxService]]]];
        [theImageView setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.1]];
        [theImageView setImageWithURLRequest:request placeholderImage:[UIImage imageNamed:@"nothing"]
             success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                 CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], CGRectMake(0, (image.size.height) - (image.size.width), image.size.width*2, image.size.width*2));
                 // or use the UIImage wherever you like
                 UIImage*cropppedImg = [UIImage imageWithCGImage:imageRef];
                 CGImageRelease(imageRef);
                 [(FluxProfileImageObject*)[picturesArray objectAtIndex:indexPath.row]setImage:cropppedImg];
                 [collectionView reloadItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
             }
             failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error){
                 NSLog(@"failed image loading: %@", error);
             }];
    }
    theImageView.image = [(FluxProfileImageObject*)[picturesArray objectAtIndex:indexPath.row]image];
    [theImageView setAlpha:1.0];
    
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
        for (int i = 0; i<picturesArray.count; i++) {
            NSString*urlString = [NSString stringWithFormat:@"%@images/%i/image?size=quarterhd",FluxProductionServerURL,[[picturesArray objectAtIndex:i]imageID]];
            [photoURLs addObject:urlString];
        }
        IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotoURLs:photoURLs animatedFromView:[collectionView cellForItemAtIndexPath:indexPath].contentView];
        //[browser setDisplaysProfileInfo:NO];
        [browser setDisplayToolbar:NO];
        [browser setDisplayDoneButtonBackgroundImage:NO];
        [browser setInitialPageIndex:indexPath.row];
        [browser setDelegate:self];
        [self presentViewController:browser animated:YES completion:nil];
    }
}

- (void)photoBrowser:(IDMPhotoBrowser *)photoBrowser didDismissAtPageIndex:(NSUInteger)index{
    
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
