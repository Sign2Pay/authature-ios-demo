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
@property(strong, nonatomic) NSDictionary *currentUserToken;
@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initAuthatureClient];

    [self.defaultBankLogo useAsAuthatureBankLogos];
    [self.nlBankLogo useAsAuthatureBankLogosForCountryCode:@"NL"];

    [self.checkoutLogoButton setTitle:@"" forState:UIControlStateNormal];
    [self.checkoutLogoButton useAuthatureBankLogos];

    [self updateViews];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) updateViews{
    NSDictionary *tokenForCheckout = [self.authatureClient getStoredTokenForScope:AUTHATURE_SCOPE_PRE_APPROVAL];
    if(tokenForCheckout){
        [self.currentAccountLabel setHidden:NO];
        self.currentAccountLabel.text = [NSString stringWithFormat:@"BANK: %@\nIBAN: %@",
                tokenForCheckout[@"account"][@"bank"][@"bank_name"],
                        tokenForCheckout[@"account"][@"masked_iban"]];
        [self.checkoutLogoButton useAuthatureBankLogosWithToken:tokenForCheckout];
    }else{
        [self.checkoutLogoButton useAuthatureBankLogos];
        [self.currentAccountLabel setHidden:YES];
    }

    if(self.currentUserToken){
        self.emailAddressField.text = self.currentUserToken[@"user"][@"identifier"];
        self.firstNameField.text = self.currentUserToken[@"user"][@"first_name"];
        self.lastNameField.text = self.currentUserToken[@"user"][@"last_name"];
    }
}

- (IBAction)authenticate:(id)sender {
    [self.authatureClient startAuthatureFlowForAuthentication];
}

- (IBAction)checkout:(id)sender {
    [self ensureTokenAndCheckout];
}

- (void)ensureTokenAndCheckout {
    [self.authatureClient verifyStoredTokenValidityforScope:AUTHATURE_SCOPE_PRE_APPROVAL
                                                   callBack:^(BOOL tokenIsValid, NSDictionary *responseObject) {
                                                       if(tokenIsValid){
                                                           //The token is still valid
                                                           //Start actual payment process here
                                                           [self checkout];
                                                       }else{
                                                           //time to reapprove
                                                           [self.authatureClient startAuthatureFlowForPreapproval];
                                                       }
                                                   } errorCallBack:^(NSError *error) {
                [self alertMessage:@"An error occured" withTitle:@"Checkout"];
            }];
}

- (IBAction)unlinkCurrentAccount:(id)sender {
    [self.authatureClient destroyStoredTokenForScope:AUTHATURE_SCOPE_PRE_APPROVAL];
    [self updateViews];
}

- (void) initAuthatureClient{
    AuthatureClientSettings *settings = [[AuthatureClientSettings alloc]
            initWithClientId:@"7a69e92d4d7dc6b9a407c1ce75e24cc9"
                 callbackUrl:@"http://authature.com/oauth/native/callback/7a69e92d4d7dc6b9a407c1ce75e24cc9"];
    AuthatureUserParams *userParams = nil;
    if(self.emailAddressField.text.length > 0 ||
            self.firstNameField.text.length > 0 ||
            self.lastNameField.text.length > 0){
        userParams = [[AuthatureUserParams  alloc]init];
        userParams.identifier = self.emailAddressField.text;
        userParams.firstName = self.firstNameField.text;
        userParams.lastName = self.lastNameField.text;
    }

    self.authatureClient = [[AuthatureClient alloc] initWithSettings:settings
                                                          userParams:userParams
                                                          andDelegate:self];
    //Let the client store the tokens per scope
    self.authatureClient.automaticTokenStorageEnabled = YES;
}

-(void) checkout{
    [self alertMessage:@"Your payment was accepted" withTitle:@"Thank you"];
}
#pragma mark Authature delegate
-(UIViewController *)controllerForAuthatureWebView {
    return self;
}

- (void)authatureAccessTokenReceived:(NSDictionary *)accessToken {
    if([((NSString *) accessToken[@"scopes"]) isEqualToString:AUTHATURE_SCOPE_AUTHENTICATE]){
        self.currentUserToken = accessToken;
        [self updateViews];
        NSString * text = [NSString stringWithFormat:@"Welcome %@ %@ (%@)",
                        accessToken[@"user"][@"last_name"],
                        accessToken[@"user"][@"first_name"],
                        accessToken[@"user"][@"identifier"]
        ];
        [self alertMessage:text
                  withTitle:@"Authentication was succesfull"];
    }

    if([((NSString *) accessToken[@"scopes"]) isEqualToString:AUTHATURE_SCOPE_PRE_APPROVAL]){
        [self checkout];
    }
}

-(void) alertMessage:(NSString *)message withTitle:(NSString*) title{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}
@end
