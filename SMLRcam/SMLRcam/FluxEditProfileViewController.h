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
#import "FluxProfileCell.h"

@interface FluxEditProfileViewController : UIViewController<UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, KTPlaceholderTextViewDelegate, UITextFieldDelegate>{
    FluxUserObject*userObject;
    NSMutableDictionary*editedDictionary;
    IBOutlet UIButton *profileImageButton;
    IBOutlet UILabel *usernameLabel;
    IBOutlet KTPlaceholderTextView *bioTextField;
}
@property (nonatomic, strong) FluxDataManager *fluxDataManager;

- (void)prepareViewWithUser:(FluxUserObject*)theUserObject;
- (IBAction)editProfilePictureCell:(id)sender;
- (IBAction)saveButtonAction:(id)sender;

@end
