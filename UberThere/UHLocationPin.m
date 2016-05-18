//
//  UHLocationPin.m
//  UberTest
//
//  Created by Kalyan on 09/04/16.
//  Copyright (c) 2016 Kalyan. All rights reserved.
//

#import "UHLocationPin.h"

@interface UHLocationPin()

@end

@implementation UHLocationPin

- (CLLocationCoordinate2D)coordinate
{
    return self.actualCoordinate;
}

- (NSString *)actualName
{
    if (!_actualName && _place) {
        _actualName = _place.name;
    }
    return _actualName;
}
@end
