//
//  SMLRcamAppDelegate.m
//  SMLRcam
//
//  Created by Kei Turner on 7/4/13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxAppDelegate.h"

#import <Security/Security.h>

#import "GAI.h"
#define GATrackingID @"UA-17713937-4"

#import "TestFlight.h"
#define TestFlightAppToken @"ef9c1a90-3dc3-4db5-8fad-867e31b66e8c"



@implementation FluxAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{

    
    //set settings defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber * savePic = [defaults objectForKey:@"Save Pictures"];
    NSNumber * uploadPic = [defaults objectForKey:@"Network Services"];
    NSNumber * isLocalURL = [defaults objectForKey:@"Server Location"];
    NSNumber * isWalkMode = [defaults objectForKey:@"Walk Mode"];
    
    // do not save locally by default
    if (savePic == nil) {
        [defaults setObject:[NSNumber numberWithBool:NO] forKey:@"Save Pictures"];
        [defaults synchronize];
    }
    // upload by default
    if (uploadPic == nil) {
        [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"Network Services"];
        [defaults synchronize];
    }
    //set local by default
    if (isLocalURL == nil) {
        [defaults setObject:[NSNumber numberWithInt:1] forKey:@"Server Location"];
        [defaults synchronize];
    }
    
    if (isWalkMode == nil) {
        [defaults setObject:[NSNumber numberWithBool:NO] forKey:@"Walk Mode"];
        [defaults synchronize];
    }
    
    [[UINavigationBar appearance] setTitleTextAttributes:@{
                                                           UITextAttributeFont: [UIFont fontWithName:@"Akkurat" size:17.0],
                                                           }];
    
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{
                                                           UITextAttributeFont: [UIFont fontWithName:@"Akkurat" size:17.0],
                                                           } forState:UIControlStateNormal];
    
    //google analytics
    // Optional: automatically send uncaught exceptions to Google Analytics.
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    // Optional: set Google Analytics dispatch interval to e.g. 20 seconds.
    [GAI sharedInstance].dispatchInterval = 20;
    // Optional: set Logger to VERBOSE for debug information.
    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelNone];
    // Initialize tracker.
    [[GAI sharedInstance] trackerWithTrackingId:GATrackingID];
    
    //testFlight analytics
    [TestFlight takeOff:TestFlightAppToken];
    
    //RKLogConfigureByName("RestKit/Network", RKLogLevelCritical);
    RKLogConfigureByName("*", RKLogLevelOff);
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
