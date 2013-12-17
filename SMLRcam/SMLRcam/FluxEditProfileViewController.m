//
//  FluxEditProfileViewController.m
//  Flux
//
//  Created by Kei Turner on 11/29/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxEditProfileViewController.h"
#import "FluxImageTools.h"

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
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0,0, tableView.frame.size.width, 20)];
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 3;
            break;
        case 1:
            return 2;
            break;
        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
        {
            if (indexPath.row == 0) {
                static NSString *CellIdentifier = @"picCell";
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
                UIImageView*imgView = (UIImageView*)[cell viewWithTag:10];
                return cell;
            }
            else if (indexPath.row == 1){
                static NSString *CellIdentifier = @"textCell";
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
                UILabel*titleLabel = (UILabel*)[cell viewWithTag:10];
                [titleLabel setTextColor:[UIColor whiteColor]];
                [titleLabel setText:@"Username"];
                [titleLabel setFont:[UIFont fontWithName:@"Akkurat" size:titleLabel.font.pointSize]];
                
                UITextField*textField = (UITextField*)[cell viewWithTag:20];
                [textField setFont:[UIFont fontWithName:@"Akkurat" size:titleLabel.font.pointSize]];
                [textField setText:@""];
                return cell;
            }
            else{
                static NSString *CellIdentifier = @"textCell";
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
                UILabel*titleLabel = (UILabel*)[cell viewWithTag:10];
                [titleLabel setTextColor:[UIColor whiteColor]];
                [titleLabel setText:@"Bio"];
                [titleLabel setFont:[UIFont fontWithName:@"Akkurat" size:titleLabel.font.pointSize]];
                
                UITextField*textField = (UITextField*)[cell viewWithTag:20];
                [textField setFont:[UIFont fontWithName:@"Akkurat" size:titleLabel.font.pointSize]];
                [textField setText:@""];
                return cell;
            }
        }
        break;
        case 1:
        {
            if (indexPath.row==0) {
                static NSString *CellIdentifier = @"textCell";
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
                UILabel*titleLabel = (UILabel*)[cell viewWithTag:10];
                [titleLabel setTextColor:[UIColor whiteColor]];
                [titleLabel setText:@"Full Name"];
                [titleLabel setFont:[UIFont fontWithName:@"Akkurat" size:titleLabel.font.pointSize]];
                
                UITextField*textField = (UITextField*)[cell viewWithTag:20];
                [textField setFont:[UIFont fontWithName:@"Akkurat" size:titleLabel.font.pointSize]];
                [textField setText:@""];
                return cell;
            }
            else {
                static NSString *CellIdentifier = @"textCell";
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
                UILabel*titleLabel = (UILabel*)[cell viewWithTag:10];
                [titleLabel setTextColor:[UIColor whiteColor]];
                [titleLabel setText:@"Email"];
                [titleLabel setFont:[UIFont fontWithName:@"Akkurat" size:titleLabel.font.pointSize]];
                
                UITextField*textField = (UITextField*)[cell viewWithTag:20];
                [textField setFont:[UIFont fontWithName:@"Akkurat" size:titleLabel.font.pointSize]];
                [textField setText:@""];
                return cell;
            }
        }
        break;
            
        default:
            return nil;
            break;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    switch (indexPath.row) {
        case 0:
        {
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
        break;
            
        default:
            break;
    }
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
            //set the image in here.
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

@end
