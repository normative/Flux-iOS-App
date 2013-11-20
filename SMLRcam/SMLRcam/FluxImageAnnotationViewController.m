//
//  FluxImageAnnotationViewController.m
//  Flux
//
//  Created by Kei Turner on 2013-10-03.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxImageAnnotationViewController.h"
#import "FluxScanImageObject.h"
#import "FluxImageTools.h"

@interface FluxImageAnnotationViewController ()

@end

@implementation FluxImageAnnotationViewController

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
    [ImageAnnotationTextView setPlaceholderText:[NSString stringWithFormat:@"What do you see?"]];
    [ImageAnnotationTextView setTheDelegate:self];
    
    [usernameLabel setFont:[UIFont fontWithName:@"Akkurat" size:usernameLabel.font.pointSize]];
    [dateLabel setFont:[UIFont fontWithName:@"Akkurat" size:dateLabel.font.pointSize]];
    
    [socialDescriptionLabel setFont:[UIFont fontWithName:@"Akkurat" size:socialDescriptionLabel.font.pointSize]];
    [socialOptionLabel setFont:[UIFont fontWithName:@"Akkurat" size:socialOptionLabel.font.pointSize]];
    [shareOnLabel setFont:[UIFont fontWithName:@"Akkurat" size:shareOnLabel.font.pointSize]];
    [twitterLabel setFont:[UIFont fontWithName:@"Akkurat" size:twitterLabel.font.pointSize]];
    [facebookLabel setFont:[UIFont fontWithName:@"Akkurat" size:facebookLabel.font.pointSize]];
    
    [socialOptionCheckbox setDelegate:self];
    [twitterCheckbox setDelegate:self];
    [facebookCheckbox setDelegate:self];

    [usernameLabel setText:@"myUsername"];
    [usernameImageView setImage:[UIImage imageNamed:@""]];
    
    imagesToBeDeleted = [[NSMutableArray alloc]init];
	// Do any additional setup after loading the view.
}

- (void)prepareViewWithBGImage:(UIImage *)image andCapturedImages:(NSMutableArray *)capturedObjects withLocation:(NSString*)location andDate:(NSDate *)capturedDate{
    FluxImageTools*tools = [[FluxImageTools alloc]init];
    UIImageView*bgView = [[UIImageView alloc]initWithFrame:self.view.bounds];
    [bgView setImage:[tools blurImage:image withBlurLevel:0.6]];
    [self.view insertSubview:bgView belowSubview:containerView];
    
    [imageCountLabel setText:[NSString stringWithFormat:@"%i",capturedObjects.count]];
    UIImage *theImg = (UIImage*)[capturedObjects objectAtIndex:0];
    CGImageRef imageRef = CGImageCreateWithImageInRect([theImg CGImage], CGRectMake(0, (theImg.size.height/2) - (theImg.size.width/2), theImg.size.width, theImg.size.width));
    // or use the UIImage wherever you like
    UIImage*cropppedImg = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    
    NSDateFormatter *theDateFormat = [[NSDateFormatter alloc] init];
    [theDateFormat setDateFormat:@"MMM dd, yyyy - h:mma"];
    [dateLabel setText:[theDateFormat stringFromDate:capturedDate]];
    
    images = capturedObjects;
}

#pragma mark - CollectionView Delegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return images.count;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"cell";
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];

    KTCheckboxButton*checkbox = (KTCheckboxButton*)[cell viewWithTag:200];
    if ([imagesToBeDeleted containsObject:[NSNumber numberWithInt:indexPath.row]]) {
        [checkbox setChecked:YES];
    }
    else{
        [checkbox setChecked:NO];
    }
    UIImage *theImg = (UIImage*)[images objectAtIndex:indexPath.row];
    CGImageRef imageRef = CGImageCreateWithImageInRect([theImg CGImage], CGRectMake(0, (theImg.size.height/2) - (theImg.size.width/2), theImg.size.width, theImg.size.width));
    // or use the UIImage wherever you like
    UIImage*cropppedImg = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:100];
    imageView.image = cropppedImg;
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if ([imagesToBeDeleted containsObject:[NSNumber numberWithInt:indexPath.row]]) {
        [imagesToBeDeleted removeObject:[NSNumber numberWithInt:indexPath.row]];
        [collectionView reloadData];
    }
    else{
        [imagesToBeDeleted addObject:[NSNumber numberWithInt:indexPath.row]];
        [collectionView reloadData];
    }
}

- (void)CheckBoxButtonWasTapped:(KTCheckboxButton *)checkButton andChecked:(BOOL)checked{
    if (checkButton == socialOptionCheckbox) {
        [socialOptionCheckbox setChecked:checked];
        NSLog(@"Set social option");
    }
    else if (checkButton == twitterCheckbox){
        [twitterCheckbox setChecked:checked];
        NSLog(@"Set twitter option");
    }
    else
    {
        [facebookCheckbox setChecked:checked];
        NSLog(@"Set facebook option");
    }
}

- (void)PlaceholderTextViewDidBeginEditing:(KTPlaceholderTextView *)placeholderTextView{
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [ImageAnnotationTextView resignFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Segue Methods

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    FluxEditCaptureSetViewController *editVC = (FluxEditCaptureSetViewController*)segue.destinationViewController;
    [editVC prepareViewWithImagesArray:images andDeletionArray:imagesToBeDeleted];
    [editVC setDelegate:self];
}

- (void)EditCaptureView:(FluxEditCaptureSetViewController *)editCaptureView didChangeImageSet:(NSMutableArray *)newImageList andRemovedIndexSet:(NSIndexSet *)indexset{
    if (images.count != newImageList.count) {
        images = newImageList;
        removedImages = indexset;
        
        [imageCountLabel setText:[NSString stringWithFormat:@"%i",images.count]];
    }
}


- (IBAction)cancelButtonAction:(id)sender {
    if ([delegate respondsToSelector:@selector(ImageAnnotationViewDidPop:)]) {
        [delegate ImageAnnotationViewDidPop:self];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)saveButtonAction:(id)sender {
    if ([delegate respondsToSelector:@selector(ImageAnnotationViewDidPop:andApproveWithChanges:)]) {
        NSDictionary*dict = [NSDictionary dictionaryWithObjectsAndKeys:ImageAnnotationTextView.text, @"annotation",removedImages, @"removedImages", nil];        
        [delegate ImageAnnotationViewDidPop:self andApproveWithChanges:dict];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
