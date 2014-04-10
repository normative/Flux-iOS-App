//
//  FluxEditProfileViewController.m
//  Flux
//
//  Created by Kei Turner on 11/29/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxEditProfileViewController.h"
#import "FluxLeftDrawerViewController.h"
#import "FluxImageTools.h"
#import "UICKeyChainStore.h"
#import "ProgressHUD.h"

#import "DZNPhotoPickerController.h"
#import "UIImagePickerController+Edit.h"

@interface FluxEditProfileViewController ()

@end

@implementation FluxEditProfileViewController

- (void)prepareViewWithUser:(FluxUserObject *)theUserObject{
    userObject = theUserObject;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (firstTime) {
        firstTime = NO;
        if (userObject.profilePic) {
            [profileImageButton setBackgroundImage:userObject.profilePic forState:UIControlStateNormal];
        }
        else{
            [profileImageButton setBackgroundImage:[UIImage imageNamed:@"emptyProfileImage_big"] forState:UIControlStateNormal];
        }
        
        [usernameLabel setText:userObject.username];
        if (userObject.bio) {
            [bioTextField setText:userObject.bio];
        }
    }

    [bioTextField becomeFirstResponder];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.screenName = @"Edit Profile View";
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    firstTime = YES;
    saveButton = [[UIBarButtonItem alloc]initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(saveButtonAction:)];
    
    editedDictionary = [[NSMutableDictionary alloc]init];
    
    UILabel *editLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, profileImageButton.frame.size.height-25, profileImageButton.frame.size.width, 25)];
    editLabel.textColor = [UIColor colorWithRed:43/255.0 green:52/255.0 blue:58/255.0 alpha:0.7];
    [editLabel setTextAlignment:NSTextAlignmentCenter];
    [editLabel setText:@"Edit"];
    editLabel.font = [UIFont fontWithName:@"Akkurat" size:13.0];
    [editLabel setBackgroundColor:[UIColor lightGrayColor]];
    [editLabel setAlpha:0.5];
    [profileImageButton addSubview:editLabel];
    
    profileImageButton.layer.cornerRadius = profileImageButton.frame.size.height/2;
    profileImageButton.clipsToBounds = YES;
    
    [bioTextField setPlaceholderText:@"Tell others a bit about you"];
    //[bioTextField setCharCountVisible:NO];
    [bioTextField setMaxCharCount:90];
    [bioTextField setTheDelegate:self];


    CALayer *roundBorderLayer = [CALayer layer];
    roundBorderLayer.borderWidth = 0.5;
    roundBorderLayer.opacity = 0.4;
    roundBorderLayer.cornerRadius = 5;
    roundBorderLayer.borderColor = [UIColor whiteColor].CGColor;
    roundBorderLayer.frame = CGRectMake(0, 0, CGRectGetWidth(bioTextField.frame), CGRectGetHeight(bioTextField.frame));
    [bioTextField.layer addSublayer:roundBorderLayer];
    
    
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark PlaceholderTextView Delegate

- (void)PlaceholderTextViewDidEdit:(KTPlaceholderTextView *)placeholderTextView{
    [editedDictionary setObject:placeholderTextView.text forKey:@"bio"];
    
    if (![placeholderTextView.text isEqualToString:userObject.bio]) {
        self.navigationItem.rightBarButtonItem = saveButton;
    }
    else
    {
        self.navigationItem.rightBarButtonItem = nil;
        [editedDictionary removeObjectForKey:@"bio"];
    }
}


#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [bioTextField resignFirstResponder];
    int i = (int)buttonIndex;
    switch(i)
    {
        case 0:
        {
            [self presentImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
            
//            UIImagePickerController * picker = [[UIImagePickerController alloc] init];
//            [picker setDelegate:self];
//            picker.sourceType = UIImagePickerControllerSourceTypeCamera;
//            [picker setAllowsEditing:YES];
//            [self presentViewController:picker animated:YES completion:^{}];
        }
            break;
        case 1:
        {
            [self presentImagePickerForSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
            
//            UIImagePickerController * picker = [[UIImagePickerController alloc] init];
//            [picker setDelegate:self];
//            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
//            [picker setAllowsEditing:YES];
//            [self presentViewController:picker animated:YES completion:^{}];
        }
            break;
        case 2:
        {
            [bioTextField becomeFirstResponder];
        }
        default:
            break;
    }
}

#pragma - Image Picker Deleagte
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    UIImage *croppedImage = [info objectForKey:UIImagePickerControllerEditedImage];
    if (croppedImage) {
        [self saveImage:croppedImage];
        [picker dismissViewControllerAnimated:YES completion:nil];
        [bioTextField becomeFirstResponder];
    }
    else{
        DZNPhotoEditViewController *photoEditViewController = [[DZNPhotoEditViewController alloc] initWithImage:image cropMode:DZNPhotoEditViewControllerCropModeCircular];
        [picker pushViewController:photoEditViewController animated:YES];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
    [bioTextField becomeFirstResponder];
}

- (void)saveImage:(UIImage*)image{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Set desired maximum height and calculate width
        CGFloat height = 140.0;  // or whatever you need
        CGFloat width = 140.0;
        
        FluxImageTools*imageTools = [[FluxImageTools alloc]init];
        
        // Resize the image
        UIImage * newImage =  [imageTools resizedImage:image toSize:CGSizeMake(width, height) interpolationQuality:kCGInterpolationDefault];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [profileImageButton setBackgroundImage:image forState:UIControlStateNormal];
            [editedDictionary setObject:newImage forKey:@"profilePic"];
            [bioTextField becomeFirstResponder];
            
            self.navigationItem.rightBarButtonItem = saveButton;
            
        });
    });
}

#pragma mark - Photo Picker status bar bug fix delegate
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

#pragma mark - other

- (void)presentImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = sourceType;
    picker.allowsEditing = YES;
    picker.editingMode = DZNPhotoEditViewControllerCropModeCircular;
    picker.delegate = self;
    
    if (sourceType == UIImagePickerControllerSourceTypeCamera) {
        picker.cameraDevice=UIImagePickerControllerCameraDeviceFront;
    }
    
    
    [self presentViewController:picker animated:YES completion:^{
        //[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    }];

}

- (IBAction)editProfilePictureCell:(id)sender {
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
        
    {
        [self actionSheet:nil clickedButtonAtIndex:1];
    }
    else{
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Select a source"
                                                                 delegate:self
                                                        cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:@"Camera", @"Select from Library", nil];
        [actionSheet showInView:self.view];
    }
}

- (IBAction)saveButtonAction:(id)sender {
    if ([editedDictionary allKeys].count > 0) {
        [ProgressHUD show:@"Updating profile"];
        FluxDataRequest*request = [[FluxDataRequest alloc]init];
        [request setUpdateUserComplete:^(FluxUserObject*userObject, FluxDataRequest*completedRequest){
            if ([editedDictionary objectForKey:@"profilePic"]) {
                //save the image locally
                NSData *pngData = UIImagePNGRepresentation([editedDictionary objectForKey:@"profilePic"]);
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsPath = [paths objectAtIndex:0]; //Get the docs directory
                NSString *filePath = [documentsPath stringByAppendingPathComponent:@"image.png"]; //Add the file name
                [pngData writeToFile:filePath atomically:YES]; //Write the file
                
                //then save the path to defaults
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setObject:filePath forKey:@"profileImage"];
                [defaults synchronize];
                
//                //to retrieve the image:
//                NSData *pngData = [NSData dataWithContentsOfFile:filePath];
//                UIImage *image = [UIImage imageWithData:pngData];
            }
            [ProgressHUD showSuccess:@"Done"];
            [(FluxLeftDrawerViewController*)[self.navigationController.viewControllers objectAtIndex:0]didUpdateProfileWithChanges:editedDictionary];
            [self.navigationController popViewControllerAnimated:YES];
        }];
        [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
            NSString*str = [NSString stringWithFormat:@"Updating your profile sems to have failed, sorry about that."];
            [ProgressHUD showError:str];
        }];
        
        FluxUserObject*new = userObject;
        [new setPassword:[UICKeyChainStore stringForKey:FluxPasswordKey service:FluxService]];
        if ([editedDictionary objectForKey:@"bio"]) {
            [new setBio:[editedDictionary objectForKey:@"bio"]];
        }
        if ([editedDictionary objectForKey:@"username"]) {
            [new setUsername:[editedDictionary objectForKey:@"username"]];
        }
        if ([editedDictionary objectForKey:@"email"]) {
            [new setEmail:[editedDictionary objectForKey:@"email"]];
        }
        
        [self.fluxDataManager updateUser:new withImage:([editedDictionary objectForKey:@"profilePic"]) ? [editedDictionary objectForKey:@"profilePic"] : nil withDataRequest:request];
    }
}


@end
