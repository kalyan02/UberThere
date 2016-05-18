//
//  UHUberHelper.h
//  UberTest
//
//  Created by Kalyan on 10/04/16.
//  Copyright (c) 2016 Kalyan. All rights reserved.
//

#import <Foundation/Foundation.h>

@import MapKit;

@interface UHUberHelper : NSObject
@property (nonatomic, strong) NSString *sourceName;
@property (nonatomic, assign) CLLocationCoordinate2D source;
@property (nonatomic, strong) NSString *destinationName;
@property (nonatomic, assign) CLLocationCoordinate2D destination;

- (void)request;
@end
