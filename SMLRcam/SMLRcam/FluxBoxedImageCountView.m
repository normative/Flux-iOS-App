//
//  FluxBoxedImageCountView.m
//  Flux
//
//  Created by Kei Turner on 2/3/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxBoxedImageCountView.h"
#import "FluxImageCaptureBoxItem.h"

@implementation FluxBoxedImageCountView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setBackgroundColor:[UIColor clearColor]];
        
        float xSpace = 0;
        self.markCount = 0;
        self.centeredWidth = 0;
        boxesArray = [[NSMutableArray alloc]init];
        
        for (int i = 0; i< 4; i++) {
            UIView*whiteBoxView = [[UIView alloc]initWithFrame:CGRectMake(xSpace, 0, 5, 5)];
            [whiteBoxView setBackgroundColor:[UIColor whiteColor]];
            [whiteBoxView setAlpha:0.0];
            
            UIView*fadedBoxView = [[UIView alloc]initWithFrame:CGRectMake(xSpace, 0, 5, 5)];
            [fadedBoxView setBackgroundColor:[UIColor whiteColor]];
            [fadedBoxView setAlpha:0.1];
            
            [fadedBoxView setHidden:YES];
            
////            whiteBoxView.layer.cornerRadius = fadedBoxView.layer.cornerRadius = 1.5;
//            whiteBoxView.layer.masksToBounds = fadedBoxView.layer.masksToBounds = YES;
            
            FluxImageCaptureBoxItem*box = [[FluxImageCaptureBoxItem alloc]init];
            [box setWhiteBox:whiteBoxView];
            [box setFadedBox:fadedBoxView];
            [box setIsMarked:NO];
            [boxesArray addObject:box];
            
            xSpace += 8;

        }
        self.centeredWidth = xSpace+8;
        for (FluxImageCaptureBoxItem* box in boxesArray){
            [self addSubview:box.fadedBox];
            [self addSubview:box.whiteBox];
        }
    }
    return self;
}

//find the first square that isn't marked and mark it
- (void)addImageCapture{
    self.markCount ++;
    NSArray*boxes = [boxesArray copy];
    for (int i = 0; i<boxes.count; i++) {
        if (![(FluxImageCaptureBoxItem*)[boxes objectAtIndex:i]isMarked]) {
            FluxImageCaptureBoxItem*box = (FluxImageCaptureBoxItem*)[boxesArray objectAtIndex:i];
            [UIView animateWithDuration:0.3 animations:^{
                [box.whiteBox setAlpha:1.0];
            }];
            [box setIsMarked:YES];
            return;
        }
    }
}

//find the last box that was marked and unmark it
- (void)removeImageCapture{
    self.markCount --;
    NSArray*boxes = [boxesArray copy];
    for (int i = boxes.count-1; i>=0; i--) {
        if ([(FluxImageCaptureBoxItem*)[boxes objectAtIndex:i]isMarked]) {
            FluxImageCaptureBoxItem*box = (FluxImageCaptureBoxItem*)[boxesArray objectAtIndex:i];
            [UIView animateWithDuration:0.3 animations:^{
                [box.whiteBox setAlpha:0.0];
            }];
            [box setIsMarked:NO];
            return;
        }
    }
}

- (void)restoreAllBoxes{
    self.markCount = 0;
    NSArray*boxes = [boxesArray copy];
    for (int i = 0; i<boxes.count; i++) {
        FluxImageCaptureBoxItem*box = (FluxImageCaptureBoxItem*)[boxesArray objectAtIndex:i];
        [box.whiteBox setAlpha:0.0];
        [box setIsMarked:NO];
    }
}

@end
