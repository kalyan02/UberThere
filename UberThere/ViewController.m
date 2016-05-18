//
//  ViewController.m
//  UberTest
//
//  Created by Kalyan on 09/04/16.
//  Copyright (c) 2016 Kalyan. All rights reserved.
//

#import "ViewController.h"
#import <MapKit/MapKit.h>

#import "UHLocationLabel.h"
#import "UHDestinationLocationLabel.h"
#import "UHLocationPin.h"
#import "UHPinView.h"

#import "UHSearchDestinationViewController.h"

#import "UHLocationManager.h"
#import "UHUberHelper.h"

typedef NS_ENUM(NSUInteger, UHLocationSelectionMode) {
    UHLocationSelectionModeNone,
    UHLocationSelectionModeSource,
    UHLocationSelectionModeDestination,
};

typedef NS_ENUM(NSUInteger, UHSelectionState) {
    UHSelectionStateNone,
    UHSelectionStateAnimating,

};

static UIColor *UHPinColorSource;
static UIColor *UHPinColorDestination;

MKMapRect MKMapRectFromCoordinateRegion(MKCoordinateRegion region)
{
    CLLocationCoordinate2D leftTop = CLLocationCoordinate2DMake(region.center.latitude + region.span.latitudeDelta/2.0, region.center.longitude + region.span.longitudeDelta/2.0);
    CLLocationCoordinate2D botRight = CLLocationCoordinate2DMake(region.center.latitude - region.span.latitudeDelta/2.0, region.center.longitude - region.span.longitudeDelta/2.0);
    
    MKMapPoint leftTopPt = MKMapPointForCoordinate(leftTop);
    MKMapPoint botRightPt = MKMapPointForCoordinate(botRight);
    
    MKMapRect rect =  MKMapRectMake(
                                    MIN(leftTopPt.x,botRightPt.x),
                                    MIN(leftTopPt.y,botRightPt.y),
                                    ABS(botRightPt.x-leftTopPt.x),
                                    ABS(botRightPt.y-leftTopPt.y)
                                    );
    return rect;
}



@interface ViewController () <MKMapViewDelegate, UHDestinationLocationLabelDelegate, UHSearchDestinationViewControllerDelegate>
@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, assign) BOOL mapInitialized;

@property (nonatomic, assign) UHLocationSelectionMode locationSelectionMode;
@property (nonatomic, assign) UHSelectionState selectionState;

@property (nonatomic, strong) UHLocationLabel *src;
@property (nonatomic, strong) UHDestinationLocationLabel *dest;
@property (nonatomic, strong) UHLocationPin *srcPlace;
@property (nonatomic, strong) UHLocationPin *destPlace;
@property (nonatomic, strong) MKAnnotationView *srcPlaceView;
@property (nonatomic, strong) MKAnnotationView *destPlaceView;
@property (nonatomic, strong) UIImage *srcPinImage;
@property (nonatomic, strong) UIImage *destPinImage;

@property (nonatomic, strong) UHPinView *pin;
@property (nonatomic, assign) CGPoint pinReferencePoint;

@property (nonatomic, strong) CLGeocoder *geocoder;

@property (nonatomic, assign) BOOL constraintsInstalled;

@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) UIButton *uberButton;

@property (nonatomic, assign) BOOL deltaCalculated;
@property (nonatomic, assign) MKCoordinateSpan defaultSpan;
@property (nonatomic, assign) CLLocationCoordinate2D coordinateDelta;
@end

@implementation ViewController

- (void)loadView
{
    self.view = [[UIView alloc] init];
    NSLog(@"damn!");
    
    self.pin = [UHPinView pin];
    self.nextButton = [[UIButton alloc] init];
    self.uberButton = [[UIButton alloc] init];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [UHLocationManager sharedInstance];
    
    UHPinColorSource = [UIColor greenColor];
    UHPinColorDestination = [UIColor redColor];
    
    self.title = @"UberHelper";
    
    self.mapView = [[MKMapView alloc] init];
    self.mapView.translatesAutoresizingMaskIntoConstraints = NO;
    self.mapView.delegate = self;
    [self.view addSubview:self.mapView];
    
    {
        UITapGestureRecognizer *onTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(locationInputFieldDidChange:)];
        self.src = [[UHLocationLabel alloc] init];
        self.src.color = UHPinColorSource;
        self.src.translatesAutoresizingMaskIntoConstraints = NO;
        self.src.placeholderText = @"Source";
        [self.src addGestureRecognizer:onTap];
        [self.view addSubview:self.src];
    }
    
    {
        UITapGestureRecognizer *onTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(locationInputFieldDidChange:)];
        self.dest = [[UHDestinationLocationLabel alloc] init];
        self.dest.color = UHPinColorDestination;
        self.dest.delegate = self;
        self.dest.translatesAutoresizingMaskIntoConstraints = NO;
        self.dest.placeholderText = @"Destination";
        [self.dest addGestureRecognizer:onTap];
        [self.view addSubview:self.dest];
    }
    
    self.locationSelectionMode = UHLocationSelectionModeSource;
    self.selectionState = UHSelectionStateNone;
    
    [self.view addSubview:self.pin];
    
    self.pinReferencePoint = CGPointZero;
    
    self.geocoder = [[CLGeocoder alloc] init];
    

    self.nextButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.nextButton setBackgroundColor:[UIColor blackColor]];
    [self.nextButton setTitle:@"Next" forState:UIControlStateNormal];
    [self.nextButton addTarget:self action:@selector(switchToReviewMode) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.nextButton];
    [self enableNextButton:NO];
    
    
    self.uberButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.uberButton setBackgroundColor:[UIColor blackColor]];
    [self.uberButton setTitle:@"Uber it" forState:UIControlStateNormal];
    [self.uberButton addTarget:self action:@selector(uberIt) forControlEvents:UIControlEventTouchUpInside];
    self.uberButton.hidden = YES;
    [self.view addSubview:self.uberButton];


}

// Manually tap on different input field
- (void)locationInputFieldDidChange:(UITapGestureRecognizer *)gr
{
    [self switchToSelectionMode];
    
    if (gr.view == self.dest) {
        
        // if it was set already, first zoom in to that area
        if (self.destPlace.place) {
            self.selectionState = UHSelectionStateAnimating;
            [self setUnderPinLat:self.destPlace.coordinate.latitude andLon:self.destPlace.coordinate.longitude];
        }

        self.locationSelectionMode = UHLocationSelectionModeDestination;
    } else if(gr.view == self.src) {
        if (self.srcPlace.place) {
            self.selectionState = UHSelectionStateAnimating;
            [self setUnderPinLat:self.srcPlace.coordinate.latitude andLon:self.srcPlace.coordinate.longitude];
        }
        self.locationSelectionMode = UHLocationSelectionModeSource;
    }
}

- (void)setLocationSelectionMode:(UHLocationSelectionMode)locationSelectionMode
{
    _locationSelectionMode = locationSelectionMode;
    

    CGFloat alphaBlur = 0.7;
    

    if (_locationSelectionMode == UHLocationSelectionModeSource) {
        self.pin.innerColor = UHPinColorSource;
        if (!_srcPinImage) {
            _srcPinImage = self.pin.image;
        }
        [UIView animateWithDuration:0.2 animations:^{
            _src.alpha = 1;
            _dest.alpha = alphaBlur;
        }];
    } else if(_locationSelectionMode == UHLocationSelectionModeDestination) {
        self.pin.innerColor = UHPinColorDestination;
        if (!_destPinImage) {
            _destPinImage = self.pin.image;
        }
        [UIView animateWithDuration:0.2 animations:^{
            _src.alpha = alphaBlur;
            _dest.alpha = 1;
        }];
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            _src.alpha = alphaBlur;
            _dest.alpha = alphaBlur;
        }];
    }
    
    [self updateVisibleAnnotations];
}

- (void)updateViewConstraints
{
    if(!self.constraintsInstalled) {
        self.constraintsInstalled = YES;
        NSDictionary *views = NSDictionaryOfVariableBindings(_mapView, _src, _dest, _pin, _nextButton, _uberButton);
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-5-[_src]-5-|"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:views]];
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
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[_src(==_dest)]-5-[_dest]"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:views]];
        
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_nextButton]-5-|"
                                                                          options:0
                                                                          metrics:nil
                                                                            views:views]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-5-[_nextButton]-5-|"
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
    
    // If state was animating, we already have coordinates
    // so we don't need to reverse geocode it
    if (self.selectionState == UHSelectionStateAnimating) {
        self.selectionState = UHSelectionStateNone;
    } else {
        // reverse geocode only if we are not animating
        if (self.mapInitialized) {
            [self reverseGeocodeCurrentPin];
        }
    }
}

- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView
{
    NSLog(@"done loading");
    self.mapInitialized = YES;
    
    [self reverseGeocodeCurrentPin];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if (annotation == self.srcPlace || annotation == self.destPlace) {
        MKAnnotationView *view = [mapView dequeueReusableAnnotationViewWithIdentifier:@"loc"];
        if (!view) {
            view = [[MKAnnotationView alloc] initWithAnnotation:nil
                                                reuseIdentifier:@"loc"];
        }

        if (annotation == self.srcPlace) {
            view.image = self.srcPinImage;
            view.centerOffset = CGPointMake(0, -view.image.size.height/2);
            return view;
        }
        if (annotation == self.destPlace) {
            view.image = self.destPinImage;
            view.centerOffset = CGPointMake(0, -view.image.size.height/2);
            return view;
        }
    }
    return nil;
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

- (void)withCurrentZoomSetLat:(CLLocationDegrees)lat andLon:(CLLocationDegrees)lon
{
    self.mapView.centerCoordinate = CLLocationCoordinate2DMake(lat, lon);
}


- (void)reverseGeocodeCurrentPin
{
    if (self.locationSelectionMode == UHLocationSelectionModeNone) {
        return;
    }
    
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
        
        if (self.locationSelectionMode == UHLocationSelectionModeSource) {
            self.srcPlace.place = place;
            if (!CLLocationCoordinate2DIsValid(coord)) {
                self.srcPlace.actualCoordinate = place.location.coordinate;
            } else {
                self.srcPlace.actualCoordinate = coord;
            }
            self.src.locationText = place.name;
            
            //[self calculateCenterOffsetsIfRequired];
            
        } else if(self.locationSelectionMode == UHLocationSelectionModeDestination) {
            self.destPlace.place = place;
            if (!CLLocationCoordinate2DIsValid(coord)) {
                self.destPlace.actualCoordinate = place.location.coordinate;
            } else {
                self.destPlace.actualCoordinate = coord;
            }
            self.dest.locationText = place.name;
        }
        
        [self updateVisibleAnnotations];
        
        NSLog(@"%@", place);
    }
    
    if (self.srcPlace.place && self.destPlace.place) {
        [self enableNextButton:YES];
    } else {
        [self enableNextButton:NO];
    }
}

- (void)calculateCenterOffsetsIfRequired
{
    // zoom to coordinate
    // with it being located at a point in view

    if (!self.deltaCalculated) {
        self.deltaCalculated = YES;
        
    }
}

- (void)enableNextButton:(BOOL)enable
{
    if (enable) {
        self.nextButton.alpha = 1;
        self.nextButton.userInteractionEnabled = YES;
    } else {
        self.nextButton.alpha = 0.2;
        self.nextButton.userInteractionEnabled = NO;
    }
}

- (void)switchToReviewMode
{
    self.locationSelectionMode = UHLocationSelectionModeNone;
    
    self.nextButton.hidden = YES;
    self.uberButton.hidden = NO;
    
    [self updateVisibleAnnotations];
    
    if (self.srcPlace.place && self.destPlace.place) {

        /*
        MKCoordinateSpan span = MKCoordinateSpanMake(
                    ABS(self.srcPlace.coordinate.latitude - self.destPlace.coordinate.latitude),
                    ABS(self.srcPlace.coordinate.longitude - self.destPlace.coordinate.longitude)
                    );
        
        CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(
                    (self.srcPlace.coordinate.latitude + self.destPlace.coordinate.latitude)/2.0,
                    (self.srcPlace.coordinate.longitude + self.destPlace.coordinate.longitude)/2.0
                    );
        MKCoordinateRegion region = MKCoordinateRegionMake(coord, span);
        */
        
        MKCoordinateRegion r1 = MKCoordinateRegionMakeWithDistance(self.srcPlace.coordinate, 1000, 1000);
        MKCoordinateRegion r2 = MKCoordinateRegionMakeWithDistance(self.destPlace.coordinate, 1000, 1000);
        MKCoordinateRegion region = MKCoordinateRegionForMapRect(MKMapRectUnion(MKMapRectFromCoordinateRegion(r1), MKMapRectFromCoordinateRegion(r2)));

        
        MKCoordinateRegion hopefulRegion = [self.mapView regionThatFits:region];
        [self.mapView setRegion:hopefulRegion animated:YES];
    }

    

}

- (void)switchToSelectionMode
{
    self.nextButton.hidden = NO;
    self.uberButton.hidden = YES;
}

- (void)uberIt
{
    [self requestUber];
}

- (void)updateVisibleAnnotations
{
    [self.mapView removeAnnotation:self.srcPlace];
    [self.mapView removeAnnotation:self.destPlace];
    
    NSMutableArray *annotations = [NSMutableArray new];
    
    // In animating mode or if we are in the re view mode,
    // we show both placeholders if available
    
    if (self.locationSelectionMode == UHLocationSelectionModeNone || self.selectionState == UHSelectionStateAnimating) {
        if (self.srcPlace.place && self.destPlace.place) {
            [annotations addObject:self.destPlace];
            [annotations addObject:self.srcPlace];
        }
        self.pin.hidden = YES;
    }
    else
    if (self.locationSelectionMode == UHLocationSelectionModeSource) {
        if (self.destPlace.place) {
            [annotations addObject:self.destPlace];
        }
        self.pin.hidden = NO;
    }
    else
    if (self.locationSelectionMode == UHLocationSelectionModeDestination) {
        if (self.srcPlace.place) {
            [annotations addObject:self.srcPlace];
        }
        self.pin.hidden = NO;
    }
    

    
    [self.mapView addAnnotations:annotations];

}

#pragma mark - Lazy getters

-(UHLocationPin *)srcPlace
{
    if (!_srcPlace) {
        _srcPlace = [[UHLocationPin alloc] init];
    }
    return _srcPlace;
}

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
        self.locationSelectionMode = UHLocationSelectionModeDestination;
        [self updateAppropriateLocationLabels:@[ place ] forRequestCoord:kCLLocationCoordinate2DInvalid];
        [self setUnderPinLat:place.coordinate.latitude andLon:place.coordinate.longitude];
    }
}


#pragma mark - Uber It

- (void)requestUber
{
    UHUberHelper *uber = [[UHUberHelper alloc] init];
    uber.source = self.srcPlace.coordinate;
    uber.sourceName = self.srcPlace.place.name;
    uber.destination = self.destPlace.coordinate;
    uber.destinationName = self.destPlace.place.name;
    
    [uber request];
}

@end

