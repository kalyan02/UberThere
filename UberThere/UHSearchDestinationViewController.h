//
//  UHSearchDestinationViewController.h
//  UberTest
//
//  Created by Kalyan on 09/04/16.
//  Copyright (c) 2016 Kalyan. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UHSearchDestinationViewController;
@class MKPlacemark;

@protocol UHSearchDestinationViewControllerDelegate <NSObject>
- (void)searchDestinationViewControllerDidReturn:(MKPlacemark *)place;
@end

@interface UHSearchDestinationViewController : UIViewController
@property (nonatomic, weak) id<UHSearchDestinationViewControllerDelegate> delegate;
@end
