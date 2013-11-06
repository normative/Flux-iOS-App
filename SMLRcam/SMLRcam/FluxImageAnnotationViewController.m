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
    [locationLabel setFont:[UIFont fontWithName:@"Akkurat" size:locationLabel.font.pointSize]];
    
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
    [imageStackButton setBackgroundImage:(UIImage*)[capturedObjects objectAtIndex:0] forState:UIControlStateNormal];
    [locationLabel setText:location];
    
    NSDateFormatter *theDateFormat = [[NSDateFormatter alloc] init];
    [theDateFormat setDateFormat:@"MMM dd, yyyy - h:mma"];
    [dateLabel setText:[theDateFormat stringFromDate:capturedDate]];
    
    images = capturedObjects;
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
        [imageStackButton setBackgroundImage:(UIImage*)[images objectAtIndex:0] forState:UIControlStateNormal];
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
