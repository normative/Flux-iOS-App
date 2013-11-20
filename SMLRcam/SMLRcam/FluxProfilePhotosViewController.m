//
//  FluxProfilePhotosViewController.m
//  Flux
//
//  Created by Kei Turner on 10/28/2013.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxProfilePhotosViewController.h"
#import "KTCheckboxButton.h"

@interface FluxProfilePhotosViewController ()

@end

@implementation FluxProfilePhotosViewController

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
    for (int i = 0; i<9; i++) {
        IDMPhoto *photo = [[IDMPhoto alloc]initWithImage:[UIImage imageNamed:@"Image"]];
        [picturesArray addObject:photo];
    }
    
    [self setTitle:@"My Photos"];
    
    [garbageButton setEnabled:NO];
    
	// Do any additional setup after loading the view.
}

- (void)viewWillDisappear:(BOOL)animated{
    [self.navigationController setToolbarHidden:YES animated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return picturesArray.count;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"cell";
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    if (isEditing) {
        [[cell viewWithTag:200]setHidden:NO];
        KTCheckboxButton*checkbox = (KTCheckboxButton*)[cell viewWithTag:200];
        if ([removedImages containsObject:[NSNumber numberWithInt:indexPath.row]]) {
            [checkbox setChecked:YES];
        }
        else{
            [checkbox setChecked:NO];
        }
    }
    else{
        [[cell viewWithTag:200]setHidden:YES];
    }
    UIImageView *recipeImageView = (UIImageView *)[cell viewWithTag:100];
    recipeImageView.image = [(IDMPhoto*)[picturesArray objectAtIndex:indexPath.row]underlyingImage];
    
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
        IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:picturesArray animatedFromView:[collectionView cellForItemAtIndexPath:indexPath].contentView];
        [browser setInitialPageIndex:indexPath.row];
        [browser setDelegate:self];
        [self presentViewController:browser animated:YES completion:nil];
    }
}

- (void)photoBrowser:(IDMPhotoBrowser *)photoBrowser didDismissAtPageIndex:(NSUInteger)index{
    
}

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
