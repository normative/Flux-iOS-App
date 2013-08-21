//
//  FluxClockSlidingControl.h
//  Flux
//
//  Created by Kei Turner on 2013-08-21.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FluxClockSlidingControl : UIView{
    
}
@property (nonatomic, strong)UILabel*timeLabel;
@property (nonatomic, strong)UIImageView*minuteHandView;
@property (nonatomic, strong)UIImageView*hourHandView;
@property (nonatomic)float startingYCoord;

- (void)changeTimeString:(NSString*)string adding:(BOOL)add;

@end
