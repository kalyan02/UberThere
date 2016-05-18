//
//  UHDestinationLocationLabel.m
//  UberTest
//
//  Created by Kalyan on 09/04/16.
//  Copyright (c) 2016 Kalyan. All rights reserved.
//

#import "UHDestinationLocationLabel.h"

@interface UHDestinationLocationLabel()
@property (nonatomic, strong) UIButton *searchButton;
@end

@implementation UHDestinationLocationLabel
{
    BOOL _constraintsInstalled;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _constraintsInstalled = NO;
        
        self.searchButton = [[UIButton alloc] init];
        self.searchButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self.searchButton setTitle:@" SEARCH " forState:UIControlStateNormal];
        [self.searchButton.titleLabel setFont:[UIFont systemFontOfSize:12]];
        [self.searchButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        self.searchButton.layer.borderColor = [UIColor blueColor].CGColor;
        self.searchButton.layer.borderWidth = 1;
        self.searchButton.layer.cornerRadius = 3;
        [self.searchButton addTarget:self action:@selector(searchWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.searchButton setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [self.buttons addSubview:self.searchButton];
    }
    return self;
}

- (void)updateConstraints
{
    if (!_constraintsInstalled) {
        _constraintsInstalled = YES;
        
        NSDictionary *views = NSDictionaryOfVariableBindings(_searchButton);
        [self.buttons addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_searchButton]|" options:0 metrics:nil views:views]];
        [self.buttons addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[_searchButton]-5-|" options:0 metrics:nil views:views]];

    }
    
    [super updateConstraints];
}

- (void)searchWasTapped:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(destinationLabelSearchWasTapped:)]) {
        [self.delegate destinationLabelSearchWasTapped:self];
    }
}

@end
