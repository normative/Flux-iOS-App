//
//  FluxFilterCountTableViewCell.h
//  Flux
//
//  Created by Kei Turner on 2014-03-19.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FluxFilterCountTableViewCell;
@protocol FluxFilterCountTableViewCellDelegate <NSObject>
@optional
- (void)FilterCountTableViewCellButtonWasTapped:(FluxFilterCountTableViewCell *)countCell;
@end

@interface FluxFilterCountTableViewCell : UITableViewCell{
    
    id __unsafe_unretained delegate;
}

@property (unsafe_unretained) id <FluxFilterCountTableViewCellDelegate> delegate;
@property (strong, nonatomic) IBOutlet UILabel *descriptonLabel;
@property (strong, nonatomic) IBOutlet UILabel *countLabel;
@property (strong, nonatomic) IBOutlet UIView *activityIndicatorContainerView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property (strong, nonatomic) IBOutlet UIButton *hiddenButton;

- (IBAction)hiddenButtonAciton:(id)sender;
- (void)initCell;

-(void)startAnimating;
-(void)stopAnimating;
-(void)setCount:(int)count;

@end
