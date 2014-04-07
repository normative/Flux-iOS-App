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
    
    self.textEditor.text = self.annotationText;
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
        NSDictionary *annotationDict = @{FluxFlickrEditDescriptionAnnotationKey : self.textEditor.text};
        [self.delegate FluxFlickrEditDescriptionViewController:self didFinishEditingDescriptionWithInfo:annotationDict];
    }
}

@end
