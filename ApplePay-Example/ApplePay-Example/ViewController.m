//
//  ViewController.m
//  ApplePay-Example
//
//  Created by Jhonathan Wyterlin on 28/08/15.
//  Copyright (c) 2015 Jhonathan Wyterlin. All rights reserved.
//

#import "ViewController.h"

#import <PassKit/PassKit.h>

@interface ViewController ()<PKPaymentAuthorizationViewControllerDelegate>

@end

@implementation ViewController

-(void)viewDidLoad {
    [super viewDidLoad];
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - PKPaymentAuthorizationViewControllerDelegate methods

-(void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                      didAuthorizePayment:(PKPayment *)payment
                               completion:(void (^)(PKPaymentAuthorizationStatus status))completion {
    
    [self handlePaymentAuthorizationWithPayment:payment completion:completion];
    
}

-(void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

#pragma mark - Private methods

-(void)handlePaymentAuthorizationWithPayment:(PKPayment *)payment
                                  completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    
    // Try to create a token with the payment
    [self createTokenWithPayment:payment completion:^(PKPaymentToken *token, NSError *error) {
       
        if (error) {
            // Failed
            completion(PKPaymentAuthorizationStatusFailure);
            return;
        }
        
        [self createBackendChargeWithToken:token completion:completion];
        
    }];
    
}

-(void)createTokenWithPayment:(PKPayment *)payment
                   completion:(void(^)(PKPaymentToken *token, NSError *error))completion {
    
    // Try to create a token with the payment
    PKPaymentToken *token = payment.token;
    
    NSError *error;
    
    if ( ! token ) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey:@"Error: Failed to create the token."};
        error = [NSError errorWithDomain:@"MyDomain" code:0 userInfo:userInfo];
    }
    
    if ( completion )
        completion(token,error);

}

-(void)createBackendChargeWithToken:(PKPaymentToken *)token
                         completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    
    NSURL *url = [NSURL URLWithString:@"https://example.com/token"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    
    NSMutableString *parametersInBody = [NSMutableString new];
    
    [parametersInBody appendFormat:@"paymentInstrumentName=%@",token.paymentInstrumentName];
    [parametersInBody appendFormat:@"&paymentNetwork=%@",token.paymentNetwork];
    [parametersInBody appendFormat:@"&transactionIdentifier=%@",token.transactionIdentifier];
    [parametersInBody appendFormat:@"&paymentData=%@",[NSString stringWithUTF8String:[token.paymentData bytes]]];
    
    NSString *body     = [parametersInBody copy];
    
    request.HTTPBody   = [body dataUsingEncoding:NSUTF8StringEncoding];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response,
                                               NSData *data,
                                               NSError *error) {
                               if (error) {
                                   completion(PKPaymentAuthorizationStatusFailure);
                               } else {
                                   completion(PKPaymentAuthorizationStatusSuccess);
                               }
                               
                           }];
    
    return;
    

    
}

@end
