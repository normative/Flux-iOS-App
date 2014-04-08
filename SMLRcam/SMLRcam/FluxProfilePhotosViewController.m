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
#import "UIActionSheet+Blocks.h"

#define enabledColor [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0]
#define disabledColor [UIColor colorWithWhite:0.5 alpha:0.5]

@interface FluxProfilePhotosViewController ()

@end

@implementation FluxProfilePhotosViewController

@synthesize delegate;



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
    editedPrivacyImages = [[NSMutableArray alloc]init];
    
    
    [editPrivacyButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: disabledColor, NSForegroundColorAttributeName,NSFontAttributeName, [UIFont fontWithName:@"Akkurat" size:17.0], nil] forState:UIControlStateNormal];
    
    
    [garbageButton setEnabled:NO];
    [editPrivacyButton setEnabled:NO];
    [editBarButton setEnabled:NO];
    [editBarButton setTintColor:[UIColor colorWithWhite:1.0 alpha:0.6]];
    
    isRetrieving = NO;
    newPrivacyIsPrivate = YES;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];

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
        isRetrieving = NO;
        
        if ([[ProgressHUD currentStatus]  isEqualToString: HUD_PROGRESS_STATUS]) {
            [ProgressHUD dismiss];
        }

        picturesArray = [imageList mutableCopy];
        if (picturesArray.count > 0) {
            [theCollectionView reloadData];
            [editBarButton setEnabled:YES];
        }
        else{
            UIView*emptyImagesView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 300, 300)];
            UILabel*noImagesLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 265, 100)];
            [noImagesLabel setCenter:CGPointMake(emptyImagesView.center.y, 230)];
            [emptyImagesView setCenter:self.view.center];
            [noImagesLabel setFont:[UIFont fontWithName:@"Akkurat" size:15.0]];
            [noImagesLabel setTextColor:[UIColor colorWithWhite:1.0 alpha:0.6]];
            
            NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
            paragraphStyle.lineSpacing = 6;
            paragraphStyle.alignment = NSTextAlignmentCenter;
            
            NSDictionary *attribs = @{
                                      NSForegroundColorAttributeName: noImagesLabel.textColor,
                                      NSFontAttributeName: noImagesLabel.font,
                                      NSParagraphStyleAttributeName : paragraphStyle
                                      };
            NSMutableAttributedString *attributedText =
            [[NSMutableAttributedString alloc] initWithString:@"You haven't taken any pictures yet, but it doesn't have to be this way."
                                                   attributes:attribs];
            
            [noImagesLabel setAttributedText:attributedText];
            
            
            [noImagesLabel setNumberOfLines:3];
            [emptyImagesView addSubview:noImagesLabel];
            
            UIImageView*imgView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 200, 200)];
            [imgView setCenter:CGPointMake(emptyImagesView.center.x, imgView.frame.size.width/2)];
            [imgView setImage:[UIImage imageNamed:@"empytPics"]];
            [imgView setContentMode:UIViewContentModeScaleAspectFit];
            [emptyImagesView addSubview:imgView];
            
            [self.view addSubview:emptyImagesView];
        }
        
    }];
    [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
        NSString*str = [NSString stringWithFormat:@"Images failed to load"];
        [ProgressHUD showError:str];
    }];
    [self.fluxDataManager requestImageListForUserWithID:userID withDataRequest:request];
    isRetrieving = YES;
    [self performSelector:@selector(showProgressHUD) withObject:nil afterDelay:1.0];
}

- (void)showProgressHUD{
    if (isRetrieving) {
        [ProgressHUD show:@"Retrieving images..."];
    }
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
        int index = [(NSNumber*)[removedImages objectAtIndex:i]intValue];
        int imageID = [(FluxProfileImageObject*)[picturesArray objectAtIndex:index] imageID];
        [self.fluxDataManager deleteImageWithImageID:imageID  withDataRequest:request];
    }
}

- (void)editImagePrivacy{
    [ProgressHUD show:@"Changing Privacy..."];
    
    NSMutableArray*imageIDs = [[NSMutableArray alloc]init];
    for (int i = 0; i<removedImages.count; i++) {
        int index= [(NSNumber*)[removedImages objectAtIndex:i]intValue];
        [imageIDs addObject:[NSString stringWithFormat:@"%i",[(FluxProfileImageObject*)[picturesArray objectAtIndex:index]imageID]]];
    }
    
    FluxDataRequest*request = [[FluxDataRequest alloc]init];
    [request setUpdateImagesPrivacyCompleteBlock:^(FluxDataRequest*completedRequest){
        [ProgressHUD showSuccess:@"Privacy Changed"];
        for (int i = 0; i<removedImages.count; i++) {
            int index= [(NSNumber*)[removedImages objectAtIndex:i]intValue];
            [(FluxProfileImageObject*)[picturesArray objectAtIndex:index] setPrivacy:newPrivacyIsPrivate];
        }
        [removedImages removeAllObjects];
        [theCollectionView reloadData];
        [self unfreezeUI];
        [self swapEditModes];
        
    }];
    
    [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
        [self swapEditModes];
        [self prepareViewWithImagesUserID:theUserID];
        NSString*str = [NSString stringWithFormat:@"Privacy update failed"];
        [ProgressHUD showError:str];
        [self unfreezeUI];
    }];

    [self.fluxDataManager editPrivacyOfImageWithImageID:imageIDs to:newPrivacyIsPrivate withDataRequest:request];
}

- (void)addToDeleteQueue{
    deletedImages++;
    if (deletedImages == removedImages.count) {
        [ProgressHUD showSuccess:@"Deleted"];
        [self unfreezeUI];
        
        if ([delegate respondsToSelector:@selector(FluxProfilePhotosViewController:didPopAndDeleteImages:)]) {
            [delegate FluxProfilePhotosViewController:self didPopAndDeleteImages:deletedImages];
        }
        
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
    static NSString *identifier = @"myCell";
    
    FluxPhotoCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    [cell setDelegate:self];
    if (isEditing) {
        [cell.checkboxButton setHidden:NO];
        if ([removedImages containsObject:[NSNumber numberWithInt:(int)indexPath.row]]) {
            [cell.checkboxButton setChecked:YES];
            [cell.imageView setAlpha:0.8];
        }
        else{
            [cell.checkboxButton setChecked:NO];
            [cell.imageView setAlpha:1.0];
        }
    }
    else{
        [cell.checkboxButton setHidden:YES];
    }
    if (![(FluxProfileImageObject*)[picturesArray objectAtIndex:indexPath.row]image]) {
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@images/%i/renderimage?size=%@&auth_token=%@",FluxServerURL,[[picturesArray objectAtIndex:indexPath.row]imageID],fluxImageTypeStrings[thumb], [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService]]]];
        [cell.imageView setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.1]];
        [cell.imageView setImageWithURLRequest:request placeholderImage:[UIImage imageNamed:@"nothing"]
             success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                 if (image) {
                     //                 CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], CGRectMake(0, (image.size.height) - (image.size.width), image.size.width*0.68, image.size.width*0.68));
                     //                 // or use the UIImage wherever you like
                     //                 UIImage*cropppedImg = [UIImage imageWithCGImage:imageRef];
                     //                 CGImageRelease(imageRef);
                     //
                     //                 [(FluxProfileImageObject*)[picturesArray objectAtIndex:indexPath.row]setImage:cropppedImg];
                     [(FluxProfileImageObject*)[picturesArray objectAtIndex:indexPath.row]setImage:image];
                     [collectionView reloadItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
                 }

             }
             failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error){
                 NSLog(@"failed image loading: %@", error);
             }];
    }
    cell.imageView.image = [(FluxProfileImageObject*)[picturesArray objectAtIndex:indexPath.row]image];
    
    BOOL locked = [(FluxProfileImageObject*)[picturesArray objectAtIndex:indexPath.row]privacy];
    if (locked) {
        [cell.lockImageView setImage:[UIImage imageNamed:@"lockClosed"]];
    }
    else{
        [cell.lockImageView setImage:[UIImage imageNamed:@"lockOpen"]];
    }
    
    [cell.imageView setAlpha:1.0];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (isEditing) {
        if ([removedImages containsObject:[NSNumber numberWithInt:(int)indexPath.row]]) {
            [removedImages removeObject:[NSNumber numberWithInt:(int)indexPath.row]];
            if (removedImages.count == 0) {
                [garbageButton setEnabled:NO];
                [editPrivacyButton setEnabled:NO];
                
                [editPrivacyButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: disabledColor, NSForegroundColorAttributeName,NSFontAttributeName, [UIFont fontWithName:@"Akkurat" size:17.0], nil] forState:UIControlStateNormal];
            }
            [theCollectionView reloadData];
        }
        else{
            [removedImages addObject:[NSNumber numberWithInt:(int)indexPath.row]];
            [theCollectionView reloadData];
            [garbageButton setEnabled:YES];
            [editPrivacyButton setEnabled:YES];
            [editPrivacyButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: enabledColor, NSForegroundColorAttributeName,NSFontAttributeName, [UIFont fontWithName:@"Akkurat" size:17.0], nil] forState:UIControlStateNormal];
        }
        [self calculateNewPrivacy];
        
    }
    //else present a photo viewer
    else{
        NSMutableArray*photoURLs = [[NSMutableArray alloc]init];
        NSString *token = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
        for (int i = 0; i<picturesArray.count; i++) {
            NSString*urlString = [NSString stringWithFormat:@"%@images/%i/renderimage?size=%@&auth_token=%@",FluxServerURL, [[picturesArray objectAtIndex:i]imageID], fluxImageTypeStrings[quarterhd],token];
            [photoURLs addObject:urlString];
        }
        FluxPhotoCollectionCell*cell = (FluxPhotoCollectionCell*)[collectionView cellForItemAtIndexPath:indexPath];
        IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotoURLs:photoURLs animatedFromView:cell.contentView];
        //[browser setDisplaysProfileInfo:NO];
        [browser setDisplayToolbar:NO];
        [browser setDisplayDoneButtonBackgroundImage:NO];
        [browser setInitialPageIndex:indexPath.row];
        [browser setDelegate:self];
        
        [cell.lockImageView setHidden:YES];
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        [self presentViewController:browser animated:YES completion:^{
            [cell.lockImageView setHidden:NO];
        }];
    }
}

- (void)photoBrowser:(IDMPhotoBrowser *)photoBrowser didDismissAtPageIndex:(NSUInteger)index{
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (void)calculateNewPrivacy{

    newPrivacyIsPrivate = NO;
    
    for (int i = 0; i<removedImages.count; i++) {
        int index= [(NSNumber*)[removedImages objectAtIndex:i]intValue];
        if (![(FluxProfileImageObject*)[picturesArray objectAtIndex:index] privacy]) {
            newPrivacyIsPrivate = YES;
            break;
        }
    }

    if (newPrivacyIsPrivate) {
        [editPrivacyButton setTitle:@"Make Private"];
    }
    else{

        [editPrivacyButton setTitle:@"Make Public"];
    }
}

#pragma mark - IB Actions

- (IBAction)garbageButtonAction:(id)sender {
    [UIActionSheet showInView:self.view
                    withTitle:(removedImages.count > 1 ? @"Are you sure you want to delete these images from Flux? This action cannot be undone." : @"Are you sure you'd like to delete this image? This action cannot be undone.")
            cancelButtonTitle:@"Cancel"
       destructiveButtonTitle:@"Delete"
            otherButtonTitles:nil
                     tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                         if (buttonIndex != actionSheet.cancelButtonIndex) {
                             [self deleteImages];
                         }
                     }];
}

- (IBAction)editPrivacyButtonAction:(id)sender {
    NSString*buttonTitle;
    if (newPrivacyIsPrivate) {
        buttonTitle = (removedImages.count > 1 ? @"Make Selected Images Private" : @"Make This Image Private");
    }
    else{
        buttonTitle =(removedImages.count > 1 ? @"Make Selected Images Public" : @"Make This Image Public");
    }
    [UIActionSheet showInView:self.view
                        withTitle:nil
                cancelButtonTitle:@"Cancel"
       destructiveButtonTitle:nil
                otherButtonTitles:@[buttonTitle]
                         tapBlock:^(UIActionSheet *actionSheet, NSInteger buttonIndex) {
                             if (buttonIndex != actionSheet.cancelButtonIndex) {
                                 [self editImagePrivacy];
                             }
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
        [removedImages removeAllObjects];
    }
    else{
        [editBarButton setTitle:@"Edit"];
        [self.navigationController setToolbarHidden:YES animated:YES];
    }
    
    [theCollectionView reloadData];
}
@end
