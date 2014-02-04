//
//  SMLRcamAppDelegate.m
//  SMLRcam
//
//  Created by Kei Turner on 7/4/13.
//  Copyright (c) 2013 SMLR. All rights reserved.
//

#import "FluxAppDelegate.h"
#import <FacebookSDK/FacebookSDK.h>

#import "FluxDebugViewController.h"

#import "GAI.h"
#define GATrackingID @"UA-17713937-4"

#import "TestFlight.h"
// Normative
//#define TestFlightAppToken @"ef9c1a90-3dc3-4db5-8fad-867e31b66e8c"
// SMLR
#define TestFlightAppToken @"0eda8ac5-1a9d-460a-bdd4-872906086253"


@implementation FluxAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{

    
    //set settings defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber * savePic = [defaults objectForKey:@"Save Pictures"];
    NSNumber * isLocalURL = [defaults objectForKey:@"Server Location"];
    NSString * borderType = [defaults objectForKey:@"Border"];
    NSString * teleportIndex = [defaults objectForKey:FluxDebugTeleportLocationIndexKey];
    NSNumber * featureMatchDebugImageOutput = [defaults objectForKey:FluxDebugMatchDebugImageOutputKey];
    NSNumber * pedometerCountDisplay = [defaults objectForKey:FluxDebugPedometerCountDisplayKey];
    
    // do not save locally by default
    if (savePic == nil) {
        [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"Save Pictures"];
        [defaults synchronize];
    }
    //set local by default
    if (isLocalURL == nil) {
        [defaults setObject:[NSNumber numberWithInt:1] forKey:@"Server Location"];
        [defaults synchronize];
    }
    
    if (borderType == nil) {
        [defaults setObject:@"3" forKey:@"Border"];
        [defaults synchronize];
    }

    if (teleportIndex == nil) {
        [defaults setObject:@"1" forKey:FluxDebugTeleportLocationIndexKey];
        [defaults synchronize];
    }

    if (featureMatchDebugImageOutput == nil) {
        [defaults setObject:@(NO) forKey:FluxDebugMatchDebugImageOutputKey];
        [defaults synchronize];
    }

    if (pedometerCountDisplay == nil) {
        [defaults setObject:@(NO) forKey:FluxDebugPedometerCountDisplayKey];
        [defaults synchronize];
    }

    [[UINavigationBar appearance] setTitleTextAttributes:@{
                                                           NSFontAttributeName: [UIFont fontWithName:@"Akkurat-Bold" size:17.0],
                                                           NSForegroundColorAttributeName: [UIColor whiteColor],
                                                           }];
    
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{
                                                           NSFontAttributeName: [UIFont fontWithName:@"Akkurat" size:17.0],
                                                           NSForegroundColorAttributeName: [UIColor whiteColor],
                                                           } forState:UIControlStateNormal];
    
    [[UINavigationBar appearance]setBarTintColor:[UIColor colorWithRed:234/255.0 green:63/255.0 blue:63/255.0 alpha:1.0]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    
    if ([UITextField conformsToProtocol:@protocol(UIAppearance)])
    {
        [[UITextField appearance] setTintColor:[UIColor whiteColor]];
    }
    
    if ([UIButton conformsToProtocol:@protocol(UIAppearance)])
    {
        [[UIButton appearance].titleLabel setFont:[UIFont fontWithName:@"Akkurat" size:17.0]];
    }
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    
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
    
    RKLogConfigureByName("RestKit/Network", RKLogLevelCritical);
    //RKLogConfigureByName("RestKit/Network", RKLogLevelTrace);
    //RKLogConfigureByName("*", RKLogLevelOff);
    
    return YES;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    // attempt to extract a token from the url
    return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication fallbackHandler:^(FBAppCall *call) {
        if([[call appLinkData] targetURL] != nil) {
            // get the object ID string from the deep link URL
            // we use the substringFromIndex so that we can delete the leading '/' from the targetURL
            NSString *objectId = [[[call appLinkData] targetURL].path substringFromIndex:1];
            
            // now handle the deep link
            // write whatever code you need to show a view controller that displays the object, etc.
            [[[UIAlertView alloc] initWithTitle:@"Directed from Facebook"
                                        message:[NSString stringWithFormat:@"Deep link to %@", objectId]
                                       delegate:self
                              cancelButtonTitle:@"OK!"
                              otherButtonTitles:nil] show];
        } else {
            //
            NSLog(@"Unhandled deep link: %@", [[call appLinkData] targetURL]);
        }
    }];
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
    [FBAppEvents activateApp];
    
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    
    // FBSample logic
    // We need to properly handle activation of the application with regards to SSO
    //  (e.g., returning from iOS 6.0 authorization dialog or from fast app switching).
    [FBAppCall handleDidBecomeActiveWithSession:FBSession.activeSession];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
