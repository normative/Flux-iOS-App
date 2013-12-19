//
//  FluxEditProfileViewController.m
//  Flux
//
//  Created by Kei Turner on 11/29/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxEditProfileViewController.h"
#import "FluxImageTools.h"
#import "FluxProfileCell.h"
#import "UICKeyChainStore.h"
#import "ProgressHUD.h"

@interface FluxEditProfileViewController ()

@end

@implementation FluxEditProfileViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)prepareViewWithUser:(FluxUserObject *)theUserObject{
    userObject = theUserObject;
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return @"Public";
    }
    else
        return @"Private";
}

-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0,0, tableView.frame.size.width, [self tableView:tableView heightForHeaderInSection:section])];
    [view setBackgroundColor:[UIColor colorWithRed:110.0/255.0 green:116.0/255.0 blue:121.0/255.5 alpha:0.9]];
    
    // Create label with section title
    UILabel*label = [[UILabel alloc] init];
    label.frame = CGRectMake(20, 2, 150, 20);
    label.textColor = [UIColor whiteColor];
    [label setFont:[UIFont fontWithName:@"Akkurat" size:12]];
    label.text = [self tableView:tableView titleForHeaderInSection:section];
    label.backgroundColor = [UIColor clearColor];
    [label setCenter:CGPointMake(label.center.x, label.center.y)];
    [view addSubview:label];
    return view;
}

- (float)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return 0;
    }
    else
        return 20.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 0) {
        return 120.0;
    }
    return 44.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
        {
            NSString *cellIdentifier = @"profileCell";
            FluxProfileCell * profileCell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            if (!profileCell) {
                profileCell = [[FluxProfileCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
            }
            [profileCell initCellisEditing:YES];
            
            NSString *username = [UICKeyChainStore stringForKey:FluxUsernameKey service:FluxService];
            if (username) {
                [profileCell.usernameLabel setText:userObject.username];
            }
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            if ([defaults objectForKey:@"bio"]) {
                [profileCell.bioLabel setText:[defaults objectForKey:@"bio"]];
            }
            
            if ([defaults objectForKey:@"profilePic"]) {
                [profileCell.profileImageButton setBackgroundImage:[defaults objectForKey:@"profilePic"] forState:UIControlStateNormal];
            }
            else{
                [profileCell.profileImageButton setBackgroundImage:[UIImage imageNamed:@"emptyProfileImage"] forState:UIControlStateNormal];
            }
            [profileCell hideCamStats];
            [profileCell setSelectionStyle:UITableViewCellSelectionStyleNone];
            return profileCell;
        }
        break;
        case 1:
        {
            static NSString *CellIdentifier = @"textCell";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
            UILabel*titleLabel = (UILabel*)[cell viewWithTag:10];
            [titleLabel setTextColor:[UIColor whiteColor]];
            [titleLabel setText:@"Email"];
            [titleLabel setFont:[UIFont fontWithName:@"Akkurat" size:titleLabel.font.pointSize]];
            
            UITextField*textField = (UITextField*)[cell viewWithTag:20];
            [textField setFont:[UIFont fontWithName:@"Akkurat" size:titleLabel.font.pointSize]];
            [textField setText:userObject.email];
            [textField setClearsOnBeginEditing:YES];
            
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            return cell;
        }
        break;
            
        default:
            return nil;
            break;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
            [[(FluxProfileCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]profileImageButton]setBackgroundImage:image forState:UIControlStateNormal];
            [editedDictionary setObject:image forKey:@"profilePic"];
        });
    });
    
    if (!newProfileImage)
    {
        return;
    }
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
                [defaults setObject:[editedDictionary objectForKey:@"profilePic"] forKey:@"profilePic"];
                [defaults synchronize];
                [ProgressHUD showSuccess:@"Done"];
                [self.navigationController popViewControllerAnimated:YES];
            }
        }];
        [request setErrorOccurred:^(NSError *e,NSString*description, FluxDataRequest *errorDataRequest){
            NSString*str = [NSString stringWithFormat:@"Profile load failed with error %d", (int)[e code]];
            [ProgressHUD showError:str];
        }];
        
        FluxUserObject*new = userObject;
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
