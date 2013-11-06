//
//  FluxEditCaptureViewController.m
//  Flux
//
//  Created by Kei Turner on 11/5/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxEditCaptureSetViewController.h"
#import "KTCheckboxButton.h"

@interface FluxEditCaptureSetViewController ()

@end

@implementation FluxEditCaptureSetViewController

@synthesize delegate;

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
    [garbageBarButton setEnabled:NO];
    [self.navigationController setToolbarHidden:NO animated:YES];
    self.removedImagesIndexSet = [[NSMutableIndexSet alloc]init];
	// Do any additional setup after loading the view.
}

- (void)viewWillDisappear:(BOOL)animated{
    [self.navigationController setToolbarHidden:YES animated:YES];
    if ([delegate respondsToSelector:@selector(EditCaptureView:didChangeImageSet:andRemovedIndexSet:)]) {
        [delegate EditCaptureView:self didChangeImageSet:self.imagesArray andRemovedIndexSet:self.removedImagesIndexSet];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareViewWithImagesArray:(NSArray *)images andDeletionArray:(NSArray *)deletedArray{
    self.imagesArray = [images mutableCopy];
    self.removedImagesArray = [deletedArray mutableCopy];
    self.capturedImages = images;
}

- (IBAction)garbageButtonAction:(id)sender {
    NSMutableArray *indexPaths = [[NSMutableArray alloc]initWithCapacity:self.removedImagesArray.count];
    NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc]init];
    for (int i = 0; i<self.removedImagesArray.count; i++) {
        int index = [self.capturedImages indexOfObject:[self.imagesArray objectAtIndex:[[self.removedImagesArray objectAtIndex:i]integerValue]]];
        [self.removedImagesIndexSet addIndex:index];
        
        NSIndexPath*indexPath = [NSIndexPath indexPathForRow:[[self.removedImagesArray objectAtIndex:i]integerValue] inSection:0];
        [indexPaths addObject:indexPath];
        [indexSet addIndex:indexPath.row];
    }
    [self.imagesArray removeObjectsAtIndexes:indexSet];
    [self.removedImagesArray removeAllObjects];
    
    [self.collectionView performBatchUpdates:^{
        [self.collectionView deleteItemsAtIndexPaths:indexPaths];
        
    } completion:^(BOOL finished) {
    }];
    
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.imagesArray.count;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"cell";
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    UIImageView *recipeImageView = (UIImageView *)[cell viewWithTag:100];
    recipeImageView.image = [self.imagesArray objectAtIndex:indexPath.row];
    KTCheckboxButton*checkbox = (KTCheckboxButton*)[cell viewWithTag:200];
    if ([self.removedImagesArray containsObject:[NSNumber numberWithInt:indexPath.row]]) {
        [checkbox setChecked:YES];
    }
    else{
        [checkbox setChecked:NO];
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if ([self.removedImagesArray containsObject:[NSNumber numberWithInt:indexPath.row]]) {
        [self.removedImagesArray removeObject:[NSNumber numberWithInt:indexPath.row]];
        if (self.removedImagesArray.count == 0) {
            [garbageBarButton setEnabled:NO];
        }
        [collectionView reloadData];
    }
    else{
        [self.removedImagesArray addObject:[NSNumber numberWithInt:indexPath.row]];
        [collectionView reloadData];
        [garbageBarButton setEnabled:YES];
    }
}

@end
