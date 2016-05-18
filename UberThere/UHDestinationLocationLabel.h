//
//  UHDestinationLocationLabel.h
//  UberTest
//
//  Created by Kalyan on 09/04/16.
//  Copyright (c) 2016 Kalyan. All rights reserved.
//

#import "UHLocationLabel.h"

@class UHDestinationLocationLabel;

@protocol UHDestinationLocationLabelDelegate <NSObject>
- (void)destinationLabelSearchWasTapped:(UHDestinationLocationLabel *)label;
@end

@interface UHDestinationLocationLabel : UHLocationLabel
@property (nonatomic, weak) id<UHDestinationLocationLabelDelegate> delegate;
@end
