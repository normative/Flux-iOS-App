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
    
    [self setTitle:@"My Photos"];
    
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
    FluxDataRequest*request = [[FluxDataRequest alloc]init];
    [request setUserImagesReady:^(NSArray * imageList, FluxDataRequest*completedDataRequest){
        picturesArray = [imageList mutableCopy];
        if (picturesArray.count > 0) {
            [theCollectionView reloadData];
            [editBarButton setEnabled:YES];
        }
        
    }];
    [self.fluxDataManager requestImageListForUserWithID:userID withDataRequest:request];
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
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@images/%i/image?size=quarterhd",FluxProductionServerURL,[[picturesArray objectAtIndex:indexPath.row]imageID]]]];
        [theImageView setImageWithURLRequest:request
                  placeholderImage:[UIImage imageNamed:@"nothing"]
                           success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                               [(FluxProfileImageObject*)[picturesArray objectAtIndex:indexPath.row]setImage:image];
                           }
                           failure:NULL];
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
    else{
        NSMutableArray*photoURLs = [[NSMutableArray alloc]init];
        for (int i = 0; i<picturesArray.count; i++) {
            NSString*urlString = [NSString stringWithFormat:@"%@images/%i/image?size=quarterhd",FluxProductionServerURL,[[picturesArray objectAtIndex:i]imageID]];
            [photoURLs addObject:urlString];
        }
        IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotoURLs:photoURLs animatedFromView:[collectionView cellForItemAtIndexPath:indexPath].contentView];
        [browser setDisplaysProfileInfo:NO];
        [browser setInitialPageIndex:indexPath.row];
        [browser setDelegate:self];
        [self presentViewController:browser animated:YES completion:nil];
    }
}

- (void)photoBrowser:(IDMPhotoBrowser *)photoBrowser didDismissAtPageIndex:(NSUInteger)index{
    
}

#pragma mark - IB Actions

- (IBAction)garbageButtonAction:(id)sender {
    NSMutableArray *indexPaths = [[NSMutableArray alloc]initWithCapacity:removedImages.count];
    NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc]init];
    for (int i = 0; i<removedImages.count; i++) {
        int index = [picturesArray indexOfObject:[picturesArray objectAtIndex:[[removedImages objectAtIndex:i]integerValue]]];
        
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
