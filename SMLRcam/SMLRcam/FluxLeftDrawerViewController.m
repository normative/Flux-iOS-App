//
//  FluxLeftDrawerViewController.m
//  Flux
//
//  Created by Jacky So on 25/10/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxLeftDrawerViewController.h"
#import "TestFlight.h"
#import "TestFlight+OpenFeedback.h"
#import "FluxCountTableViewCell.h"
#import "FluxProfileCell.h"
#import "UICKeyChainStore.h"
#import "ProgressHUD.h"
#import "FluxImageTools.h"

#import "FluxSettingsViewController.h"
#import "FluxProfilePhotosViewController.h"
#import "FluxEditProfileViewController.h"

@interface FluxLeftDrawerViewController ()

@end

@implementation FluxLeftDrawerViewController

#pragma mark - View Init


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillDisappear:(BOOL)animated{
    [UIView animateWithDuration:0.2 animations:^{
        [self.tableView setAlpha:0.0];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [UIView animateWithDuration:0.25 animations:^{
        [self.tableView setAlpha:1.0];
    }];
}



- (void)viewDidLoad
{
    [self.view setAlpha:0.0];
    [super viewDidLoad];
    
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    
    
    
    
    tableViewArray = [self tableViewArrayForUser:nil];
    isEditing = NO;
    
    self.navigationItem.rightBarButtonItem =  [[UIBarButtonItem alloc] initWithTitle: @"Done"
                                                                              style: UIBarButtonItemStylePlain
                                                                             target: self
                                                                             action: @selector(doneButtonAction)];
    
    NSString * version = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    NSString * build = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];
    
    
    [self.versionLbl setText:[NSString stringWithFormat:@"Flux v.%@ (%@)",version,build]];
    [self.versionLbl setFont:[UIFont fontWithName:@"Akkurat" size:self.versionLbl.font.pointSize]];
    [self.feedbackButton.titleLabel setFont:[UIFont fontWithName:@"Akkurat-Bold" size:self.feedbackButton.titleLabel.font.pointSize]];
    
    NSString *userID = [UICKeyChainStore stringForKey:FluxUserIDKey service:FluxService];
    if (!userID) {
        NSString *a = [UICKeyChainStore stringForKey:FluxPasswordKey service:FluxService];
        NSString *s = [UICKeyChainStore stringForKey:FluxTokenKey service:FluxService];
        NSString *d = [UICKeyChainStore stringForKey:FluxEmailKey service:FluxService];
    }

    //**should** always pass
    if (userID) {
        FluxDataRequest*request = [[FluxDataRequest alloc]init];
        [request setUserReady:^(FluxUserObject*userObject, FluxDataRequest*completedRequest){
            userObj = userObject;
            tableViewArray = [self tableViewArrayForUser:userObject];
            [self.tableView reloadData];
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:userObject.bio forKey:@"bio"];
            
            if (userObject.hasProfilePic) {
                
                
//                if (![defaults objectForKey:@"profileImage"]) {
                if (true) {
                    FluxDataRequest*picRequest = [[FluxDataRequest alloc]init];
                    [picRequest setUserPicReady:^(UIImage*img, int userID, FluxDataRequest*completedRequest){
                        [userObj setProfilePic:img];
                        NSData *pngData = UIImagePNGRepresentation(img);
                        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                        NSString *documentsPath = [paths objectAtIndex:0]; //Get the docs directory
                        NSString *filePath = [documentsPath stringByAppendingPathComponent:@"image.png"]; //Add the file name
                        [pngData writeToFile:filePath atomically:YES]; //Write the file
                        
                        [defaults setObject:filePath forKey:@"profileImage"];
                        [defaults synchronize];
                        
                        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                    }];
                    [picRequest setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
                        NSString*str = [NSString stringWithFormat:@"Profile picture failed with error %d", (int)[e code]];
                        [ProgressHUD showError:str];
                    }];
                    [self.fluxDataManager requestUserProfilePicForID:userID.integerValue andSize:@"thumb" withDataRequest:picRequest];
                }
                else{
                    NSData *pngData = [NSData dataWithContentsOfFile:[defaults objectForKey:@"profileImage"]];
                    UIImage *image = [UIImage imageWithData:pngData];
                    [userObj setProfilePic:image];
                }
            }
        }];
        [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
            NSString*str = [NSString stringWithFormat:@"Profile load failed with error %d", (int)[e code]];
            [ProgressHUD showError:str];
        }];
        
        [self.fluxDataManager requestUserProfileForID:userID.integerValue withDataRequest:request];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - tableView Init
- (NSMutableArray*)tableViewArrayForUser:(FluxUserObject*)user{
    NSMutableArray*newTableArray;
    if (user) {
        NSMutableDictionary*tmp1 = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInt:user.imageCount], @"Photos" , nil];
//        NSMutableDictionary*tmp2 = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInt:user.followingCount], @"Following" , nil];
//        NSMutableDictionary*tmp3 = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInt:user.followerCount], @"Followers" , nil];
//        NSMutableDictionary*tmp4 = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInt:user.friendCount], @"Friends" , nil];
        NSMutableDictionary*tmp5 = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInt:0], @"Settings" , nil];
        newTableArray = [[NSMutableArray alloc]initWithObjects:tmp1, /*tmp2, tmp3, tmp4,*/ tmp5, nil];
    }
    else{
        NSMutableDictionary*tmp1 = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInt:0], @"Photos" , nil];
        NSMutableDictionary*tmp2 = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInt:0], @"Following" , nil];
        NSMutableDictionary*tmp3 = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInt:0], @"Followers" , nil];
        NSMutableDictionary*tmp4 = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInt:0], @"Friends" , nil];
        NSMutableDictionary*tmp5 = [[NSMutableDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithInt:0], @"Settings" , nil];
        newTableArray = [[NSMutableArray alloc]initWithObjects:tmp1, /*tmp2, tmp3, tmp4,*/ tmp5, nil];
    }
    return newTableArray;
}

- (void)didUpdateProfileWithChanges:(NSDictionary*)changesDict{
    
    //only supports these two for now, and profilePic is loaded from defaults anyway
    if ([changesDict objectForKey:@"bio"]) {
        [userObj setBio:[changesDict objectForKey:@"bio"]];
    }
    if ([changesDict objectForKey:@"profilePic"]) {
        [userObj setProfilePic:[changesDict objectForKey:@"profilePic"]];
    }
    tableViewArray = [self tableViewArrayForUser:userObj];
    [self.tableView reloadData];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return tableViewArray.count+1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row>0) {
        return 44.0;
    }
    return 120.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"standardLeftCell";
    FluxCountTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[FluxCountTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    [cell initCell];
    if (indexPath.row == 0) {
        
        NSString *cellIdentifier = @"profileCell";
        FluxProfileCell * profileCell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!profileCell) {
            profileCell = [[FluxProfileCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        }
        [profileCell initCellisEditing:isEditing];
        
        NSString *username = [UICKeyChainStore stringForKey:FluxUsernameKey service:FluxService];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString*bio = (NSString*)[defaults objectForKey:@"bio"];
        if (username) {
            [profileCell setUsernameText:username];
        }
        
        if (userObj.bio) {
            [profileCell setBioText:userObj.bio];
        }
        else{
            [profileCell setBioText:bio];
        }
        

        if ([defaults objectForKey:@"profileImage"]) {
            
            NSData *pngData = [NSData dataWithContentsOfFile:[defaults objectForKey:@"profileImage"]];
            UIImage *image = [UIImage imageWithData:pngData];
            
            if (image)
            {
                [profileCell.profileImageButton setBackgroundImage:image forState:UIControlStateNormal];
            }
            else
            {
                [profileCell.profileImageButton setBackgroundImage:[UIImage imageNamed:@"emptyProfileImage_big"] forState:UIControlStateNormal];
            }
        }
        else{
            [profileCell.profileImageButton setBackgroundImage:[UIImage imageNamed:@"emptyProfileImage_big"] forState:UIControlStateNormal];
        }
        

        [profileCell hideCamStats];
        return profileCell;
    }
    //settings
    else if (indexPath.row == tableViewArray.count){
        cell.titleLabel.text = (NSString*)[[[tableViewArray objectAtIndex:indexPath.row-1]allKeys]firstObject];
        cell.countLabel.text = @"";
        [cell.titleLabel setEnabled:YES];
        
        //hack for hiding other cells. should be removed once they're active
        return cell;
    }
    //disable social
    else if(indexPath.row == 2 || indexPath.row == 3 || indexPath.row == 4){
        cell.titleLabel.text = (NSString*)[[[tableViewArray objectAtIndex:indexPath.row-1]allKeys]firstObject];
        cell.countLabel.text = [NSString stringWithFormat:@"%i",[(NSNumber*)[[tableViewArray objectAtIndex:indexPath.row-1]objectForKey:[[[tableViewArray objectAtIndex:indexPath.row-1]allKeys]firstObject]]intValue]];
        [cell.titleLabel setEnabled:NO];
        [cell.countLabel setEnabled:NO];
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    }
    
    else{
        cell.titleLabel.text = (NSString*)[[[tableViewArray objectAtIndex:indexPath.row-1]allKeys]firstObject];
        cell.countLabel.text = [NSString stringWithFormat:@"%i",[(NSNumber*)[[tableViewArray objectAtIndex:indexPath.row-1]objectForKey:[[[tableViewArray objectAtIndex:indexPath.row-1]allKeys]firstObject]]intValue]];
        [cell.titleLabel setEnabled:YES];
        [cell.countLabel setEnabled:YES];
    }
    //[cell.imageView setImage:[UIImage imageNamed:@"imageViewerClock"]];
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row)
    {
        case 0:
            [self performSegueWithIdentifier:@"pushEditProfileSegue" sender:self];
            break;
        case 1:
            [self performSegueWithIdentifier:@"pushPhotosSegue" sender:nil];
            break;
        case 2:
            [self performSegueWithIdentifier:@"pushSettingsSegue" sender:nil];
            
            break;
        case 3:
                [tableView deselectRowAtIndexPath:indexPath animated:NO];
            break;
        case 4:
                [tableView deselectRowAtIndexPath:indexPath animated:NO];
            break;
        case 5:
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
            break;
            
        default:
            break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - IBActions

- (IBAction)onSendFeedBackBtn:(id)sender
{
    [TestFlight openFeedbackViewFromView:self];
}

- (IBAction)doneButtonAction {
    if (isEditing) {
        //save edits
    }
    else{
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)editProfileAction:(id)sender {

    
    
    //if inline
//    isEditing = YES;
//    [self setTitle:@"Edit Profile"];
//    [self.navigationItem.rightBarButtonItem setTitle:@"Save"];
//    [self.navigationItem.rightBarButtonItem setEnabled:NO];
//
//    
//    self.navigationItem.leftBarButtonItem =  [[UIBarButtonItem alloc] initWithTitle: @"Cancel"
//                                                                               style: UIBarButtonItemStylePlain
//                                                                              target: self
//                                                                              action: @selector(cancelEdit)];
//    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
}

- (IBAction)editProfleImageAction:(id)sender {
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
        //actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
        [actionSheet showInView:self.view];
    }
}

- (void)cancelEdit{
    isEditing = NO;
    [self setTitle:@"Profile"];
    [self.navigationItem.rightBarButtonItem setTitle:@"Done"];
    [self.navigationItem.rightBarButtonItem setEnabled:YES];
    self.navigationItem.leftBarButtonItem = nil;
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
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
            //set the image in here.
            [[(FluxProfileCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]profileImageButton]setBackgroundImage:image forState:UIControlStateNormal];
        });
    });
    
    if (!newProfileImage)
    {
        return;
    }
    
    // Adjusting Image Orientation
    //    NSData *data = UIImagePNGRepresentation(newProfileImage);
    //    UIImage *tmp = [UIImage imageWithData:data];
    //    UIImage *fixed = [UIImage imageWithCGImage:tmp.CGImage
    //                                         scale:newProfileImage.scale
    //                                   orientation:newProfileImage.imageOrientation];
    //    newProfileImage = fixed;
    
}

#pragma mark - delegate

- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"pushEditProfileSegue"])
    {
        FluxEditProfileViewController* editProfileVC = (FluxEditProfileViewController*)segue.destinationViewController;
        [editProfileVC setFluxDataManager:self.fluxDataManager];
        NSString *email = [UICKeyChainStore stringForKey:FluxEmailKey service:FluxService];
        [userObj setEmail:email];
        [editProfileVC prepareViewWithUser:userObj];
    }

    if ([[segue identifier] isEqualToString:@"pushSettingsSegue"])
    {
        FluxSettingsViewController* leftDrawerSettingsViewController = (FluxSettingsViewController*)segue.destinationViewController;
        leftDrawerSettingsViewController.fluxDataManager = self.fluxDataManager;
    }
    if ([[segue identifier] isEqualToString:@"pushPhotosSegue"]){
        [(FluxProfilePhotosViewController*)segue.destinationViewController setFluxDataManager:self.fluxDataManager];
        [(FluxProfilePhotosViewController*)segue.destinationViewController prepareViewWithImagesUserID:[UICKeyChainStore stringForKey:FluxUserIDKey service:FluxService].integerValue];
    }
}

@end
