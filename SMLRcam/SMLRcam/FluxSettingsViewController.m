//
//  FluxLeftDrawerSettingsViewController.m
//  Flux
//
//  Created by Jacky So on 25/10/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxSettingsViewController.h"

@interface FluxSettingsViewController ()

@end

@implementation FluxSettingsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated{
//    [super viewWillAppear:animated];
//    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 400, 44)];
//    label.backgroundColor = [UIColor clearColor];
//    [label setFont:[UIFont fontWithName:@"Akkurat-Bold" size:17.0]];
//    label.textAlignment = UITextAlignmentCenter;
//    label.textColor = [UIColor whiteColor];
//    label.adjustsFontSizeToFitWidth = YES;
//    label.text = self.title;
//    self.navigationItem.titleView = label;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setTitle:@"Settings"];

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
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryNone;

    switch (indexPath.row)
    {
        case 0:
            self.saveLocallySwitch.on = [[defaults objectForKey:@"Save Pictures"] boolValue];
            break;
        case 1:
            break;
        case 2:
            self.connectServerSegmentedControl.selectedSegmentIndex = [[defaults objectForKey:@"Server Location"] intValue];
            break;
    }
    return cell;
}


- (IBAction)changeSaveLocallySwitch:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:self.saveLocallySwitch.on]
                 forKey:@"Save Pictures"];
    [defaults synchronize];
}

- (IBAction)changeConnectServerSegment:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithInt:self.connectServerSegmentedControl.selectedSegmentIndex] forKey:@"Server Location"];
    [defaults synchronize];
}

- (IBAction)onAreaResetBtn:(id)sender
{
    [self.fluxDataManager deleteLocations];
}

@end
