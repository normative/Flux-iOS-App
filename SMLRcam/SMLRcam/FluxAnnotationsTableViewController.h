//
//  FluxAnnotationsTableViewController.h
//  Flux
//
//  Created by Kei Turner on 2013-08-12.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FluxNetworkServices.h"

@interface FluxAnnotationsTableViewController : UITableViewController<NetworkServicesDelegate>{
    FluxNetworkServices *networkServices;
}
@property (nonatomic, strong)NSMutableDictionary*tableViewdict;

- (void)setTableViewDictionary:(NSMutableDictionary*)imageDict;

@end
