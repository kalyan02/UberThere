//
//  UHSearchDestinationViewController.m
//  UberTest
//
//  Created by Kalyan on 09/04/16.
//  Copyright (c) 2016 Kalyan. All rights reserved.
//

#import "UHSearchDestinationViewController.h"
#import "UHLocationManager.h"

@import MapKit;

@interface UHSearchDestinationViewController () <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) BOOL constraintsInstalled;

@property (nonatomic, strong) NSArray *searchResults;
@property (nonatomic, strong) MKLocalSearch *localSearch;
@property (nonatomic, strong) MKLocalSearchResponse *searchResponse;;

@property (nonatomic, strong) NSLayoutConstraint *tableBottomConstraint;
@end

@implementation UHSearchDestinationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"Search Destination";
    
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"Search";
    self.searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.searchBar];
    
    self.tableView = [[UITableView alloc] init];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleDone target:self action:@selector(close:)];
    self.navigationItem.leftBarButtonItem.tintColor = [UIColor whiteColor];
    
    [self.view setNeedsUpdateConstraints];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:self.view.window];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:self.view.window];
    
    // Do any additional setup after loading the view.
}

- (void)keyboardWillShow:(NSNotification *)note
{
    NSDictionary *userInfo = [note userInfo];
    CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    self.tableBottomConstraint.constant = -keyboardSize.height;
    
    [self.view updateConstraintsIfNeeded];
}

- (void)keyboardWillHide:(NSNotification *)note
{
    //    NSDictionary *userInfo = [note userInfo];
    //    CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    self.tableBottomConstraint.constant = 0;
    
    [self.view updateConstraintsIfNeeded];
}


- (void)updateViewConstraints
{
    if (!_constraintsInstalled) {
        _constraintsInstalled = YES;
        
        NSDictionary *views = NSDictionaryOfVariableBindings(_searchBar, _tableView);
        NSDictionary *metrics = nil;
        
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_tableView]|" options:0 metrics:metrics views:views]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_searchBar]|" options:0 metrics:metrics views:views]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_searchBar][_tableView]" options:0 metrics:metrics views:views]];
        self.tableBottomConstraint = [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
        [self.view addConstraint:self.tableBottomConstraint];
    }
    
    [super updateViewConstraints];
}

#pragma mark - search bar delegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    MKLocalSearchRequest *searchRequest = [[MKLocalSearchRequest alloc] init];
    searchRequest.naturalLanguageQuery = searchText;
    
    /*
    if ([UHLocationManager authorized]) {
        CLLocation *loc = [[UHLocationManager sharedInstance] recentLocation];
        if (loc) {
            searchRequest.region = [MKCoordinateRegionMakeWithDistance(<#CLLocationCoordinate2D centerCoordinate#>, <#CLLocationDistance latitudinalMeters#>, <#CLLocationDistance longitudinalMeters#>)
        }
        
    }
     */
    
    if (self.localSearch) {
        [self.localSearch cancel];
    }
    
    __weak typeof(self) weakSelf = self;
    self.localSearch = [[MKLocalSearch alloc] initWithRequest:searchRequest];
    [self.localSearch startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
        weakSelf.searchResponse = response;
        [weakSelf reloadData];
    }];
}

- (void)reloadData
{
    [self.tableView reloadData];
}

#pragma mark - Search

- (void)handleSearchResponse:(MKLocalSearchResponse *)response
{
    
}

#pragma mark - table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.searchResponse.mapItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:@"cell"];
    }
    
    MKMapItem *item = [self.searchResponse.mapItems objectAtIndex:indexPath.row];
    cell.textLabel.text = item.name;
    
    NSMutableArray *details = [NSMutableArray new];
    if (item.placemark.subLocality) {
        [details addObject:item.placemark.subLocality];
    }
    if (item.placemark.locality) {
        [details addObject:item.placemark.locality];
    }
    
    cell.detailTextLabel.text = [details componentsJoinedByString:@", "];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MKMapItem *item = [self.searchResponse.mapItems objectAtIndex:indexPath.row];
    if (item && self.delegate && [self.delegate respondsToSelector:@selector(searchDestinationViewControllerDidReturn:)]) {
        [self.delegate searchDestinationViewControllerDidReturn:item.placemark];
    }
}

- (void)close:(id)sender
{
    [self.delegate searchDestinationViewControllerDidReturn:nil];
}

@end
