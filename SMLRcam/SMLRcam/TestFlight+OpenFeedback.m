//
//  TestFlight+OpenFeedback.m
//  TestFlightFeedbackExample
//
//  Created by Denis Zamataev on 8/28/13.
//
//

#import "TestFlight+OpenFeedback.h"

@implementation TestFlight (OpenFeedback)

+ (void)openFeedbackViewFromView:(UIViewController *)presentingVC {
    TFFeedbackController *feedbackController = [[TFFeedbackController alloc] initWithNibName:[TFFeedbackController nibFileName]
                                                                                      bundle:nil];
    
    [presentingVC presentViewController:feedbackController animated:YES completion:^{
        
    }];
}

@end
