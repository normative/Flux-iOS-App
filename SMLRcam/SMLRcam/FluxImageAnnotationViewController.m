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
    [ImageAnnotationTextView becomeFirstResponder];
    
    [usernameLabel setFont:[UIFont fontWithName:@"Akkurat" size:usernameLabel.font.pointSize]];
    [dateLabel setFont:[UIFont fontWithName:@"Akkurat" size:dateLabel.font.pointSize]];
    
    [[UISegmentedControl appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"Akkurat" size:13.0], NSFontAttributeName, nil] forState:UIControlStateNormal];
    
    [[UISegmentedControl appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor colorWithRed:234/255.0 green:63/255.0 blue:63/255.0 alpha:1.0], NSForegroundColorAttributeName, nil] forState:UIControlStateSelected];


    [usernameLabel setText:@"myUsername"];
    [usernameImageView setImage:[UIImage imageNamed:@"profileImage"]];
    
    removedImages = [[NSMutableIndexSet alloc]init];
	// Do any additional setup after loading the view.
}

- (void)prepareViewWithBGImage:(UIImage *)image andCapturedImages:(NSMutableArray *)capturedObjects withLocation:(NSString*)location andDate:(NSDate *)capturedDate{
    FluxImageTools*tools = [[FluxImageTools alloc]init];
    UIImageView*bgView = [[UIImageView alloc]initWithFrame:self.view.bounds];
    [bgView setImage:[tools blurImage:image withBlurLevel:0.6]];
    [self.view insertSubview:bgView belowSubview:containerView];
    //    UIImage *theImg = (UIImage*)[capturedObjects objectAtIndex:0];
//    CGImageRef imageRef = CGImageCreateWithImageInRect([theImg CGImage], CGRectMake(0, (theImg.size.height/2) - (theImg.size.width/2), theImg.size.width, theImg.size.width));
//    // or use the UIImage wherever you like
//    UIImage*cropppedImg = [UIImage imageWithCGImage:imageRef];
//    CGImageRelease(imageRef);
    
    
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
    [checkbox setDelegate:self];
    if ([removedImages containsIndex:indexPath.row]) {
        [checkbox setChecked:NO];
    }
    else
    {
        [checkbox setChecked:YES];
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
    if ([removedImages containsIndex:indexPath.row]) {
        [removedImages removeIndex:indexPath.row];
        [collectionView reloadData];
    }
    else{
        [removedImages addIndex:indexPath.row];
        [collectionView reloadData];
    }
}

- (void)CheckBoxButtonWasTapped:(KTCheckboxButton *)checkButton andChecked:(BOOL)checked{
    NSArray*elements = [imageCollectionView visibleCells];
    for (int i = 0; i<elements.count; i++) {
        UICollectionViewCell*cell = (UICollectionViewCell*)[elements objectAtIndex:i];
        KTCheckboxButton*checkbox = (KTCheckboxButton*)[cell viewWithTag:200];
        if (checkButton == checkbox) {
            [self collectionView:imageCollectionView didSelectItemAtIndexPath:[imageCollectionView indexPathForCell:cell]];
        }
    }
}

- (void)PlaceholderTextViewDidBeginEditing:(KTPlaceholderTextView *)placeholderTextView{
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IB Actions


- (IBAction)socialOptionChanged:(id)sender {
}

- (IBAction)cancelButtonAction:(id)sender {
    if ([delegate respondsToSelector:@selector(ImageAnnotationViewDidPop:)]) {
        [delegate ImageAnnotationViewDidPop:self];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)saveButtonAction:(id)sender {
    if (ImageAnnotationTextView.text.length < 141) {
        if ([delegate respondsToSelector:@selector(ImageAnnotationViewDidPop:andApproveWithChanges:)]) {
            NSDictionary*dict = [NSDictionary dictionaryWithObjectsAndKeys:ImageAnnotationTextView.text, @"annotation",removedImages, @"removedImages", nil];
            [delegate ImageAnnotationViewDidPop:self andApproveWithChanges:dict];
        }
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}
@end
