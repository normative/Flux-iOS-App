//
//  FluxRoundImagePickerController.m
//  Flux
//
//  Created by Kei Turner on 12/19/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxRoundImagePickerController.h"

@interface FluxRoundImagePickerController ()

@end

@implementation FluxRoundImagePickerController

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
    
    int radius = self.view.frame.size.width/2;
    CGRect circleRect = CGRectMake(0,(self.view.frame.size.height)-self.view.frame.size.width/2, self.view.bounds.size.width, self.view.bounds.size.height);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:circleRect cornerRadius:0];
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 2.0*radius, 2.0*radius) cornerRadius:radius];
    [path appendPath:circlePath];
    [path setUsesEvenOddFillRule:YES];
    
    CAShapeLayer *fillLayer = [CAShapeLayer layer];
    fillLayer.path = path.CGPath;
    fillLayer.fillRule = kCAFillRuleEvenOdd;
    fillLayer.fillColor = [UIColor blackColor].CGColor;
    fillLayer.opacity = 0.5;
    [self.view.layer addSublayer:fillLayer];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
