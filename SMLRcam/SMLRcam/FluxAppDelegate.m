//
//  SMLRcamAppDelegate.m
//  SMLRcam
//
//  Created by Kei Turner on 7/4/13.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxAppDelegate.h"

#import "MMDrawerController.h"
#import "FluxLeftDrawerViewController.h"
#import "FluxRightDrawerViewController.h"
#import "FluxScanViewController.h"
#import "FluxDataManager.h"

#import <Security/Security.h>

#import "GAI.h"
#define GATrackingID @"UA-17713937-4"

#import "TestFlight.h"
#define TestFlightAppToken @"ef9c1a90-3dc3-4db5-8fad-867e31b66e8c"



@implementation FluxAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard"
                                                             bundle: nil];
    
    FluxDataManager*fluxDataManager = [[FluxDataManager alloc] init];
    
    
    FluxLeftDrawerViewController * leftSideDrawerViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"FluxLeftDrawerViewController"];
    FluxRightDrawerViewController * rightSideDrawerViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"FluxRightDrawerViewController"];
    
    FluxScanViewController * scanViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"FluxScanViewController"];
    
    rightSideDrawerViewController.fluxDataManager = fluxDataManager;
    scanViewController.fluxDataManager = fluxDataManager;
    
    MMDrawerController * drawerController = [[MMDrawerController alloc] initWithCenterViewController:scanViewController  leftDrawerViewController:leftSideDrawerViewController rightDrawerViewController:rightSideDrawerViewController];
    
    [drawerController setMaximumLeftDrawerWidth:256.0];
    [drawerController setMaximumRightDrawerWidth:256.0];
    [drawerController setOpenDrawerGestureModeMask:MMOpenDrawerGestureModeNone];
    
    //sets the custom gesture handler to the left drawer button. In order to do both buttons, you have to set it to open under 1 view.
    //possible ways to accomplish: have a view the size of the screen bounds, set the gesture handler here to those touch points. Then in that view's class, override the - (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event method (maybe), or have the entire bottom of the scan view be this fake view.
//    [drawerController setGestureShouldRecognizeTouchBlock:^BOOL(MMDrawerController *drawerController, UIGestureRecognizer *gesture, UITouch *touch) {
//         BOOL shouldRecognizeTouch = NO;
//         if(drawerController.openSide == MMDrawerSideNone &&
//            [gesture isKindOfClass:[UIPanGestureRecognizer class]]){
//             UIView * customView = scanViewController.view;
//             customView.frame = CGRectMake(0, scanViewController., scanViewController.view.frame.size.width, <#CGFloat height#>) scanViewController.view.frame.origin;
//             CGPoint location = [touch locationInView:customView];
//             shouldRecognizeTouch = (CGRectContainsPoint(customView.bounds, location));
//         }
//         return shouldRecognizeTouch;
//     }];
    
    
    [drawerController setCloseDrawerGestureModeMask:MMCloseDrawerGestureModeAll];
    
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
    
    
    //google analytics
    // Optional: automatically send uncaught exceptions to Google Analytics.
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    // Optional: set Google Analytics dispatch interval to e.g. 20 seconds.
    [GAI sharedInstance].dispatchInterval = 20;
    // Optional: set Logger to VERBOSE for debug information.
    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelVerbose];
    // Initialize tracker.
    id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:GATrackingID];
    
    //testFlight analytics
    [TestFlight takeOff:TestFlightAppToken];
    
    
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window setRootViewController:drawerController];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
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
