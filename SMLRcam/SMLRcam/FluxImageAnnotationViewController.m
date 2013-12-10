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
    [ImageAnnotationTextView setTheDelegate:self];
    [ImageAnnotationTextView becomeFirstResponder];

    [twitterButton setImage:[UIImage imageNamed:@"shareTwitter_on"] forState:UIControlStateSelected];
    [facebookButton setImage:[UIImage imageNamed:@"shareFacebook_on"] forState:UIControlStateSelected];
    [privacyButton setImage:[UIImage imageNamed:@"shareEveryone_off"] forState:UIControlStateSelected];
    
    removedImages = [[NSMutableIndexSet alloc]init];
    
    CALayer *roundBorderLayer = [CALayer layer];
    roundBorderLayer.borderWidth = 0.5;
    roundBorderLayer.opacity = 0.4;
    roundBorderLayer.cornerRadius = 5;
    roundBorderLayer.borderColor = [UIColor whiteColor].CGColor;
    roundBorderLayer.frame = CGRectMake(0, 0, CGRectGetWidth(ImageAnnotationTextView.frame), CGRectGetHeight(ImageAnnotationTextView.frame));
    [ImageAnnotationTextView.layer addSublayer:roundBorderLayer];
    
    
	// Do any additional setup after loading the view.
}

- (void)prepareViewWithBGImage:(UIImage *)image andCapturedImages:(NSMutableArray *)capturedObjects withLocation:(NSString*)location andDate:(NSDate *)capturedDate{
    FluxImageTools*tools = [[FluxImageTools alloc]init];
    UIImageView*bgView = [[UIImageView alloc]initWithFrame:self.view.bounds];
    [bgView setImage:[tools blurImage:image withBlurLevel:0.6]];
    [self.view insertSubview:bgView belowSubview:containerView];
    
    [ImageAnnotationTextView setPlaceholderText:[NSString stringWithFormat:@"What did you see here?"]];

    
    images = capturedObjects;
}

- (void)prepareSnapShotViewWithImage:(UIImage*)image withLocation:(NSString*)location andDate:(NSDate*)capturedDate{
    FluxImageTools*tools = [[FluxImageTools alloc]init];
    UIImageView*bgView = [[UIImageView alloc]initWithFrame:self.view.bounds];
    [bgView setImage:[tools blurImage:image withBlurLevel:0.6]];
    [self.view insertSubview:bgView belowSubview:containerView];
    
    isSnapshot = YES;
    
    [ImageAnnotationTextView setPlaceholderText:[NSString stringWithFormat:@"What did you find?"]];
    [saveButton setEnabled:NO];
    [saveButton setTintColor:[UIColor lightGrayColor]];
    
    images = [NSArray arrayWithObject:image];
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
    if (isSnapshot) {
        UIImageView *imageView = (UIImageView *)[cell viewWithTag:100];
        imageView.image = [images objectAtIndex:0];
        return cell;
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

//if it's a 4s or before, tap hides the keyboard
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    if ([[UIScreen mainScreen] bounds].size.height < 568.0f)
    {
        [ImageAnnotationTextView resignFirstResponder];
    }
}

#pragma mark - IB Actions

- (IBAction)cancelButtonAction:(id)sender {
    if ([delegate respondsToSelector:@selector(ImageAnnotationViewDidPop:)]) {
        [delegate ImageAnnotationViewDidPop:self];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)saveButtonAction:(id)sender {
    if (ImageAnnotationTextView.text.length < 141) {
        if (isSnapshot) {
            //do something with the snapshot
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            BOOL savelocally = [[defaults objectForKey:@"Save Pictures"]boolValue];
            if (savelocally)
            {
                UIImageWriteToSavedPhotosAlbum([images objectAtIndex:0], nil, nil, nil);
            }
            [self cancelButtonAction:nil];
        }
        else{
            if ([delegate respondsToSelector:@selector(ImageAnnotationViewDidPop:andApproveWithChanges:)]) {
                NSDictionary*dict = [NSDictionary dictionaryWithObjectsAndKeys:ImageAnnotationTextView.text, @"annotation",removedImages, @"removedImages", nil];
                [delegate ImageAnnotationViewDidPop:self andApproveWithChanges:dict];
            }
        }
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}
- (IBAction)privacyButtonAction:(id)sender {
    if (!isSnapshot) {
        [privacyButton setSelected:!privacyButton.selected];
    }
}

- (IBAction)facebookButtonAction:(id)sender {
    [facebookButton setSelected:!facebookButton.selected];
    if (isSnapshot) {
        [self checkPostButton];
    }
}

- (IBAction)twitterButtonAction:(id)sender {
    [twitterButton setSelected:!twitterButton.selected];
    if (isSnapshot) {
        [self checkPostButton];
    }
}

- (void)checkPostButton{
    if (facebookButton.isSelected || twitterButton.isSelected) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
        [saveButton setTintColor:[UIColor whiteColor]];
    }
    else{
        self.navigationItem.rightBarButtonItem.enabled = NO;
        [saveButton setTintColor:[UIColor lightGrayColor]];
    }
}

@end
