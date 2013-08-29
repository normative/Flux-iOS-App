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

#pragma mark - delegate methods

// Network delegate
- (void)NetworkServices:(FluxNetworkServices *)aNetworkServices
         didreturnImage:(UIImage *)image
             forImageID:(int)imageID
{
    NSNumber *objKey = [NSNumber numberWithInt: imageID];
    [[self.tableViewdict objectForKey:objKey] setContentImage:image];
    
    NSArray * arr = [self.tableViewdict allKeys];
    int index = [arr indexOfObject:objKey];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:[NSIndexPath indexPathForRow:index inSection:0], nil] withRowAnimation:UITableViewRowAnimationFade];
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
    return [self.tableViewdict count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"annotationsFeedCell";
    FluxAnnotationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil)
    {
        cell = [[FluxAnnotationTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                  reuseIdentifier:CellIdentifier];
    }

    NSNumber *objkey = [[self.tableViewdict allKeys] objectAtIndex:indexPath.row];
    FluxScanImageObject *rowObject = [self.tableViewdict objectForKey: objkey];
    
    cell.imageID = rowObject.imageID;
    if (rowObject.contentImage == nil)
    {
        [networkServices getThumbImageForID:cell.imageID];
    }
    else
        [cell.contentImageView setImage:rowObject.contentImage];
    cell.descriptionLabel.text = rowObject.descriptionString;
    cell.userLabel.text = [NSString stringWithFormat:@"User: %i",rowObject.userID];
    cell.timestampLabel.text = rowObject.timestampString;

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


#pragma mark - view lifecycle

- (void)dismissPopoverAnimated:(BOOL)animated{
    if (animated) {
        [UIView animateWithDuration:0.3f
                         animations:^{
                             [self.view setAlpha:0.0];
                         }
                         completion:^(BOOL finished){
                             [self.view setHidden:YES];
                         }];
    }
    else{
        [self.view setAlpha:0.0];
        [self.view setHidden:YES];
    }

}
- (void)showPopoverAnimated:(BOOL)animated{
    if (animated) {
        [self.view setHidden:NO];
        [UIView animateWithDuration:0.3f
                         animations:^{
                             [self.view setAlpha:1.0];
                         }
                         completion:nil];
    }
    else{
        [self.view setHidden:NO];
        [self.view setAlpha:1.0];
    }

}

- (BOOL)popoverIsHidden{
    return self.view.isHidden;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    
    if (self)
    {
        // Custom initialization
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super initWithCoder:aDecoder])
    {
        self.tableViewdict = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    networkServices = [[FluxNetworkServices alloc]init];
    [networkServices setDelegate:self];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidAppear:(BOOL)animated{
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
