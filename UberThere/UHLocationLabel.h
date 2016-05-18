//
//  UHLocationLabel.h
//  UberTest
//
//  Created by Kalyan on 09/04/16.
//  Copyright (c) 2016 Kalyan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UHLocationLabel : UIView
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) UILabel *locationLabel;
@property (nonatomic, strong) NSString *placeholderText;
@property (nonatomic, strong) NSString *locationText;

@property (nonatomic, strong) UIView *buttons;
@end
