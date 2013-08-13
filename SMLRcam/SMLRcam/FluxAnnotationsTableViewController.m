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

@interface FluxAnnotationsTableViewController ()

@end

@implementation FluxAnnotationsTableViewController

@synthesize annotationsTableViewArray;

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
    
    FluxScanImageObject * obj1 = [[FluxScanImageObject alloc]init];
    [obj1 setTimestampDate:[NSDate date]];
    [obj1 setDescriptionString:@"Johny sitting in front of the CN Tower"];
    [obj1 setUserName:@"Karren246"];
    [obj1 setContentImage:[UIImage imageNamed:@"pic1.png"]];
    
    FluxScanImageObject * obj2 = [[FluxScanImageObject alloc]init];
    [obj2 setTimestampDate:[NSDate date]];
    [obj2 setDescriptionString:@"Great view of Toronto Western Hospital"];
    [obj2 setUserName:@"VDub19"];
    [obj2 setContentImage:[UIImage imageNamed:@"pic2.png"]];
    
    FluxScanImageObject * obj3 = [[FluxScanImageObject alloc]init];
    [obj3 setTimestampDate:[NSDate date]];
    [obj3 setDescriptionString:@"Best pork sandwiches in town!"];
    [obj3 setUserName:@"Jon_4"];
    [obj3 setContentImage:[UIImage imageNamed:@"pic3.png"]];
    
    FluxScanImageObject * obj4 = [[FluxScanImageObject alloc]init];
    [obj4 setTimestampDate:[NSDate date]];
    [obj4 setDescriptionString:@"Some cool graffiti"];
    [obj4 setUserName:@"my_username"];
    [obj4 setContentImage:[UIImage imageNamed:@"pic1.png"]];
    
    FluxScanImageObject * obj5 = [[FluxScanImageObject alloc]init];
    [obj5 setTimestampDate:[NSDate date]];
    [obj5 setDescriptionString:@"Chili Peppers live at the ACC!"];
    [obj5 setUserName:@"band_freak_47"];
    [obj5 setContentImage:[UIImage imageNamed:@"pic2.png"]];
    
    self.annotationsTableViewArray = [[NSArray alloc]initWithObjects:obj1,obj2,obj3,obj4,obj5, nil];
    

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

- (void)setTableViewArray:(NSArray*)array{
    self.annotationsTableViewArray = array;
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
    return self.annotationsTableViewArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"annotationsFeedCell";
    FluxAnnotationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier ];
    
    if (cell == nil) {
        cell = [[FluxAnnotationTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.descriptionLabel.text = [[self.annotationsTableViewArray objectAtIndex:indexPath.row]descriptionString];
    cell.userLabel.text = [[self.annotationsTableViewArray objectAtIndex:indexPath.row]userName];
    [cell.contentImageView setImage:[[self.annotationsTableViewArray objectAtIndex:indexPath.row]contentImage]];
    
    NSDateFormatter *formatter  = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd MMM, YYYY"];
    [cell.timestampLabel setText:[formatter stringFromDate:[[self.annotationsTableViewArray objectAtIndex:indexPath.row]timestampDate]]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
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
