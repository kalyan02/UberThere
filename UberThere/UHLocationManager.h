//
//  UHLocationManager.h
//  UberTest
//
//  Created by Kalyan on 09/04/16.
//  Copyright (c) 2016 Kalyan. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreLocation;

typedef void (^UHLocationManagerCallback)(CLLocation *);

@interface UHLocationManager : NSObject
+ (instancetype)sharedInstance;
+ (BOOL)authorized;

@property (nonatomic, readonly) CLLocationManager *locationManager;
@property (nonatomic, readonly) CLLocation *recentLocation;

- (void)subscribeLocationUpdates:(UHLocationManagerCallback)callback;
@end
