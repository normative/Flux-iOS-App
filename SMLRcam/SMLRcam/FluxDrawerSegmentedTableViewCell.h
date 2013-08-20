//
//  FluxDrawerSegmentedTableViewCell.h
//  Flux
//
//  Created by Kei Turner on 2013-08-20.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>


@class FluxDrawerSegmentedTableViewCell;
@protocol SegmentedCellDelegate <NSObject>
@optional
//images
- (void)SegmentedCell:(FluxDrawerSegmentedTableViewCell *)segmentedCell segmentedControlWasTapped:(UISegmentedControl*)segmented;
@end

@interface FluxDrawerSegmentedTableViewCell : UITableViewCell{
    
    __weak id <SegmentedCellDelegate> delegate;
}
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, weak) id <SegmentedCellDelegate> delegate;

- (IBAction)segmentedChanged:(id)sender;
@end
