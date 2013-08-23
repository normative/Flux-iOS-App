//
//  FluxHashtagTableViewCell.h
//  Flux
//
//  Created by Kei Turner on 2013-08-22.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FluxHashtagTableViewCell : UITableViewCell<UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UITextView *hashTextView;

@end
