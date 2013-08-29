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
#import <QuartzCore/QuartzCore.h>

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

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return @"Tags Nearby";
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(20, 0, 100, 22);
    label.textColor = [UIColor lightGrayColor];
    [label setFont:[UIFont fontWithName:@"Akkurat" size:14]];
    label.text = [self tableView:tableView titleForHeaderInSection:section];
    label.backgroundColor = [UIColor clearColor];
    
    UIView*backgroundView = [[UIView alloc] initWithFrame:CGRectMake(2, 0, 316, 24)];
    [backgroundView setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.65]];
    
    // Create header view and add label as a subview
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 22)];
    [view setBackgroundColor:[UIColor clearColor]];
    [view addSubview:backgroundView];
    [view addSubview:label];
    
    
    
    return view;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.tableViewdict count];
}

- (float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    FluxAnnotationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"annotationsFeedCell"];
    return cell.frame.size.height;
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

//remove all but selected cell - not called right now
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSMutableArray *cellIndicesToBeDeleted = [[NSMutableArray alloc] init];
    for (int i = 0; i < [tableView numberOfRowsInSection:0]; i++) {
        if (i != indexPath.row) {
            NSIndexPath *p = [NSIndexPath indexPathForRow:i inSection:1];
            [cellIndicesToBeDeleted addObject:p];
        }
    }
    [tableView deleteRowsAtIndexPaths:cellIndicesToBeDeleted
                     withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.view.layer.mask.position = CGPointMake(0, scrollView.contentOffset.y);
    [CATransaction commit];
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
    if ([self.tableViewdict count]>0) {
        [self.tableView reloadData];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
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
    [self.view setBackgroundColor:[UIColor clearColor]];
    
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

@end
