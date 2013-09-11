//
//  LOAAViewController.m
//  LocationOrientationAcquisitionApp
//
//  Created by Ryan Martens on 9/11/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "LOAAViewController.h"

@interface LOAAViewController ()

@end

@implementation LOAAViewController

#pragma mark - View

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self setupLogging];
    [self setupLocationManager];
    [self setupMotionManager];
    
    Annotation.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [Annotation resignFirstResponder];
    
    return YES;
}

#pragma mark - Location

- (void) setupLocationManager
{
    if (locationManager != nil)
    {
        return;
    }
    
    locationManager = [[CLLocationManager alloc] init];
    
    if (locationManager != nil)
    {
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        locationManager.distanceFilter = kCLDistanceFilterNone;
        locationManager.pausesLocationUpdatesAutomatically = NO;
        [locationManager startUpdatingLocation];
        
        if ([CLLocationManager headingAvailable])
        {
            locationManager.headingFilter = 5;
            [locationManager startUpdatingHeading];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)newLocations
{
    // Grab last entry for now, since we should be getting all of them
    if ([newLocations count] > 1)
    {
        NSLog(@"Received more than one location (%d)", [newLocations count]);
    }
    
    CLLocation *newLocation = [newLocations lastObject];
    
    // test that the horizontal accuracy does not indicate an invalid measurement
    if (newLocation.horizontalAccuracy < 0)
    {
        NSLog(@"Invalid measurement (horizontalAccuracy=%f)",newLocation.horizontalAccuracy);
        return;
    }
    
    // test that the vertical accuracy does not indicate an invalid measurement
    if (newLocation.verticalAccuracy < 0)
    {
        NSLog(@"Invalid measurement (verticalAccuracy=%f)",newLocation.verticalAccuracy);
        return;
    }
    
    // test the age of the location measurement to determine if the measurement is cached
    // in most cases you will not want to rely on cached measurements
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge > 5.0)
    {
        NSLog(@"location age too old (%f)",locationAge);
        return;
    }
    
    [Latitude setText:[NSString stringWithFormat:@"%f", newLocation.coordinate.latitude]];
    [Longitude setText:[NSString stringWithFormat:@"%f", newLocation.coordinate.longitude]];
    [Altitude setText:[NSString stringWithFormat:@"%f", newLocation.altitude]];
    [HorizontalAcc setText:[NSString stringWithFormat:@"%f", newLocation.horizontalAccuracy]];
    [VerticalAcc setText:[NSString stringWithFormat:@"%f", newLocation.verticalAccuracy]];
    [Course setText:[NSString stringWithFormat:@"%f", newLocation.course]];
    [Speed setText:[NSString stringWithFormat:@"%f", newLocation.speed]];
    
    CLHeading *heading = [locationManager heading];
    [HeadingAcc setText:[NSString stringWithFormat:@"%f", heading.headingAccuracy]];
    
    CLLocationDirection direction = -1;
    
    if (heading.headingAccuracy >= 0)
    {
        // Use the true heading if it is valid.
        direction = ((heading.trueHeading >= 0) ? heading.trueHeading : heading.magneticHeading);
        
        [Heading setText:[NSString stringWithFormat:@"%f", direction]];
    }
    else
    {
        [Heading setText:@"-"];
    }
    
    // Output to log file
    NSString *logStr = [NSString stringWithFormat:@"%f, %f, %f, %f, %f, %f, %f, %f, %f\n",
                        newLocation.coordinate.latitude,
                        newLocation.coordinate.longitude,
                        newLocation.altitude,
                        newLocation.horizontalAccuracy,
                        newLocation.verticalAccuracy,
                        newLocation.course,
                        newLocation.speed,
                        direction,
                        heading.headingAccuracy];
    [self writeLocationLog:logStr];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)heading
{
    [HeadingAcc setText:[NSString stringWithFormat:@"%f", heading.headingAccuracy]];
    
    if (heading.headingAccuracy >= 0)
    {
        // Use the true heading if it is valid.
        CLLocationDirection direction = ((heading.trueHeading >= 0) ? heading.trueHeading : heading.magneticHeading);
        
        [Heading setText:[NSString stringWithFormat:@"%f", direction]];
    }
    else
    {
        [Heading setText:@"-"];
    }
}

#pragma mark - Motion

- (void) setupMotionManager
{
    if (motionManager != nil)
    {
        return;
    }
    
    motionManager = [[CMMotionManager alloc] init];
    
    if (motionManager != nil)
    {
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0;
        motionManager.showsDeviceMovementDisplay = YES;
        
        [motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXTrueNorthZVertical];
        motionUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1/60.0 target:self selector:@selector(UpdateDeviceMotion:) userInfo:nil repeats:YES];
    }
}

- (void)UpdateDeviceMotion:(NSTimer*)timer{
    CMAttitude *attitude = [[CMAttitude alloc] init];
    if ((motionManager) && ([motionManager isDeviceMotionActive]))
    {
        attitude = motionManager.deviceMotion.attitude;
        [Pitch setText:[NSString stringWithFormat:@"%f", attitude.pitch]];
        [Yaw setText:[NSString stringWithFormat:@"%f", attitude.yaw]];
        [Roll setText:[NSString stringWithFormat:@"%f", attitude.roll]];
    }
    else
    {
        [Pitch setText:@"-"];
        [Yaw setText:@"-"];
        [Roll setText:@"-"];
    }
    
    NSString *logStr = [NSString stringWithFormat:@"%f, %f, %f\n",
                        attitude.pitch, attitude.yaw, attitude.roll];
    [self writeMotionLog:logStr];
}

#pragma mark - Logging

- (void) setupLogging
{
    dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy'-'MM'-'dd', 'HH':'mm':'ss'.'SSS', '"];

    locationFileLock = [[NSLock alloc] init];
    motionFileLock = [[NSLock alloc] init];
    
    [self createNewLogFiles];
}

- (void) createNewLogFiles
{
    NSDateFormatter *fileDateFormat = [[NSDateFormatter alloc] init];
    [fileDateFormat setDateFormat:@"yyyy'-'MM'-'dd'_'HH':'mm':'ss"];
    
    NSDate *curDate = [NSDate date];
    NSString *curDateString = [fileDateFormat stringFromDate:curDate];
    
    NSString *locationName = [NSString stringWithFormat:@"Documents/%@_position.csv", curDateString];
    NSString *motionName = [NSString stringWithFormat:@"Documents/%@_orientation.csv", curDateString];
    
    [locationFileLock lock];

        locationFilename = [NSHomeDirectory() stringByAppendingPathComponent:locationName];
        [[NSFileManager defaultManager] createFileAtPath:locationFilename contents:nil attributes:nil];
        locationFile = [NSFileHandle fileHandleForWritingAtPath:locationFilename];

        NSString *locationFileHeader = @"Date, Time, Latitude, Longitude, Altitude, HorizAcc, VertAcc, Course, Speed, Heading, HeadingAcc\n";
        [locationFile writeData:[locationFileHeader dataUsingEncoding:NSUTF8StringEncoding]];

    [locationFileLock unlock];
    
    [motionFileLock lock];

        motionFilename = [NSHomeDirectory() stringByAppendingPathComponent:motionName];
        [[NSFileManager defaultManager] createFileAtPath:motionFilename contents:nil attributes:nil];
        motionFile = [NSFileHandle fileHandleForWritingAtPath:motionFilename];

        NSString *motionFileHeader = @"Date, Time, Pitch, Yaw, Roll\n";
        [motionFile writeData:[motionFileHeader dataUsingEncoding:NSUTF8StringEncoding]];

    [motionFileLock unlock];
}

- (void) writeLocationLog:(NSString *)logmsg
{
    if (locationFile == nil)
    {
        return;
    }
    
    NSDate *curDate = [NSDate date];
    NSString *curDateString = [dateFormat stringFromDate:curDate];
    
    NSString *outStr = [curDateString stringByAppendingString:logmsg];
    
    [locationFileLock lock];
    
    [locationFile writeData:[outStr dataUsingEncoding:NSUTF8StringEncoding]];
    
    [locationFileLock unlock];
}

- (void) writeMotionLog:(NSString *)logmsg
{
    if (motionFile == nil)
    {
        return;
    }
    
    NSDate *curDate = [NSDate date];
    NSString *curDateString = [dateFormat stringFromDate:curDate];
   
    NSString *outStr = [curDateString stringByAppendingString:logmsg];

    [motionFileLock lock];
    
    [motionFile writeData:[outStr dataUsingEncoding:NSUTF8StringEncoding]];
    
    [motionFileLock unlock];
}

#pragma mark - Buttons

- (IBAction)StartNewButton:(id)sender
{
    [locationFileLock lock];
    
        [locationFile closeFile];
        locationFile = nil;
   
    [locationFileLock unlock];
    
    [motionFileLock lock];

        [motionFile closeFile];
        motionFile = nil;
    
    [motionFileLock unlock];
    
    [self createNewLogFiles];
}

- (IBAction)ClearOldButton:(id)sender
{
    [locationFileLock lock];
    [motionFileLock lock];
    
    [locationFile closeFile];
    [motionFile closeFile];
    locationFile = nil;
    motionFile = nil;
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *directory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/"];
    NSError *error = nil;
    for (NSString *file in [fm contentsOfDirectoryAtPath:directory error:&error]) {
        BOOL success = [fm removeItemAtPath:[directory stringByAppendingPathComponent:file] error:&error];
        if (!success || error) {
            // it failed.
            NSLog(@"Error deleting files.");
        }
    }
    
    [locationFileLock unlock];
    [motionFileLock unlock];
    
    [self createNewLogFiles];
}

- (IBAction)AnnotateButton:(id)sender
{
    NSDate *curDate = [NSDate date];
    NSString *curDateString = [dateFormat stringFromDate:curDate];

    NSString *outStr = [NSString stringWithFormat:@"# %@ %@\n", curDateString, [Annotation text]];

    if (locationFile != nil)
    {
        [locationFileLock lock];
        
        [locationFile writeData:[outStr dataUsingEncoding:NSUTF8StringEncoding]];
        
        [locationFileLock unlock];

    }
    
    if (locationFile != nil)
    {
        [motionFileLock lock];

        [motionFile writeData:[outStr dataUsingEncoding:NSUTF8StringEncoding]];
        
        [motionFileLock unlock];
    }
    
    [Annotation setText:@""];
}

@end
