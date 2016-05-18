//
//  UHUberHelper.m
//  UberTest
//
//  Created by Kalyan on 10/04/16.
//  Copyright (c) 2016 Kalyan. All rights reserved.
//

#import "UHUberHelper.h"

NSString * const UHUberClientID = @"";

@implementation UHUberHelper
- (void)request
{
    NSMutableString *queryString = [NSMutableString new];
    [queryString appendFormat:@"action=setPickup"];
    [queryString appendFormat:@"&client_id=%@", UHUberClientID];
    
    if(self.sourceName) {
        [queryString appendFormat:@"&pickup[latitude]=%@", @(self.source.latitude)];
        [queryString appendFormat:@"&pickup[longitude]=%@", @(self.source.longitude)];
        [queryString appendFormat:@"&pickup[nickname]=%@", [self urlEscapeString:self.sourceName]];
    }
    
    [queryString appendFormat:@"&dropoff[latitude]=%@", @(self.destination.latitude)];
    [queryString appendFormat:@"&dropoff[longitude]=%@", @(self.destination.longitude)];
    [queryString appendFormat:@"&dropoff[nickname]=%@", [self urlEscapeString:self.destinationName]];
    
    NSString *protocol = @"uber://";
    if (![self isUberInstalled]) {
        protocol = @"https://m.uber.com/";
    }
    NSString *url = [NSString stringWithFormat:@"%@?%@", protocol, queryString];
    NSURL *uberURL = [NSURL URLWithString:url];
    [[UIApplication sharedApplication] openURL:uberURL];
}

- (BOOL)isUberInstalled
{
    return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"uber://"]];
}

- (NSString *)urlEscapeString:(NSString *)unencodedString
{
    CFStringRef originalStringRef = (__bridge_retained CFStringRef)unencodedString;
    NSString *s = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,originalStringRef, NULL, NULL,kCFStringEncodingUTF8);
    CFRelease(originalStringRef);
    return s;
}


- (NSString *)serializeParams:(NSDictionary *)params {
    /*
     
     Convert an NSDictionary to a query string
     
     */
    
    NSMutableArray* pairs = [NSMutableArray array];
    for (NSString* key in [params keyEnumerator]) {
        id value = [params objectForKey:key];
        if ([value isKindOfClass:[NSDictionary class]]) {
            for (NSString *subKey in value) {
                NSString* escaped_value = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                              (CFStringRef)[value objectForKey:subKey],
                                                                                              NULL,
                                                                                              (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                              kCFStringEncodingUTF8));
                [pairs addObject:[NSString stringWithFormat:@"%@[%@]=%@", key, subKey, escaped_value]];
            }
        } else if ([value isKindOfClass:[NSArray class]]) {
            for (NSString *subValue in value) {
                NSString* escaped_value = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                              (CFStringRef)subValue,
                                                                                              NULL,
                                                                                              (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                              kCFStringEncodingUTF8));
                [pairs addObject:[NSString stringWithFormat:@"%@[]=%@", key, escaped_value]];
            }
        } else {
            NSString* escaped_value = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                          (CFStringRef)[params objectForKey:key],
                                                                                          NULL,
                                                                                          (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                          kCFStringEncodingUTF8));
            [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, escaped_value]];
        }
    }
    return [pairs componentsJoinedByString:@"&"];
}
@end
