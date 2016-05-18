//
//  UHPinView.h
//  UberTest
//
//  Created by Kalyan on 09/04/16.
//  Copyright (c) 2016 Kalyan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UHPinView : UIView
@property (nonatomic, strong) UIColor *innerColor;
@property (nonatomic, strong) UIColor *color;
+ (instancetype)pin;
- (UIImage *)image;
@end
