//
//  FluxSearchCell.h
//  Flux
//
//  Created by Kei Turner on 2014-02-27.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FluxSearchCell;
@protocol FluxSearchCellDelegate <NSObject>
@optional
- (void)SearchCell:(FluxSearchCell *)searchCell didType:(NSString*)query;
@end


@interface FluxSearchCell : UITableViewCell <UISearchBarDelegate>{
    
    id __unsafe_unretained delegate;
}
@property (unsafe_unretained) id <FluxSearchCellDelegate> delegate;
@property (strong, nonatomic) IBOutlet UISearchBar *theSearchBar;


@end
