//
//  FluxTimeTickView.h
//  Flux
//
//  Created by Kei Turner on 2013-09-23.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FluxTimeSegment.h"


@interface FluxTimeTickView : UIView{
    NSMutableArray*timeTicksArray;
    UILabel *headerLabel;
    NSDateFormatter *headerDateFormatter;
}

-(id)initWithFrame:(CGRect)frame andTimeSegment:(FluxTimeSegment*)timeSegment forDate:(NSDate*)date;
- (void)populateViewForTimeSegmentType:(timeSegment_type)timeType;

- (void)timeButtonTapped:(id)sender;
@end
