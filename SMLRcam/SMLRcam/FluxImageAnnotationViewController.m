
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


#import "UICKeyChainStore.h"
#import "UIActionSheet+Blocks.h"
#import "ProgressHUD.h"
#define IS_4INCHSCREEN  ([[UIScreen mainScreen] bounds].size.height == 568)?TRUE:FALSE


#define IS_4INCHSCREEN  ([[UIScreen mainScreen] bounds].size.height == 568)?TRUE:FALSE

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
    NSLog(@"DidLoad: %@", NSStringFromCGRect(ImageAnnotationTextView.frame));
    [super viewDidLoad];
    [ImageAnnotationTextView setTheDelegate:self];
    if (IS_4INCHSCREEN) {
        [ImageAnnotationTextView becomeFirstResponder];
        CALayer *roundBorderLayer = [CALayer layer];
        roundBorderLayer.borderWidth = 0.5;
        roundBorderLayer.opacity = 0.4;
        roundBorderLayer.cornerRadius = 5;
        roundBorderLayer.borderColor = [UIColor whiteColor].CGColor;
        roundBorderLayer.frame = CGRectMake(0, 0, CGRectGetWidth(ImageAnnotationTextView.frame), CGRectGetHeight(ImageAnnotationTextView.frame));
        [ImageAnnotationTextView.layer addSublayer:roundBorderLayer];

    }
    else{
        CALayer *roundBorderLayer = [CALayer layer];
        roundBorderLayer.borderWidth = 0.5;
        roundBorderLayer.opacity = 0.4;
        roundBorderLayer.cornerRadius = 5;
        roundBorderLayer.borderColor = [UIColor whiteColor].CGColor;
        roundBorderLayer.frame = CGRectMake(0, 0, 300, 63);
        [ImageAnnotationTextView.layer addSublayer:roundBorderLayer];

    }

    
    [twitterButton setImage:[UIImage imageNamed:@"shareTwitter_on"] forState:UIControlStateSelected];
    [facebookButton setImage:[UIImage imageNamed:@"shareFacebook_on"] forState:UIControlStateSelected];

    
    
    [privacyButton setImage:[UIImage imageNamed:@"shareEveryone_off"] forState:UIControlStateSelected];
    
    removedImages = [[NSMutableIndexSet alloc]init];
    
//    [privacyButton setHidden:YES];
//    [facebookButton setHidden:YES];
//    [twitterButton setHidden:YES];
    
    
	// Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.screenName = @"Image Capture Annotation View";
}


- (void)prepareViewWithBGImage:(UIImage *)image andCapturedImages:(NSMutableArray *)capturedObjects withLocation:(NSString*)location andDate:(NSDate *)capturedDate{
    FluxImageTools*tools = [[FluxImageTools alloc]init];
    UIImageView*bgView = [[UIImageView alloc]initWithFrame:self.view.bounds];
    [bgView setImage:[tools blurImage:image withBlurLevel:0.6]];
    [self.view insertSubview:bgView belowSubview:containerView];
    
    [ImageAnnotationTextView setPlaceholderText:[NSString stringWithFormat:@"What did you capture?"]];
    [self.navigationItem.rightBarButtonItem setTitle:@"Save"];
    [facebookButton setHidden:YES];
    [twitterButton setHidden:YES];
    
    images = capturedObjects;
}

- (void)prepareSnapShotViewWithImage:(UIImage*)image withLocation:(NSString*)location andDate:(NSDate*)capturedDate{
    FluxImageTools*tools = [[FluxImageTools alloc]init];
    UIImageView*bgView = [[UIImageView alloc]initWithFrame:self.view.bounds];
    [bgView setImage:[tools blurImage:image withBlurLevel:0.6]];
    [self.view insertSubview:bgView belowSubview:containerView];
    
    isSnapshot = YES;
    [privacyButton setHidden:YES];
    
    
    [self.navigationItem.rightBarButtonItem setTitle:@"Save"];
    
    
    [ImageAnnotationTextView setPlaceholderText:[NSString stringWithFormat:@"What's in flux?"]];
    
    //[saveButton setEnabled:NO];
    //[saveButton setTintColor:[UIColor lightGrayColor]];
    
    images = [NSArray arrayWithObject:image];
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:nil];
    gestureRecognizer.cancelsTouchesInView = NO;
    gestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:gestureRecognizer];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    if ([touch.view isKindOfClass:[UIButton class]] || [touch.view isKindOfClass:[KTPlaceholderTextView class]]){
        return NO;
    }
    CGPoint touchLocation = [touch locationInView:self.view];
    if (CGRectContainsPoint(imageCollectionView.frame, touchLocation)) {
        if (isSnapshot) {
            [ImageAnnotationTextView resignFirstResponder];
        }
        NSLog(@"Touched in collectionView");
    }
    else {
        [ImageAnnotationTextView resignFirstResponder];
    }
    return YES;
}

#pragma mark - CollectionView Delegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return images.count;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    if (isSnapshot) {
        return UIEdgeInsetsMake(0, 105, 0, 0);
    }
    return UIEdgeInsetsMake(0, 10, 0,10);
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
        [imageView setContentMode:UIViewContentModeScaleAspectFit];
        imageView.image = [images objectAtIndex:0];
        [(KTCheckboxButton*)[cell viewWithTag:200] setHidden:YES];
        [cell setUserInteractionEnabled:NO];
        
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
        [self checkSaveButton];
    }
    else{
        [removedImages addIndex:indexPath.row];
        [collectionView reloadData];
        [self checkSaveButton];
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

- (void)checkSaveButton{
    if (removedImages.count == images.count) {
        [saveButton setEnabled:NO];
        saveButton.tintColor = [UIColor colorWithWhite:1.0 alpha:0.8];
    }
    else{
        [saveButton setEnabled:YES];
        saveButton.tintColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    }
}

- (void)PlaceholderTextViewDidBeginEditing:(KTPlaceholderTextView *)placeholderTextView{
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//if it's a non-4" display
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
            UIImageWriteToSavedPhotosAlbum([images objectAtIndex:0], nil, nil, nil);
        }
        
        
        if ([delegate respondsToSelector:@selector(ImageAnnotationViewDidPop:andApproveWithChanges:)]) {
            NSMutableArray*socialPostArr = [[NSMutableArray alloc]init];
            if (facebookButton.isSelected && !facebookButton.isHidden) {
                [socialPostArr addObject:FacebookService];
            }
            if (twitterButton.isSelected && !twitterButton.isHidden) {
                [socialPostArr addObject:TwitterService];
            }
            NSDictionary*dict = [NSDictionary dictionaryWithObjectsAndKeys:ImageAnnotationTextView.text, @"annotation",
                                 removedImages, @"removedImages",
                                 [NSNumber numberWithBool:privacyButton.isSelected], @"privacy",
                                 socialPostArr, @"social",
                                 [NSNumber numberWithBool:isSnapshot], @"snapshot",
                                 [images firstObject] , @"snapshotImage",
                                 nil];
            [delegate ImageAnnotationViewDidPop:self andApproveWithChanges:dict];
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
    if (facebookButton.selected) {
        [self toggleSwitchSocialButton:facebookButton state:!facebookButton.selected];
    }
    else{
        NSString*facebook = [UICKeyChainStore stringForKey:FluxUsernameKey service:FacebookService];
        
        if (facebook) {
            FluxSocialManager*socialManager = [[FluxSocialManager alloc]init];
            [socialManager setDelegate:self];
            [socialManager linkFacebookWithPublishPermissions];
        }
        else{
            [UIActionSheet showInView:self.view
                            withTitle:@"Facebook"
                    cancelButtonTitle:@"Cancel"
               destructiveButtonTitle:nil
                    otherButtonTitles:@[@"Link"]
                             tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                                 if (buttonIndex != actionSheet.cancelButtonIndex) {
                                     //link facebook
                                     FluxSocialManager*socialManager = [[FluxSocialManager alloc]init];
                                     [socialManager setDelegate:self];
                                     [socialManager linkFacebookWithPublishPermissions];
                                 }
                             }];
        }
    }
}

- (IBAction)twitterButtonAction:(id)sender {
    NSString*twitter = [UICKeyChainStore stringForKey:FluxUsernameKey service:TwitterService];
    
    if (twitter) {
        [self toggleSwitchSocialButton:twitterButton state:!twitterButton.selected];
    }
    else{
        [UIActionSheet showInView:self.view
                        withTitle:@"Twitter"
                cancelButtonTitle:@"Cancel"
           destructiveButtonTitle:nil
                otherButtonTitles:@[@"Link"]
                         tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                             if (buttonIndex != actionSheet.cancelButtonIndex) {
                                 //link twitter
                                 FluxSocialManager*socialManager = [[FluxSocialManager alloc]init];
                                 [socialManager setDelegate:self];
                                 [socialManager linkTwitter];
                             }
                         }];
    }

}

- (void)toggleSwitchSocialButton:(UIButton*)button state:(BOOL)state{
    [button setSelected:state];
    
    if (isSnapshot) {
        [self checkPostButton];
    }
}

- (void)SocialManagerDidAddFacebookPublishPermissions:(FluxSocialManager *)socialManager{
    [self toggleSwitchSocialButton:facebookButton state:!facebookButton.selected];
}

- (void)SocialManagerDidFailToAddAddFacebookPublishPermissions:(FluxSocialManager *)socialManager andDidShowError:(BOOL)errorShownAlready{
    [ProgressHUD showError:@"Failed to link Facebook account"];
}

//- (void)SocialManager:(FluxSocialManager *)socialManager didLinkFacebookAccountWithName:(NSString *)name{
//    [self toggleSwitchSocialButton:facebookButton state:!facebookButton.selected];
//
//}

- (void)SocialManager:(FluxSocialManager *)socialManager didLinkTwitterAccountWithUsername:(NSString *)username{
    [self toggleSwitchSocialButton:twitterButton state:!twitterButton.selected];
}

- (void)SocialManager:(FluxSocialManager *)socialManager didFailToLinkSocialAccount:(NSString *)accountType withMessage:(NSString *)message{
    if (message) {
        [ProgressHUD showError:message];
    }
    else{
        [ProgressHUD showError:[NSString stringWithFormat:@"Failed to link %@",accountType]];
    }
}

- (void)checkPostButton{
    if (facebookButton.isSelected || twitterButton.isSelected) {
        [self.navigationItem.rightBarButtonItem setTitle:@"Post"];
    }
    else{
        [self.navigationItem.rightBarButtonItem setTitle:@"Save"];
    }
}

@end
