//
//  FluxProfilePhotosViewController.m
//  Flux
//
//  Created by Kei Turner on 10/28/2013.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxProfilePhotosViewController.h"

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
    
    
    picturesArray = [[NSMutableArray alloc]init];
    for (int i = 0; i<9; i++) {
        IDMPhoto *photo = [[IDMPhoto alloc]initWithImage:[UIImage imageNamed:@"Image"]];
        [picturesArray addObject:photo];
    }
    
    [self setTitle:@"My Photos"];
    
	// Do any additional setup after loading the view.
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
    
    UIImageView *recipeImageView = (UIImageView *)[cell viewWithTag:100];
    recipeImageView.image = [(IDMPhoto*)[picturesArray objectAtIndex:indexPath.row]underlyingImage];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:picturesArray animatedFromView:[collectionView cellForItemAtIndexPath:indexPath].contentView];
    [browser setInitialPageIndex:indexPath.row];
    [browser setDelegate:self];
    [self presentViewController:browser animated:YES completion:nil];
}

- (void)photoBrowser:(IDMPhotoBrowser *)photoBrowser didDismissAtPageIndex:(NSUInteger)index{
    
}

@end
