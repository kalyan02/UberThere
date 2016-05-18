//
//  UHLocationLabel.m
//  UberTest
//
//  Created by Kalyan on 09/04/16.
//  Copyright (c) 2016 Kalyan. All rights reserved.
//

#import "UHLocationLabel.h"

static const CGFloat CircleViewRadius = 8;

@interface UHLocationLabel()
@property (nonatomic, strong) UIView *circleView;
@property (nonatomic, assign) BOOL constraintsInstalled;
@end

@implementation UHLocationLabel

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.locationLabel = [[UILabel alloc] init];
        self.locationLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.locationLabel.font = [UIFont systemFontOfSize:14];
        self.locationLabel.textAlignment = NSTextAlignmentLeft;
        self.locationLabel.text = @"";
        [self addSubview:self.locationLabel];
        
        self.circleView = [[UIView alloc] init];
        self.circleView.translatesAutoresizingMaskIntoConstraints = NO;
        self.circleView.backgroundColor = [UIColor blackColor];
        self.circleView.layer.cornerRadius = CircleViewRadius;
        [self addSubview:self.circleView];
        
        self.color = [UIColor blackColor];
        
        self.backgroundColor = [UIColor whiteColor];
        self.layer.shadowColor = [UIColor grayColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(1, 1);
        self.layer.shadowRadius = 3;
        self.layer.shadowOpacity = 0.5;
        
        self.buttons = [[UIView alloc] init];
        self.buttons.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.buttons];
        
        
        
        

    }
    return self;
}

- (void)setPlaceholderText:(NSString *)placeholderText
{
    _placeholderText = placeholderText;
    [self updateLabel];
}

- (void)setLocationText:(NSString *)locationText
{
    _locationText = locationText;
    [self updateLabel];
}

- (void)updateLabel
{
    NSString *text;
    UIColor *fgColor;
    NSDictionary *attrs;
    if (!_locationText) {
        text = _placeholderText;
        fgColor = [UIColor lightGrayColor];
    } else {
        text = _locationText;
        fgColor = [UIColor blackColor];
    }
    
    attrs = @{
              NSFontAttributeName : [UIFont systemFontOfSize:14],
              NSForegroundColorAttributeName : fgColor
              };
    
    self.locationLabel.attributedText = [[NSAttributedString alloc] initWithString:text
                                                                        attributes:attrs];
}

- (void)updateConstraints
{
    if (!_constraintsInstalled) {
        _constraintsInstalled = YES;
        
        NSDictionary *metrics = @{
                                  @"dia" : @(CircleViewRadius*2),
                                  @"vpad" : @10,
                                  @"hpad" : @10,
                                  };
        NSDictionary *views = NSDictionaryOfVariableBindings(_locationLabel, _circleView, _buttons);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-hpad-[_circleView(==dia)]-hpad-[_locationLabel]-hpad-[_buttons]-hpad-|"
                                                                     options:0
                                                                     metrics:metrics
                                                                       views:views]];


        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-vpad-[_locationLabel]-vpad-|"
                                                                     options:0
                                                                     metrics:metrics
                                                                       views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_buttons]|"
                                                                     options:0
                                                                     metrics:metrics
                                                                       views:views]];

        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.circleView
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1
                                                          constant:0]];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.circleView
                                                         attribute:NSLayoutAttributeWidth
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self.circleView
                                                         attribute:NSLayoutAttributeHeight
                                                        multiplier:1
                                                          constant:0]];
        
        
        
    }
    
    [super updateConstraints];
}

- (void)setColor:(UIColor *)color
{
    _color = color;
    self.circleView.backgroundColor = color;
}


@end
