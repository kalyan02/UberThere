//
//  UHLocationPin.h
//  UberTest
//
//  Created by Kalyan on 09/04/16.
//  Copyright (c) 2016 Kalyan. All rights reserved.
//

#import <Foundation/Foundation.h>
@import MapKit;
@interface UHLocationPin : NSObject<MKAnnotation>
@property (nonatomic, assign) CLLocationCoordinate2D actualCoordinate;
@property (nonatomic, strong) NSString *actualName;
@property (nonatomic, strong) CLPlacemark *place;
@end
