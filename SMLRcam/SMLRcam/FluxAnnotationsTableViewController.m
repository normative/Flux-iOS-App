//
//  FluxAnnotationsTableViewController.m
//  Flux
//
//  Created by Kei Turner on 2013-08-12.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxAnnotationsTableViewController.h"
#import "FluxAnnotationTableViewCell.h"
#import "FluxScanImageObject.h"

#import "IDMPhotoBrowser.h"

@interface FluxAnnotationsTableViewController ()

@end

@implementation FluxAnnotationsTableViewController

@synthesize tableViewdict;


-(void)NetworkServices:(FluxNetworkServices *)aNetworkServices didreturnImage:(UIImage *)image forImageID:(int)imageID{
    
    [[self.tableViewdict objectForKey:[NSString stringWithFormat:@"%i",imageID]]setContentImage:image];
    
    NSArray * arr = [self.tableViewdict allKeys];
    int index = [arr indexOfObject:[self.tableViewdict objectForKey:[NSString stringWithFormat:@"%i",imageID]]];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:[NSIndexPath indexPathForRow:index inSection:1], nil] withRowAnimation:UITableViewRowAnimationFade];
}

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
     networkServices = [[FluxNetworkServices alloc]init];
    [networkServices setDelegate:self];
    
    //self.tableViewdict = [[NSMutableDictionary alloc]init];
    
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

- (void)setTableViewDictionary:(NSMutableDictionary*)imageDict{
    self.tableViewdict = [[NSMutableDictionary alloc]initWithDictionary:imageDict];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[self.tableViewdict allKeys] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"annotationsFeedCell";
    FluxAnnotationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier ];
    
    if (cell == nil) {
        cell = [[FluxAnnotationTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.descriptionLabel.text = [[self.tableViewdict objectForKey:[[self.tableViewdict allKeys]objectAtIndex:indexPath.row]]descriptionString];
    
    //cell.descriptionLabel.text = [[self.annotationsTableViewArray objectAtIndex:indexPath.row]descriptionString];
    cell.userLabel.text = [NSString stringWithFormat:@"User: %i",[[self.tableViewdict objectForKey:[[self.tableViewdict allKeys]objectAtIndex:indexPath.row]]userID]];
    cell.imageID = (int)[[self.tableViewdict allKeys]objectAtIndex:indexPath.row];
    
    if ([[self.tableViewdict objectForKey:[[self.tableViewdict allKeys]objectAtIndex:indexPath.row]]contentImage] == nil) {
        [networkServices getThumbImageForID:[[self.tableViewdict objectForKey:[[self.tableViewdict allKeys]objectAtIndex:indexPath.row]]imageID]];
    }
    else
        [cell.contentImageView setImage:[[self.tableViewdict objectForKey:[[self.tableViewdict allKeys]objectAtIndex:indexPath.row]]contentImage]];
    
    NSDateFormatter *formatter  = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd MMM, YYYY"];
    [cell.timestampLabel setText:[[self.tableViewdict objectForKey:[[self.tableViewdict allKeys]objectAtIndex:indexPath.row]]timestampString]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
//    NSArray *photosURL = @[[NSURL URLWithString:@"http://farm4.static.flickr.com/3567/3523321514_371d9ac42f_b.jpg"],
//                           [NSURL URLWithString:@"http://farm4.static.flickr.com/3629/3339128908_7aecabc34b_b.jpg"],
//                           [NSURL URLWithString:@"http://farm4.static.flickr.com/3364/3338617424_7ff836d55f_b.jpg"],
//                           [NSURL URLWithString:@"http://farm4.static.flickr.com/3590/3329114220_5fbc5bc92b_b.jpg"]];
//    
//    // Create an array to store IDMPhoto objects
//    NSMutableArray *photos = [[NSMutableArray alloc] init];
//    
//    for (NSURL *url in photosURL) {
//        IDMPhoto *photo = [IDMPhoto photoWithURL:url];
//        [photos addObject:photo];
//    }
//    
//    //IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:photos animatedFromView:[tableView cellForRowAtIndexPath:indexPath].contentView];
//    IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:photos];
//    browser.displayArrowButton = NO;
//    
//    // Show
//    [self presentViewController:browser animated:YES completion:nil];
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
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
