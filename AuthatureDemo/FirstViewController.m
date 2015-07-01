//
//  FirstViewController.m
//  AuthatureDemo
//
//  Created by Mark Meeus on 01/07/15.
//  Copyright (c) 2015 Sign2Pay. All rights reserved.
//

#import "FirstViewController.h"
#import "AuthatureClient.h"

@interface FirstViewController ()<AuthatureDelegate>
@property(strong, nonatomic) AuthatureClient* authatureClient;
@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)capture:(id)sender {
    [[self client] startGetTokenForSignatureCapture];
}

- (IBAction)authenticate:(id)sender {
    [[self client] startGetTokenForAuthentication];
}

- (IBAction)preApprove:(id)sender {
    [[self client] startGetTokenForPreApproval];
}

- (AuthatureClient*) client{
    AuthatureClientSettings *settings = [[AuthatureClientSettings alloc]
            initWithClientId:@"7a69e92d4d7dc6b9a407c1ce75e24cc9"
                 callbackUrl:@"http://authature.com/oauth/native/callback/7a69e92d4d7dc6b9a407c1ce75e24cc9"];
    AuthatureUserParams *userParams = [[AuthatureUserParams  alloc]init];
    userParams.identifier = self.emailAddressField.text;
    userParams.firstName = self.firstNameAddressField.text;
    userParams.lastName = self.lastNameAddressField.text;
    self.authatureClient = [[AuthatureClient alloc] initWithSettings:settings
                                                          userParams:userParams
                                                          andDelegate:self];
    self.authatureClient.automaticTokenStorageEnabled = YES;
    return self.authatureClient;
}

#pragma mark Authature delegate
-(UIViewController *)controllerForAuthatureWebView {
    return self;
}

@end
