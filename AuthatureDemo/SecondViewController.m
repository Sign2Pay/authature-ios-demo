//
//  SecondViewController.m
//  AuthatureDemo
//
//  Created by Mark Meeus on 01/07/15.
//  Copyright (c) 2015 Sign2Pay. All rights reserved.
//

#import <AuthatureClient/AuthatureClient.h>
#import "SecondViewController.h"
#import "AuthatureAccessTokenStorage.h"

@interface SecondViewController ()<AuthatureDelegate>
@property(strong, nonatomic) AuthatureClient *authatureClient;
@property(strong, nonatomic) NSArray *tokens;
@end

@implementation SecondViewController

- (void)viewDidLoad {
    [self setupClient];
    [self loadTokens];
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)addPreapprovalToken:(id)sender{
    [self.authatureClient startGetTokenForPreApproval];
}

-(void) setupClient{
    AuthatureClientSettings *settings = [[AuthatureClientSettings alloc]
            initWithClientId:@"7a69e92d4d7dc6b9a407c1ce75e24cc9"
                 callbackUrl:@"http://authature.com/oauth/native/callback/7a69e92d4d7dc6b9a407c1ce75e24cc9"];

    self.authatureClient = [[AuthatureClient alloc] initWithSettings:settings
                                                          userParams:nil
                                                         andDelegate:self];
    self.authatureClient.automaticTokenStorageEnabled = false; // don't store the tokens automatically
}

-(void) loadTokens{
    [AuthatureAccessTokenStorage destroyAccessTokenForClientId:self.authatureClient.settings.clientId
                                                        andKey:@"token_(null)"];
    self.tokens = [AuthatureAccessTokenStorage allAccessTokensForClientId:self.authatureClient.settings.clientId];
}
#pragma mark authature delegate
- (UIViewController *)controllerForAuthatureWebView {
    return self;
}

- (void)authatureAccessTokenReceived:(NSDictionary *)accessToken {
    NSString *token = accessToken[@"token"];
    [AuthatureAccessTokenStorage saveAccessToken:accessToken
                                     forClientId:self.authatureClient.settings.clientId
                                         withKey:token ];
    [self loadTokens];
}
#pragma mark UITableViewDataSource and delegate
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.tokens.count; 
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = @"authature_token_cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }

    NSDictionary *token = [self.tokens objectAtIndex:indexPath.row];
    cell.textLabel.Text  = [NSString stringWithFormat:@"%@ %@ => %@ (Click to check validity)",
                    token[@"user"][@"last_name"],
                    token[@"user"][@"first_name"],
                    token[@"scopes"]];

    cell.detailTextLabel.Text = [NSString stringWithFormat:@"%@ %@: %@",
                    token[@"account"][@"bank"][@"country_code"],
                    token[@"account"][@"bank"][@"bank_name"],
                    token[@"account"][@"masked_iban"]
        ];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *token = [self.tokens objectAtIndex:indexPath.row];
    [self.authatureClient verifyTokenValidity:token
                                     forScope:token[@"scopes"]
                                     callBack:^(BOOL valid, NSDictionary *response) {
                                         if(valid){
                                             [self alertMessage:[NSString stringWithFormat:@"Token is Valid and can be used for %@", token[@"scopes"]]
                                                       withTile:@"Valid"];
                                         }else{
                                             [self alertMessage:[NSString stringWithFormat:@"Token is NOT Valid and cannot be used for %@", token[@"scopes"]]
                                                       withTile:@"Valid"];
                                         }

                                     } errorCallBack:^(NSError *error) {
                                        [self alertMessage:@"An error occured" withTile:@"Authature"];
            }];
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
