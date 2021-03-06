//
//  FluxDebugViewController.h
//  Flux
//
//  Created by Kei Turner on 1/30/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>

extern NSString* const FluxDebugDidChangeMatchDebugImageOutput;
extern NSString* const FluxDebugMatchDebugImageOutputKey;
extern NSString* const FluxDebugDidChangeTeleportLocationIndex;
extern NSString* const FluxDebugTeleportLocationIndexKey;
extern NSString* const FluxDebugDidChangePedometerCountDisplay;
extern NSString* const FluxDebugPedometerCountDisplayKey;
extern NSString* const FluxDebugDidChangeHistoricalPhotoPicker;
extern NSString* const FluxDebugHistoricalPhotoPickerKey;
extern NSString* const FluxDebugDidChangeHeadingCorrectedMotion;
extern NSString* const FluxDebugHeadingCorrectedMotionKey;
extern NSString* const FluxDebugDidChangeDetailLoggerEnabled;
extern NSString* const FluxDebugDetailLoggerEnabledKey;

@interface FluxDebugViewController : UIViewController <MFMailComposeViewControllerDelegate>
{
    IBOutlet UISlider *slider1;
    IBOutlet UISegmentedControl *segmentedControl1;
    IBOutlet UISegmentedControl *segmentedControl2;
    IBOutlet UISegmentedControl *segmentedControl3;
    
    IBOutlet UISwitch *switch1;
    IBOutlet UISwitch *switch2;
    IBOutlet UISwitch *switch3;
    IBOutlet UISwitch *switch4;
    IBOutlet UIButton *detailLoggerButtonLabel;
}

- (IBAction)slider1DidSlide:(id)sender;
- (IBAction)segmentedControl1DidChange:(id)sender;
- (IBAction)segmentedControl2DidChange:(id)sender;
- (IBAction)segmentedControl3DidChange:(id)sender;

- (IBAction)switch1DidChange:(id)sender;
- (IBAction)switch2DidChange:(id)sender;
- (IBAction)switch3DidChange:(id)sender;
- (IBAction)switch4DidChange:(id)sender;
- (IBAction)deleteAccountButtonAction:(id)sender;
- (IBAction)detailLoggerButtonAction:(id)sender;

- (IBAction)hideMenuAction:(id)sender;

@end
