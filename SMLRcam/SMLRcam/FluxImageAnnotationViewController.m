//
//  FluxImageAnnotationViewController.m
//  Flux
//
//  Created by Kei Turner on 2013-10-03.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxImageAnnotationViewController.h"

@interface FluxImageAnnotationViewController ()

@end

@implementation FluxImageAnnotationViewController

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
    [ImageAnnotationTextView SetPlaceholderText:[NSString stringWithFormat:@"What do you see?"]];
    [ImageAnnotationTextView setTheDelegate:self];
    
    //segmented Control
    [categorySegmentedControl initWithImages:[NSArray arrayWithObjects:[UIImage imageNamed:@"btn-Annotation-person_selected"],[UIImage imageNamed:@"btn-Annotation-place_selected"],[UIImage imageNamed:@"btn-Annotation-thing_selected"],[UIImage imageNamed:@"btn-Annotation-event_selected"], nil] andStandardImages:[NSArray arrayWithObjects:[UIImage imageNamed:@"btn-Annotation-person_default"],[UIImage imageNamed:@"btn-Annotation-place_default"],[UIImage imageNamed:@"btn-Annotation-thing_default"],[UIImage imageNamed:@"btn-Annotation-event_default"], nil]];
    [categorySegmentedControl setDelegate:self];
    [categorySegmentedControl setSelectedSegmentIndex:0];
    
	// Do any additional setup after loading the view.
}

- (void)PlaceholderTextViewDidBeginEditing:(KTPlaceholderTextView *)placeholderTextView{
    [UIView animateWithDuration:0.2f
                     animations:^{
                         [photoAnnotationContainerView setFrame:CGRectMake(0, photoAnnotationContainerView.frame.origin.y-200, photoAnnotationContainerView.frame.size.width, photoAnnotationContainerView.frame.size.height)];
                     }];
}

- (void)SegmentedControlValueDidChange:(KTSegmentedButtonControl *)segmentedControl{
    //[capturedImageObject setCategoryID:(segmentedControl.selectedIndex + 1)];
}

- (IBAction)approveImageAction:(id)sender
{
    //[capturedImageObject setDescriptionString:ImageAnnotationTextView.text];
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
