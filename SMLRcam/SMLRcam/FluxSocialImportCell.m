//
//  FluxSocialImportCell.m
//  Flux
//
//  Created by Kei Turner on 2/19/2014.
//  Copyright (c) 2014 Normative. All rights reserved.
//

#import "FluxSocialImportCell.h"

#import <AddressBookUI/AddressBookUI.h>

@implementation FluxSocialImportCell


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)initCell{
    [self.headerLabel setFont:[UIFont fontWithName:@"Akkurat" size:self.headerLabel.font.pointSize]];
    
    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = [UIColor colorWithRed:43/255.0 green:52/255.0 blue:58/255.0 alpha:0.7];
    [self setSelectedBackgroundView:bgColorView];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setTheTitle:(NSString*)title{
    [self.headerLabel setText:title];
    if ([title isEqualToString:@"Twitter"]) {
        [self.serviceImageView setImage:[UIImage imageNamed:@"import_twitter"]];
    }
    else if ([title isEqualToString:@"Facebook"]){
        [self.serviceImageView setImage:[UIImage imageNamed:@"import_facebook"]];
    }
    else if ([title isEqualToString:@"Contacts"]){
        [self.serviceImageView setImage:[UIImage imageNamed:@"import_contact"]];
    }
    else{
        
    }
}

//
//
//    // Request authorization to Address Book
//    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
//    
//    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
//        ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
//            if (granted) {
//                [self collectContacts];
//                
//                // First time access has been granted
//            } else {
//                // User denied access
//                // Display an alert telling user the contact could not be added
//            }
//        });
//    }
//    else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
//        // The user has previously given access
//        [self collectContacts];
//    }
//    else {
//        // The user has previously denied access
//        // Send an alert telling user to change privacy setting in settings app
//    }
//
//-(void)collectContacts
//{
//    NSMutableDictionary *myAddressBook = [[NSMutableDictionary alloc] init];
//    ABAddressBookRef addressBook = ABAddressBookCreate();
//    CFArrayRef people  = ABAddressBookCopyArrayOfAllPeople(addressBook);
//    for(int i = 0;i<ABAddressBookGetPersonCount(addressBook);i++)
//    {
//        ABRecordRef ref = CFArrayGetValueAtIndex(people, i);
//        
//        // Get First name, Last name, Prefix, Suffix, Job title
//        NSString *firstName = (__bridge NSString *)ABRecordCopyValue(ref,kABPersonFirstNameProperty);
//        NSString *lastName = (__bridge NSString *)ABRecordCopyValue(ref,kABPersonLastNameProperty);
//        NSString *prefix = (__bridge NSString *)ABRecordCopyValue(ref,kABPersonPrefixProperty);
//        NSString *suffix = (__bridge NSString *)ABRecordCopyValue(ref,kABPersonSuffixProperty);
//        NSString *jobTitle = (__bridge NSString *)ABRecordCopyValue(ref,kABPersonJobTitleProperty);
//        
//        [myAddressBook setObject:firstName forKey:@"firstName"];
//        [myAddressBook setObject:lastName forKey:@"lastName"];
//        [myAddressBook setObject:prefix forKey:@"prefix"];
//        [myAddressBook setObject:suffix forKey:@"suffix"];
//        [myAddressBook setObject:jobTitle forKey:@"jobTitle"];
//        
//        NSMutableArray *arPhone = [[NSMutableArray alloc] init];
//        ABMultiValueRef phones = ABRecordCopyValue(ref, kABPersonPhoneProperty);
//        for(CFIndex j = 0; j < ABMultiValueGetCount(phones); j++)
//        {
//            CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(phones, j);
//            NSString *phoneLabel =(__bridge NSString*) ABAddressBookCopyLocalizedLabel (ABMultiValueCopyLabelAtIndex(phones, j));
//            NSString *phoneNumber = (__bridge NSString *)phoneNumberRef;
//            NSMutableDictionary *temp = [[NSMutableDictionary alloc] init];
//            [temp setObject:phoneNumber forKey:@"phoneNumber"];
//            [temp setObject:phoneLabel forKey:@"phoneNumber"];
//            [arPhone addObject:temp];
//        }
//        [myAddressBook setObject:arPhone forKey:@"Phone"];
//        
//        CFStringRef address;
//        CFStringRef label;
//        ABMutableMultiValueRef multi = ABRecordCopyValue(ref, kABPersonAddressProperty);
//        for (CFIndex i = 0; i < ABMultiValueGetCount(multi); i++)
//        {
//            label = ABMultiValueCopyLabelAtIndex(multi, i);
//            CFStringRef readableLabel = ABAddressBookCopyLocalizedLabel(label);
//            address = ABMultiValueCopyValueAtIndex(multi, i);
//            CFRelease(address);
//            CFRelease(label);
//        }
//        
//        ABMultiValueRef emails = ABRecordCopyValue(ref, kABPersonEmailProperty);
//        NSMutableArray *arEmail = [[NSMutableArray alloc] init];
//        for(CFIndex idx = 0; idx < ABMultiValueGetCount(emails); idx++)
//        {
//            CFStringRef emailRef = ABMultiValueCopyValueAtIndex(emails, idx);
//            NSString *strLbl = (__bridge NSString*) ABAddressBookCopyLocalizedLabel (ABMultiValueCopyLabelAtIndex (emails, idx));
//            NSString *strEmail_old = (__bridge NSString*)emailRef;
//            NSMutableDictionary *temp = [[NSMutableDictionary alloc] init];
//            [temp setObject:strEmail_old forKey:@"strEmail_old"];
//            [temp setObject:strLbl forKey:@"strLbl"];
//            [arEmail addObject:temp];
//        }
//        [myAddressBook setObject:arEmail forKey:@"Email"];
//    }
//    [self createCSV:myAddressBook];
//}
//
//-(void) createCSV :(NSMutableDictionary*)arAddressData
//{
//    NSMutableString *stringToWrite = [[NSMutableString alloc] init];
//    [stringToWrite appendString:[NSString stringWithFormat:@"%@,",[arAddressData valueForKey:@"firstName"]]];
//    [stringToWrite appendString:[NSString stringWithFormat:@"%@,",[arAddressData valueForKey:@"lastName"]]];
//    [stringToWrite appendString:[NSString stringWithFormat:@"%@,",[arAddressData valueForKey:@"jobTitle"]]];
//    //[stringToWrite appendString:@"fname, lname, title, company, phonetype1, value1,phonetype2,value,phonetype3,value3phonetype4,value4,phonetype5,value5,phonetype6,value6,phonetype7,value7,phonetype8,value8,phonetype9,value9,phonetype10,value10,email1type,email1value,email2type,email2value,email3type,email3‌​value,email4type,email4value,email5type,email5value,website1,webs‌​ite2,website3"];
//    NSMutableArray *arPhone = (NSMutableArray*) [arAddressData valueForKey:@"Phone"];
//    for(int i = 0 ;i<[arPhone count];i++)
//    {
//        NSMutableDictionary *temp = (NSMutableDictionary*) [arPhone objectAtIndex:i];
//        [stringToWrite appendString:[NSString stringWithFormat:@"%@,",[temp valueForKey:@"phoneNumber"]]];
//        [stringToWrite appendString:[NSString stringWithFormat:@"%@,",[temp valueForKey:@"phoneNumber"]]];
//    }
//    NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
//    NSString *documentDirectory=[paths objectAtIndex:0];
//    NSString *strBackupFileLocation = [NSString stringWithFormat:@"%@/%@", documentDirectory,@"ContactList.csv"];
//    [stringToWrite writeToFile:strBackupFileLocation atomically:YES encoding:NSUTF8StringEncoding error:nil];
//}
@end
