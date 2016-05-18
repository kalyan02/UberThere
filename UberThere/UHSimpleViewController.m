//
//  UHSimpleViewController.m
//  UberTest
//
//  Created by Kalyan on 10/04/16.
//  Copyright (c) 2016 Kalyan. All rights reserved.
//

#import "UHSimpleViewController.h"

#import <MapKit/MapKit.h>

#import "UHLocationLabel.h"
#import "UHDestinationLocationLabel.h"
#import "UHLocationPin.h"
#import "UHPinView.h"

#import "UHSearchDestinationViewController.h"

#import "UHLocationManager.h"
#import "UHUberHelper.h"

static UIColor *UHPinColorSource;
static UIColor *UHPinColorDestination;

@interface UHSimpleViewController () <MKMapViewDelegate, UHDestinationLocationLabelDelegate, UHSearchDestinationViewControllerDelegate>
@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, assign) BOOL mapInitialized;

@property (nonatomic, strong) UHDestinationLocationLabel *dest;
@property (nonatomic, strong) UHLocationPin *destPlace;
@property (nonatomic, strong) MKAnnotationView *destPlaceView;
@property (nonatomic, strong) UIImage *destPinImage;

@property (nonatomic, strong) UHPinView *pin;
@property (nonatomic, assign) CGPoint pinReferencePoint;

@property (nonatomic, strong) CLGeocoder *geocoder;

@property (nonatomic, assign) BOOL constraintsInstalled;

@property (nonatomic, strong) UIButton *uberButton;


@property (nonatomic, assign) BOOL deltaCalculated;
@property (nonatomic, assign) MKCoordinateSpan defaultSpan;
@property (nonatomic, assign) CLLocationCoordinate2D coordinateDelta;
@end

@implementation UHSimpleViewController

- (void)loadView
{
    self.view = [[UIView alloc] init];
    NSLog(@"damn!");
    
    self.pin = [UHPinView pin];
    self.uberButton = [[UIButton alloc] init];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    __weak typeof(self) weakSelf = self;
    [[UHLocationManager sharedInstance] subscribeLocationUpdates:^(CLLocation *l) {
        [self showFirstMapView];
    }];
    
    [[UHLocationManager sharedInstance].locationManager startUpdatingLocation];
    
    UHPinColorSource = [UIColor greenColor];
    UHPinColorDestination = [UIColor redColor];
    
    self.title = @"UberHelper";
    
    self.mapView = [[MKMapView alloc] init];
    self.mapView.translatesAutoresizingMaskIntoConstraints = NO;
    self.mapView.delegate = self;
    [self.view addSubview:self.mapView];
    
    
    {
        self.dest = [[UHDestinationLocationLabel alloc] init];
        self.dest.color = UHPinColorDestination;
        self.dest.delegate = self;
        self.dest.translatesAutoresizingMaskIntoConstraints = NO;
        self.dest.placeholderText = @"Destination";
        [self.view addSubview:self.dest];
    }
    
    [self.view addSubview:self.pin];
    
    self.pinReferencePoint = CGPointZero;
    
    self.geocoder = [[CLGeocoder alloc] init];
    
    self.uberButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.uberButton setBackgroundColor:[UIColor blackColor]];
    [self.uberButton setTitle:@"Uber it" forState:UIControlStateNormal];
    [self.uberButton addTarget:self action:@selector(uberIt) forControlEvents:UIControlEventTouchUpInside];
    self.uberButton.hidden = NO;
    [self.view addSubview:self.uberButton];
    
    
}

- (void)showFirstMapView
{
    static BOOL didShowFirstView = NO;
    if (!didShowFirstView) {
        didShowFirstView = YES;
        
        
        self.mapView.showsUserLocation = YES;
        
        CLLocation *l = [[UHLocationManager sharedInstance] recentLocation];
        [self setUnderPinLat:l.coordinate.latitude andLon:l.coordinate.longitude];
    }

}

- (void)updateViewConstraints
{
    if(!self.constraintsInstalled) {
        self.constraintsInstalled = YES;
        NSDictionary *views = NSDictionaryOfVariableBindings(_mapView, _dest, _pin, _uberButton);
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-5-[_dest]-5-|"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:views]];
        
        
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_mapView]|"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:views]];
        
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_mapView]|"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:views]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[_dest]"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:views]];
        
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_uberButton]-5-|"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:views]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-5-[_uberButton]-5-|"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:views]];
        
        
        /*
         [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.pin attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.mapView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
         [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.pin attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.mapView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
         */
        
    }
    
    [super updateViewConstraints];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    static BOOL refPointRegistered = NO;
    
    if (!refPointRegistered) {
        refPointRegistered = YES;
        
        // set a test layout center
        [self setLat:31.224777 andLon:121.529891];
        
        // layout pin from its center
        self.pin.center = CGPointMake(CGRectGetMidX(self.mapView.frame), CGRectGetMidY(self.mapView.frame));
        
        // the point under which we have actual marker
        self.pinReferencePoint = CGPointMake(self.pin.center.x, CGRectGetMaxY(self.pin.frame));
        
        // Calculate offsets for reference point
        CLLocationCoordinate2D coordUnderPin = [self.mapView convertPoint:self.pinReferencePoint toCoordinateFromView:self.view];
        CLLocationCoordinate2D coordAtCenter = self.mapView.centerCoordinate;
        
        self.coordinateDelta = CLLocationCoordinate2DMake(coordUnderPin.latitude - coordAtCenter.latitude, coordUnderPin.longitude - coordAtCenter.longitude);
        
    }
    
}

#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    NSLog(@"User stopped moving now");

    // reverse geocode only if we are not animating
    if (self.mapInitialized) {
        [self reverseGeocodeCurrentPin];
    }

}

- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView
{
    NSLog(@"done loading");
    self.mapInitialized = YES;
    
    [self reverseGeocodeCurrentPin];
}


#pragma mark - Map Helpers


- (void)setLat:(CLLocationDegrees)lat andLon:(CLLocationDegrees)lon
{
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(lat, lon);
    MKCoordinateRegion baseRegion = MKCoordinateRegionMakeWithDistance(coord, 1350, 1350);
    MKCoordinateRegion adjRegion = [self.mapView regionThatFits:baseRegion];
    [self.mapView setRegion:adjRegion animated:NO];
}

- (void)setUnderPinLat:(CLLocationDegrees)lat andLon:(CLLocationDegrees)lon
{
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(lat-self.coordinateDelta.latitude, lon-self.coordinateDelta.longitude);
    MKCoordinateRegion baseRegion = MKCoordinateRegionMakeWithDistance(coord, 1350, 1350);
    MKCoordinateRegion adjRegion = [self.mapView regionThatFits:baseRegion];
    [self.mapView setRegion:adjRegion animated:YES];
}

- (void)reverseGeocodeCurrentPin
{
    __weak typeof(self) weakSelf = self;
    [self.geocoder cancelGeocode];
    
    CLLocationCoordinate2D coord = [self.mapView convertPoint:self.pinReferencePoint toCoordinateFromView:self.view];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
    [self.geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        
        [weakSelf updateAppropriateLocationLabels:placemarks forRequestCoord:coord];
    }];
    
}

- (void)updateAppropriateLocationLabels:(NSArray *)placemarks forRequestCoord:(CLLocationCoordinate2D)coord
{
    if (placemarks.count > 0) {
        CLPlacemark *place = [placemarks firstObject];
        
        self.destPlace.place = place;
        self.dest.locationText = place.name;
        if (!CLLocationCoordinate2DIsValid(coord)) {
            self.destPlace.actualCoordinate = place.location.coordinate;
        } else {
            self.destPlace.actualCoordinate = coord;
        }

        
        NSLog(@"%@", place);
    }
}

- (void)uberIt
{
    [self requestUber];
}


#pragma mark - Lazy getters


-(UHLocationPin *)destPlace
{
    if (!_destPlace) {
        _destPlace = [[UHLocationPin alloc] init];
    }
    return _destPlace;
}

#pragma mark - UHDestinationLocationLabelDelegate

- (void)destinationLabelSearchWasTapped:(UHDestinationLocationLabel *)label
{
    UHSearchDestinationViewController *searchVC = [[UHSearchDestinationViewController alloc] init];
    searchVC.delegate = self;
    
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:searchVC];
    navVC.navigationBar.barStyle = UIBarStyleBlack;
    navVC.navigationBar.translucent = NO;
    
    [self.navigationController presentViewController:navVC animated:YES completion:nil];
}

#pragma mark - UHSearchDestinationViewControllerDelegate

- (void)searchDestinationViewControllerDidReturn:(MKPlacemark *)place
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    if (place) {
        self.destPlace.actualName = place.name;
        
        [self updateAppropriateLocationLabels:@[ place ]
                              forRequestCoord:kCLLocationCoordinate2DInvalid];
        [self setUnderPinLat:place.coordinate.latitude
                      andLon:place.coordinate.longitude];
    }
}


#pragma mark - Uber It

- (void)requestUber
{
    UHUberHelper *uber = [[UHUberHelper alloc] init];
    uber.destination = self.destPlace.coordinate;
    uber.destinationName = self.destPlace.actualName;
    
    [uber request];
}

@end

