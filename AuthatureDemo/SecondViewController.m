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
#import "UIImageView+Authature.h"

@interface SecondViewController ()<AuthatureDelegate>
@property(strong, nonatomic) AuthatureClient *authatureClient;
@property(strong, nonatomic) NSArray *tokens;
@property(nonatomic) BOOL isEditing;
@end

@implementation SecondViewController

- (void)viewDidLoad {
    [self setupClient];
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillAppear:(BOOL)animated {
    [self loadTokens];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    [self.tableView reloadData];
}
#pragma mark UITableViewDataSource and delegate
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.tokens.count +  1; //one for the add button
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row < self.tokens.count){
        return [self createTokenCellForTokenIndex:indexPath.row];

    } else{
        return [self createAddTokenButtonCell];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Add as many accounts as you want";
}

- (UITableViewCell *)createAddTokenButtonCell {
    NSString *identifier = @"authature_add_button_cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    cell.textLabel.text = @"ADD NEW ACCOUNT";
    return cell;
}

- (UITableViewCell *)createTokenCellForTokenIndex:(NSInteger)index {
    NSString *identifier = @"authature_token_cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }

    NSDictionary *token = [self.tokens objectAtIndex:index];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ %@ => %@ (Click to check validity)",
                                                     token[@"user"][@"last_name"],
                                                     token[@"user"][@"first_name"],
                                                     token[@"scopes"]];

    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@: %@",
                                                           token[@"account"][@"bank"][@"country_code"],
                                                           token[@"account"][@"bank"][@"bank_name"],
                                                           token[@"account"][@"masked_iban"]
    ];

    [cell.imageView useAsAuthatureBankLogosWithToken:token];
    cell.editing = YES;
    return cell;
}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row < self.tokens.count;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row < self.tokens.count){
        return UITableViewCellEditingStyleDelete;
    }
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if(editingStyle == UITableViewCellEditingStyleDelete){
        NSDictionary *token = [self.tokens objectAtIndex:indexPath.row];
        //check if this token is stored as one of the automatic tokens of FirstView
        NSDictionary *tokenForSameScope = [self.authatureClient getStoredTokenForScope:token[@"scopes"]]; //get the stored token for the same scope
        if(tokenForSameScope != NULL &&
                [((NSString *) tokenForSameScope[@"scopes"]) isEqualToString:token[@"scopes"]]) {
            [self.authatureClient destroyStoredTokenForScope:token[@"scopes"]];
        }else
        {
            [AuthatureAccessTokenStorage destroyAccessTokenForClientId:self.authatureClient.settings.clientId
                                                                andKey:token[@"token"]];
        }

        [self loadTokens];
        [self.tableView reloadData];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row == self.tokens.count){
        [self.authatureClient startAuthatureFlowForPreapproval];
    }else{
        NSDictionary *token = [self.tokens objectAtIndex:indexPath.row];
        [self.authatureClient verifyTokenValidity:token
                                         forScope:token[@"scopes"]
                                         callBack:^(BOOL valid, NSDictionary *response) {
                                             if(valid){
                                                 [self alertMessage:[NSString stringWithFormat:@"Token is Valid and can be used for %@", token[@"scopes"]]
                                                           withTitle:@"Valid"];
                                             }else{
                                                 [self alertMessage:[NSString stringWithFormat:@"Token is NOT Valid and cannot be used for %@", token[@"scopes"]]
                                                           withTitle:@"Valid"];
                                             }

                                         } errorCallBack:^(NSError *error) {
                    [self alertMessage:@"An error occured" withTitle:@"Authature"];
                }];
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
