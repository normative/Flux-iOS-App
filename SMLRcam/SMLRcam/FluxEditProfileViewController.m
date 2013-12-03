//
//  FluxEditProfileViewController.m
//  Flux
//
//  Created by Kei Turner on 11/29/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxEditProfileViewController.h"

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
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
