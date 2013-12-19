//
//  FluxEditProfileViewController.h
//  Flux
//
//  Created by Kei Turner on 11/29/2013.
//  Copyright (c) 2013 Normative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FluxUserObject.h"
#import "FluxDataManager.h"

@interface FluxEditProfileViewController : UITableViewController<UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>{
    FluxUserObject*userObject;
    NSMutableDictionary*editedDictionary;
}
@property (nonatomic, strong) FluxDataManager *fluxDataManager;

- (void)prepareViewWithUser:(FluxUserObject*)theUserObject;
- (IBAction)editProfilePictureCell:(id)sender;
- (IBAction)saveButtonAction:(id)sender;

@end
