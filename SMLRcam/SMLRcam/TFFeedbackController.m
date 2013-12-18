//
//  TFFeedbackController.m
//  TestFlightFeedbackExample
//
//  Created by Denis Zamataev on 8/27/13.
//
//

#import "TFFeedbackController.h"
#import "UICKeyChainStore.h"
#import <sys/utsname.h>



@interface TFFeedbackController ()

@end

@implementation TFFeedbackController

+ (NSString*)nibFileName
{
    return [NSString stringWithFormat:@"%@%@", @"TFFeedbackController", TFFeedback_INTERFACE_IDIOM_SPECIFIC_ENDING];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [_textView becomeFirstResponder];
    _textViewBottomSpacingConstraintOriginalValue = _textViewBottomSpacingConstraint.constant;
    [self changeTextViewBottomSpacingConstraintToSupportInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)cancel:(id)sender
{
    [self dismiss];
}


- (IBAction)submit:(id)sender
{
    NSString *username = [UICKeyChainStore stringForKey:FluxUsernameKey service:FluxService];
    NSString *userID = [UICKeyChainStore stringForKey:FluxUserIDKey service:FluxService];
    NSString *feedbackText;
    
    if (userID && username) {
        feedbackText = [NSString stringWithFormat:@"%@ -(%@), %@: %@",username,userID,[self deviceName],_textView.text];
    }
    else{
        feedbackText = _textView.text;
    }
    [TestFlight submitFeedback:feedbackText];
    [self dismiss];
}

- (NSString*)deviceName
{
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}

- (void)dismiss
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self changeTextViewBottomSpacingConstraintToSupportInterfaceOrientation:toInterfaceOrientation];
}

- (void)changeTextViewBottomSpacingConstraintToSupportInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        _textViewBottomSpacingConstraint.constant = TFFeedback_INTERFACE_IDIOM_SPECIFIC_TEXT_FIELD_BOTTOM_SPACING_FOR_LANDSCAPE_ORIENTATION;
    }
    else {
        _textViewBottomSpacingConstraint.constant = _textViewBottomSpacingConstraintOriginalValue;
    }
    [self.view layoutIfNeeded];
}
@end
