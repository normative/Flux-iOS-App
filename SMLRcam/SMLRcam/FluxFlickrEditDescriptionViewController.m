//
//  FluxFlickrEditDescriptionViewController.m
//  Flux
//
//  Created by Ryan Martens on 4/7/14.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxFlickrEditDescriptionViewController.h"

NSString* const FluxFlickrEditDescriptionAnnotationKey = @"FluxFlickrEditDescriptionAnnotationKey";

@interface FluxFlickrEditDescriptionViewController ()

@end

@implementation FluxFlickrEditDescriptionViewController

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
    // Do any additional setup after loading the view.
    
    [self.view setBackgroundColor:[UIColor grayColor]];
    
    [self.editAnnotationTextView setTheDelegate:self];
    [self.editAnnotationTextView becomeFirstResponder];
    
    [self.editAnnotationTextView setCountCharactersToZero:NO];
    [self.editAnnotationTextView setWarnCharCount:141];
    [self.editAnnotationTextView setMaxCharCount:1000];
    
    CALayer *roundBorderLayer = [CALayer layer];
    roundBorderLayer.borderWidth = 0.5;
    roundBorderLayer.opacity = 0.4;
    roundBorderLayer.cornerRadius = 5;
    roundBorderLayer.borderColor = [UIColor blackColor].CGColor;
    roundBorderLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.editAnnotationTextView.frame), CGRectGetHeight(self.editAnnotationTextView.frame));
    [self.editAnnotationTextView.layer addSublayer:roundBorderLayer];

    self.editAnnotationTextView.text = self.annotationText;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cancelButtonAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(FluxFlickrEditDescriptionViewControllerDidCancel:)])
    {
        [self.delegate FluxFlickrEditDescriptionViewControllerDidCancel:self];
    }
}

- (IBAction)selectButtonAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(FluxFlickrEditDescriptionViewController:didFinishEditingDescriptionWithInfo:)])
    {
        NSDictionary *annotationDict = @{FluxFlickrEditDescriptionAnnotationKey : self.editAnnotationTextView.text};
        [self.delegate FluxFlickrEditDescriptionViewController:self didFinishEditingDescriptionWithInfo:annotationDict];
    }
}

@end
