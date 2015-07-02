//
//  FirstViewController.m
//  AuthatureDemo
//
//  Created by Mark Meeus on 01/07/15.
//  Copyright (c) 2015 Sign2Pay. All rights reserved.
//

#import "FirstViewController.h"
#import "AuthatureClient.h"
#import "UIImageView+Authature.h"
#import "UIButton+Authature.h"

@interface FirstViewController ()<AuthatureDelegate>
@property(strong, nonatomic) AuthatureClient* authatureClient;
@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(36, 36), NO, 0.0);
    UIImage *blank = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    [self.preapproveBankLogo useAsAuthatureBankLogos];
    [self.preapproveLogoButton setTitle:@"" forState:UIControlStateNormal];
    [self.preapproveLogoButton useAuthatureBankLogos];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)capture:(id)sender {
    [[self client] startAuthatureFlowForSignatureCapture];
}

- (IBAction)authenticate:(id)sender {
    [[self client] startAuthatureFlowForAuthentication];
}

- (IBAction)preApprove:(id)sender {
    [[self client] startAuthatureFlowForPreapproval];
}

- (AuthatureClient*) client{
    AuthatureClientSettings *settings = [[AuthatureClientSettings alloc]
            initWithClientId:@"7a69e92d4d7dc6b9a407c1ce75e24cc9"
                 callbackUrl:@"http://authature.com/oauth/native/callback/7a69e92d4d7dc6b9a407c1ce75e24cc9"];
    AuthatureUserParams *userParams = nil;
    if(self.emailAddressField.text.length > 0 ||
            self.firstNameAddressField.text.length > 0 ||
            self.lastNameAddressField.text.length > 0){
        userParams = [[AuthatureUserParams  alloc]init];
        userParams.identifier = self.emailAddressField.text;
        userParams.firstName = self.firstNameAddressField.text;
        userParams.lastName = self.lastNameAddressField.text;
    }

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

- (void)authatureAccessTokenReceived:(NSDictionary *)accessToken {
    if([((NSString *) accessToken[@"scopes"]) isEqualToString:AUTHATURE_SCOPE_SIGNATURE_CAPTURE]){
        NSString * text = [NSString stringWithFormat:@"Thank you %@ %@ (%@)",
                                                     accessToken[@"user"][@"last_name"],
                                                     accessToken[@"user"][@"first_name"],
                                                     accessToken[@"user"][@"identifier"]
        ];
        [self alertMessage:text
                  withTile:@"Your signature has been captured."];
    }

    if([((NSString *) accessToken[@"scopes"]) isEqualToString:AUTHATURE_SCOPE_AUTHENTICATE]){
        NSString * text = [NSString stringWithFormat:@"Welcome %@ %@ (%@)",
                        accessToken[@"user"][@"last_name"],
                        accessToken[@"user"][@"first_name"],
                        accessToken[@"user"][@"identifier"]
        ];
        [self alertMessage:text
                  withTile:@"Authentication was succesfull"];
    }

    if([((NSString *) accessToken[@"scopes"]) isEqualToString:AUTHATURE_SCOPE_PRE_APPROVAL]){
        NSString * text = [NSString stringWithFormat:@"Thank you %@ %@ (%@)",
                                                                   accessToken[@"user"][@"last_name"],
                                                                   accessToken[@"user"][@"first_name"],
                                                                   accessToken[@"user"][@"identifier"]
        ];
        [self alertMessage:text
                  withTile:@"Your payment has been preapproved"];
    }
}

-(void) alertMessage:(NSString *)message withTile:(NSString*) title{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}
@end
