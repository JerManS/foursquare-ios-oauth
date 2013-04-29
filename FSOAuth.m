//
//  FSOAuth.m
//  FSSampleOAuth
//
//  Created by Brian Dorfman on 4/22/13.
//  Copyright (c) 2013 Foursquare. All rights reserved.
//

#import "FSOAuth.h"

#define kFoursquareURL       @"foursquare://"
#define kFoursquareOAuthPath    @"fsqauth://authorize?client_id=%@&v=%@&redirect_uri=%@"
#define kFoursquareOAuthRequiredVersion @"20130312"
#define kFoursquareAppStoreURL @"https://itunes.apple.com/app/foursquare/id306934924?mt=8"

@implementation FSOAuth

+ (FSOAuthStatusCode)authorizeUserUsingClientId:(NSString *)clientID callbackURIString:(NSString *)callbackURIString {
    if ([clientID length] <= 0) {
        return FSOAuthStatusErrorInvalidClientID;
    }

    UIApplication *sharedApplication = [UIApplication sharedApplication];
    if ([callbackURIString length] <= 0 || ![sharedApplication canOpenURL:[NSURL URLWithString:callbackURIString]]) {
        return FSOAuthStatusErrorInvalidCallback;
    }
    
    if (![sharedApplication canOpenURL:[NSURL URLWithString:kFoursquareURL]]) {
        [sharedApplication openURL:[NSURL URLWithString:kFoursquareAppStoreURL]];
        return FSOAuthStatusErrorFoursquareNotInstalled;
    }
    
    NSString *urlEncodedCallbackString = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                                               (CFStringRef)callbackURIString,
                                                                                                               NULL,
                                                                                                               (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                               kCFStringEncodingUTF8);
    
    NSURL *authURL = [NSURL URLWithString:[NSString stringWithFormat:kFoursquareOAuthPath, clientID, kFoursquareOAuthRequiredVersion, urlEncodedCallbackString]];
    
    if (![sharedApplication canOpenURL:authURL]) {
        [sharedApplication openURL:[NSURL URLWithString:kFoursquareAppStoreURL]];
        return FSOAuthStatusErrorFoursquareOAuthNotSupported;
    }
    
    [sharedApplication openURL:authURL];
    
    return FSOAuthStatusSuccess;
}

+ (NSString *)accessCodeForFSOAuthURL:(NSURL *)url error:(FSOAuthErrorCode *)errorCode {
    NSString *accessCode = nil;
    
    if (url) {
        NSArray *parameterPairs = [[url query] componentsSeparatedByString:@"&"];
        
        if (errorCode != NULL) {
            *errorCode = FSOAuthErrorNone;
        }
        
        for (NSString *pair in parameterPairs) {
            NSArray *keyValue = [pair componentsSeparatedByString:@"="];
            if ([keyValue count] == 2) {
                NSString *param = keyValue[0];
                NSString *value = keyValue[1];
                
                if ([param isEqualToString:@"code"]) {
                    accessCode = value;
                }
                else if ([param isEqualToString:@"error"]) {
                    if (errorCode != NULL) {
                        if ([value isEqualToString:@"invalid_request"]) {
                            *errorCode = FSOAuthErrorInvalidRequest;
                        }
                        else if ([value isEqualToString:@"invalid_client"]) {
                            *errorCode = FSOAuthErrorInvalidClient;
                        }
                        else if ([value isEqualToString:@"invalid_grant"]) {
                            *errorCode = FSOAuthErrorInvalidGrant;
                        }
                        else if ([value isEqualToString:@"unauthorized_client"]) {
                            *errorCode = FSOAuthErrorUnauthorizedClient;
                        }
                        else if ([value isEqualToString:@"unsupported_grant_type"]) {
                            *errorCode = FSOAuthErrorUnsupportedGrantType;
                        }
                    }   
                }
            }
        }
    }
    return accessCode;
}
     
@end
