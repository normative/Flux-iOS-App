//
//  FluxAnnotationsTableViewController.h
//  Flux
//
//  Created by Kei Turner on 2013-08-12.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FluxAnnotationsTableViewController : UITableViewController{
    
}
@property (nonatomic, strong)NSArray*annotationsTableViewArray;

- (void)setTableViewArray:(NSArray*)array;

@end
