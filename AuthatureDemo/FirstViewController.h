//
//  FirstViewController.h
//  AuthatureDemo
//
//  Created by Mark Meeus on 01/07/15.
//  Copyright (c) 2015 Sign2Pay. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FirstViewController : UIViewController

@property(strong, nonatomic) IBOutlet UITextField *emailAddressField;
@property(strong, nonatomic) IBOutlet UITextField *firstNameAddressField;
@property(strong, nonatomic) IBOutlet UITextField *lastNameAddressField;

@property(strong, nonatomic) IBOutlet UIImageView *preapproveBankLogo;
@property(strong, nonatomic) IBOutlet UIButton *preapproveLogoButton;
@property(strong, nonatomic) IBOutlet UILabel *currentAccountLabel;


-(IBAction)authenticate:(id)sender;
-(IBAction)checkout:(id)sender;
-(IBAction)unlinkCurrentAccount:(id)sender;

@end

