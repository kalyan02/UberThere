//
//  UHLocationManager.m
//  UberTest
//
//  Created by Kalyan on 09/04/16.
//  Copyright (c) 2016 Kalyan. All rights reserved.
//

#import "UHLocationManager.h"

@interface UHLocationManager() <CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *recentLocation;
@property (nonatomic, strong) NSMutableArray *callbacks;
@end

@implementation UHLocationManager

+ (instancetype)sharedInstance
{
    static UHLocationManager *_privateInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _privateInstance = [[UHLocationManager alloc] init];
    });
    return _privateInstance;
}

+ (BOOL)authorized
{
    return [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.locationManager = [[CLLocationManager alloc] init];
        [self.locationManager requestWhenInUseAuthorization];
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [self.locationManager startUpdatingLocation];
        self.locationManager.delegate =  self;
        
        self.callbacks = [[NSMutableArray alloc] init];
        
    }
    return self;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    if (locations.count > 0) {
        CLLocation *location = (CLLocation *)[locations firstObject];;
        self.recentLocation = location;
        
        for (UHLocationManagerCallback callback in self.callbacks) {
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(location);
            });
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self.locationManager startUpdatingLocation];
    }
}

- (void)subscribeLocationUpdates:(UHLocationManagerCallback)callback
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.callbacks addObject:callback];
    });
}
@end
