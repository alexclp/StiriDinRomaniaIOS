//
//  LoginViewController.m
//  Stiri
//
//  Created by Vlad Stoica on 8/7/13.
//  Copyright (c) 2013 Stoica Vlad. All rights reserved.
//

#import "LoginViewController.h"
#import <GoogleOpenSource/GoogleOpenSource.h>
#import <GooglePlus/GooglePlus.h>
#import "AFNetworking.h"
@interface LoginViewController ()

@end

@implementation LoginViewController
@synthesize signInButton;
static NSString * const kClientId = @"976584719831.apps.googleusercontent.com";

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    GPPSignIn *signIn = [GPPSignIn sharedInstance];
    signIn.clientID = kClientId;
    signIn.scopes = [NSArray arrayWithObjects:
                     kGTLAuthScopePlusLogin, // defined in GTLPlusConstants.h
                     nil];
    signIn.shouldFetchGoogleUserID = true;
    signIn.shouldFetchGoogleUserEmail = true;
    signIn.delegate = self;
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)finishedWithAuth: (GTMOAuth2Authentication *)auth
                   error: (NSError *) error
{
    if(!error){
        NSString *userId = [GPPSignIn sharedInstance].userID;
        NSString *token = [auth.parameters valueForKey:@"id_token"];
        NSLog(@"Received error %@ and auth object %@",
              [GPPSignIn sharedInstance].userID , auth);
        NSString *urlString =[NSString stringWithFormat:@"http://stiriromania.eu01.aws.af.cm/"];
        NSURL *url = [NSURL URLWithString:urlString];
        AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                                userId, @"fbaccount",
                                token, @"fbtoken",
                                nil];
        [httpClient postPath:@"/user/login" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSString *responseStr = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
            NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData: [responseStr dataUsingEncoding:NSUTF8StringEncoding]
                                                                           options: NSJSONReadingMutableContainers
                                                                             error: nil];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSNumber *userServerId = [jsonDictionary valueForKey:@"id"];
            [defaults setValue:userServerId forKey:@"user_id"];
            [self performSegueWithIdentifier:@"loginSuccesfulSegue" sender:self];
            NSLog(@"Request Successful, response '%@'", responseStr);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"[HTTPClient Error]: %@", error.localizedDescription);
        }];
    }
    
}
@end
