//
//  FluxTimeTickView.m
//  Flux
//
//  Created by Kei Turner on 2013-09-23.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import "FluxTimeTickView.h"

#import "FluxTimeTickButton.h"

@implementation FluxTimeTickView

#pragma mark - Init Methods

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame andTimeSegmentType:(timeSegment_type)timeType forDate:(NSDate *)date{
    self = [super initWithFrame:frame];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    headerDateFormatter = [[NSDateFormatter alloc]init];
    headerLabel = [[UILabel alloc]init];
    
    [self setBackgroundColor:[UIColor clearColor]];
    
    if (self)
    {
        switch (timeType) {
            case infinite:
            {
                [headerLabel setText:@"∞"];
            }
                break;
            case year:
            {
                [headerDateFormatter setDateFormat:@"yyyy"];
                [headerLabel setText:[headerDateFormatter stringFromDate:date]];
                NSRange numOfMonths = [calendar rangeOfUnit:NSWeekCalendarUnit
                                                     inUnit:NSYearCalendarUnit
                                                    forDate:date];
                timeTicksArray = [[NSMutableArray alloc]initWithCapacity:numOfMonths.length];
            }
                break;
            case month:
            {
                [headerDateFormatter setDateFormat:@"MMM, yyyy"];
                [headerLabel setText:[headerDateFormatter stringFromDate:date]];
                NSRange numOfWeeks = [calendar rangeOfUnit:NSWeekCalendarUnit
                                                    inUnit:NSMonthCalendarUnit
                                                   forDate:date];
                timeTicksArray = [[NSMutableArray alloc]initWithCapacity:numOfWeeks.length];
            }
                break;
            case week:
            {
                NSDateComponents *components = [calendar components:( NSWeekOfMonthCalendarUnit ) fromDate:date];
                NSLog(@"week of month: %ld", (long)[components weekOfMonth]);
                [headerDateFormatter setDateFormat:@"MMM dd, yyyy"];
                [headerLabel setText:[headerDateFormatter stringFromDate:date]];
                NSRange numOfDays = [calendar rangeOfUnit:NSDayCalendarUnit
                                                   inUnit:NSWeekCalendarUnit
                                                  forDate:date];
                timeTicksArray = [[NSMutableArray alloc]initWithCapacity:numOfDays.length];
            }
                break;
            case day:
            {
                [headerDateFormatter setDateFormat:@"MMM, dd"];
                [headerLabel setText:[headerDateFormatter stringFromDate:date]];
            }
            break;
            default:
                break;
        }
        [self populateViewForTimeSegmentType:timeType];
    }
    return self;
}

- (void)populateViewForTimeSegmentType:(timeSegment_type)timeType{
    switch (timeType) {
        case infinite:
            
        
        break;
            
        case year:
        case month:
        case week:
        {
            int yOffset = 10;
            for (int i = 0; i<timeTicksArray.count; i++) {
                FluxTimeTickButton*timeButton = [[FluxTimeTickButton alloc]initWithFrame:CGRectMake(5, yOffset+(yOffset*i), self.frame.size.width-5, 5)];
                [timeButton setBackgroundColor:[UIColor grayColor]];
                [timeButton addTarget:self action:@selector(timeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
                [self addSubview:timeButton];
                [timeTicksArray replaceObjectAtIndex:i withObject:timeButton];
            }
        }

            
            break;
            
        case day:
            
            
            break;
            
        default:
            break;
    }
}

- (void)timeButtonTapped:(id)sender{
    NSLog(@"Button Tapped");
}



@end
