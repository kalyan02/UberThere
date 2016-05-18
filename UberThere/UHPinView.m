//
//  UHPinView.m
//  UberTest
//
//  Created by Kalyan on 09/04/16.
//  Copyright (c) 2016 Kalyan. All rights reserved.
//

#import "UHPinView.h"
@import QuartzCore;

@interface UHPinView()

@end

@implementation UHPinView
{
    UIView *bip;
    UIView *pin;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        bip = [[UIView alloc] initWithFrame:CGRectZero];
        [self addSubview:bip];
        
        pin = [[UIView alloc] initWithFrame:CGRectZero];
        [self addSubview:pin];
        
        self.color = [UIColor blackColor];
        self.innerColor = [UIColor whiteColor];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect frame = self.frame;
    CGFloat smallerSide = frame.size.width;
    bip.layer.cornerRadius = smallerSide/2.0;
    bip.frame = CGRectMake(0, 0, smallerSide, smallerSide);
    pin.frame = CGRectMake(CGRectGetWidth(frame)/2.0-1, CGRectGetHeight(frame)/2.0, 2, CGRectGetMaxY(frame)-CGRectGetMidY(frame));
    
    pin.backgroundColor = self.color;
    bip.backgroundColor = self.innerColor;
    bip.layer.borderColor = self.color.CGColor;
    bip.layer.borderWidth = 3;
    
}

- (void)setInnerColor:(UIColor *)innerColor
{
    _innerColor = innerColor;
    
    bip.backgroundColor = _innerColor;
}

+ (instancetype)pin
{
    return [[[self class] alloc] initWithFrame:CGRectMake(0, 0, 25, 50)];
}

- (UIImage *)image
{
    UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, 0.0);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
