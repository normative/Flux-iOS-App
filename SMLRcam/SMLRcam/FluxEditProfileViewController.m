//
//  FluxEditProfileViewController.m
//  Flux
//
//  Created by Kei Turner on 11/29/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxEditProfileViewController.h"
#import "FluxImageTools.h"
#import "UICKeyChainStore.h"
#import "ProgressHUD.h"

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
    if (userObject.profilePic) {
        [profileImageButton setBackgroundImage:userObject.profilePic forState:UIControlStateNormal];
    }
    else{
        [profileImageButton setBackgroundImage:[UIImage imageNamed:@"emptyProfileImage"] forState:UIControlStateNormal];
    }
    
    [usernameLabel setText:userObject.username];
    if (userObject.bio) {
        [bioTextField setText:userObject.bio];
    }
    [bioTextField becomeFirstResponder];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
- (void)PlaceholderTextViewDidBeginEditing:(KTPlaceholderTextView *)placeholderTextView{
    [editedDictionary setObject:placeholderTextView.text forKey:@"bio"];
}


#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    int i = buttonIndex;
    switch(i)
    {
        case 0:
        {
            UIImagePickerController * picker = [[UIImagePickerController alloc] init];
            [picker setDelegate:self];
            picker.sourceType = UIImagePickerControllerSourceTypeCamera;
            [picker setAllowsEditing:YES];
            [self presentViewController:picker animated:YES completion:^{}];
        }
            break;
        case 1:
        {
            UIImagePickerController * picker = [[UIImagePickerController alloc] init];
            [picker setDelegate:self];
            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            [picker setAllowsEditing:YES];
            [self presentViewController:picker animated:YES completion:^{}];
        }
        default:
            break;
    }
}

#pragma - Image Picker Deleagte
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // Picking Image from Camera/ Library
    [picker dismissViewControllerAnimated:YES completion:^{}];
    UIImage*newProfileImage = info[UIImagePickerControllerEditedImage];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Set desired maximum height and calculate width
        CGFloat height = 140.0;  // or whatever you need
        CGFloat width = 140.0;
        
        FluxImageTools*imageTools = [[FluxImageTools alloc]init];
        
        // Resize the image
        UIImage * image =  [imageTools resizedImage:newProfileImage toSize:CGSizeMake(width, height) interpolationQuality:kCGInterpolationDefault];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [profileImageButton setBackgroundImage:image forState:UIControlStateNormal];
            [editedDictionary setObject:image forKey:@"profilePic"];
            [bioTextField becomeFirstResponder];
            
        });
    });
    
    if (!newProfileImage)
    {
        return;
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [bioTextField becomeFirstResponder];
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
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//                [defaults setObject:[editedDictionary objectForKey:@"profilePic"] forKey:@"profilePic"];
                [defaults setObject:UIImagePNGRepresentation([editedDictionary objectForKey:@"profilePic"]) forKey:@"profilePic"];
                [defaults synchronize];
                [ProgressHUD showSuccess:@"Done"];
                [self.navigationController popViewControllerAnimated:YES];
            }
        }];
        [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
            NSString*str = [NSString stringWithFormat:@"Profile update failed with error %d", (int)[e code]];
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
