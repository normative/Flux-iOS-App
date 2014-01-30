//
//  FluxDebugViewController.h
//  Flux
//
//  Created by Kei Turner on 1/30/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FluxDebugViewController : UIViewController{
    
    IBOutlet UISlider *slider1;
    IBOutlet UISlider *slider2;
    IBOutlet UISlider *slider3;
    IBOutlet UISegmentedControl *segmentedControl1;
    
    IBOutlet UISwitch *switch1;
    IBOutlet UISwitch *switch2;
    IBOutlet UISwitch *switch3;
    IBOutlet UIStepper *stepper1;
}
- (IBAction)slider1DidSlide:(id)sender;
- (IBAction)slider2DidSlide:(id)sender;
- (IBAction)slider3DidSlide:(id)sender;
- (IBAction)segmentedControl1DidChange:(id)sender;

- (IBAction)switch1DidChange:(id)sender;
- (IBAction)switch2DidChange:(id)sender;
- (IBAction)switch3DidChange:(id)sender;
- (IBAction)stepper1DidStep:(id)sender;

- (IBAction)hideMenuAction:(id)sender;

@end
