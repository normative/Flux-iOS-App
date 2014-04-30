//
//  FluxEditCaptionViewController.m
//  Flux
//
//  Created by Kei Turner on 2014-04-30.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxEditCaptionViewController.h"

#define IS_4INCHSCREEN  ([[UIScreen mainScreen] bounds].size.height == 568)?TRUE:FALSE

@interface FluxEditCaptionViewController ()

@end

@implementation FluxEditCaptionViewController

@synthesize delegate;

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
    
    if (IS_4INCHSCREEN) {
        imageSize = 150;
    }
    else{
        imageSize = 70;
    }
    
    [self.captionTextView setFont:[UIFont fontWithName:@"Akkurat" size:self.captionTextView.font.pointSize]];
    [self.captionTextView setTheDelegate:self];
    
    CALayer *roundBorderLayer = [CALayer layer];
    roundBorderLayer.borderWidth = 0.5;
    roundBorderLayer.opacity = 0.4;
    roundBorderLayer.cornerRadius = 5;
    roundBorderLayer.borderColor = [UIColor whiteColor].CGColor;
    roundBorderLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.captionTextView.frame), CGRectGetHeight(self.captionTextView.frame));
    [self.captionTextView.layer addSublayer:roundBorderLayer];
    

    
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidLayoutSubviews{
    CGPoint center = self.underlyingImageView.center;
    [self.underlyingImageView setFrame:CGRectMake(0, 0, self.underlyingImageView.frame.size.height, self.underlyingImageView.frame.size.height)];
    [self.underlyingImageView setCenter:center];
    finalTextFrame= self.captionTextView.frame;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)animateFromTextFrame:(CGRect)textFrame withCaption:(NSString*)caption andImageFrame:(CGRect)imageFrame andUnderlyingImage:(UIImage*)image{
    [self.underlyingImageView setFrame:imageFrame];
    
    existingString = caption;
    
    //    [captionTextField setFrame:textFrame];
    [self.captionTextView setText:caption];
    [self.captionTextView becomeFirstResponder];
    
    [self.captionTextView setCenter:CGPointMake(self.captionTextView.center.x, self.captionTextView.center.y+200)];
    if (image) {
        [self.underlyingImageView setImage:image];
    }
    
    
    [UIView animateWithDuration:0.3 animations:^{
        [self.underlyingImageView setFrame:CGRectMake(self.view.center.x-(imageSize/2), 80, imageSize, imageSize)];
        [self.captionTextView setFrame:finalTextFrame];
    }completion:^(BOOL finished){
        tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapGestureAction:)];
        [self.view addGestureRecognizer:tapGesture];
    }];
    [self.doneButton setEnabled:NO];
    [self.doneButton setTintColor:[UIColor colorWithWhite:1.0 alpha:0.8]];
    
    [self.view layoutSubviews];
}

- (void)fadeToSourceRect{
    [self.captionTextView resignFirstResponder];
    [UIView animateWithDuration:0.3 animations:^{
        [self.captionTextView setFrame:finalTextFrame];
        [self.captionTextView setCenter:CGPointMake(self.captionTextView.center.x, self.captionTextView.center.y+200)];
    }completion:^(BOOL finished){
        
    }];
}


- (void)tapGestureAction:(UITapGestureRecognizer*)theTapGesture{
    CGPoint location = [theTapGesture locationInView:self.view];
    if (!CGRectContainsPoint(self.captionTextView.frame, location) && !CGRectContainsPoint(self.underlyingImageView.frame, location)){
        [self clearView];
    }
    
}

- (void)clearView{
    [self fadeToSourceRect];
    if ([delegate respondsToSelector:@selector(EditCaptionViewDidClear:)]) {
        [delegate EditCaptionViewDidClear:self];
    }
}

- (IBAction)doneButtonAction:(id)sender {
    if (![existingString isEqualToString:self.captionTextView.text]) {
        if ([delegate respondsToSelector:@selector(EditCaptionView:shouldEditCaption:)]) {
            [delegate EditCaptionView:self shouldEditCaption:self.captionTextView.text];
        }
    }
    [self clearView];
}

- (IBAction)cancelButtonAction:(id)sender {
    [self clearView];
}

- (void)PlaceholderTextViewDidEdit:(KTPlaceholderTextView *)placeholderTextView{
    if (![existingString isEqualToString:placeholderTextView.text]){
        [self.doneButton setEnabled:YES];
        [self.doneButton setTintColor:[UIColor colorWithWhite:1.0 alpha:1.0]];
    }
    else{
        [self.doneButton setEnabled:NO];
        [self.doneButton setTintColor:[UIColor colorWithWhite:1.0 alpha:0.8]];
    }
}
@end
