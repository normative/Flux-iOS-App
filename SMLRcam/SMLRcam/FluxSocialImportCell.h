//
//  FluxSocialImportCell.h
//  Flux
//
//  Created by Kei Turner on 2/19/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface FluxSocialImportCell : UITableViewCell{

}

@property (nonatomic, strong) IBOutlet UILabel *headerLabel;
@property (nonatomic, strong) IBOutlet UIImageView *serviceImageView;


-(void)initCell;
- (void)setTheTitle:(NSString*)title;

@end
