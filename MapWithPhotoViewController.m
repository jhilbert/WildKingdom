//
//  MapWithPhotoViewController.m
//  WildKingdom
//
//  Created by Josef Hilbert on 25.01.14.
//  Copyright (c) 2014 Josef Hilbert. All rights reserved.
//

#import "MapWithPhotoViewController.h"
#import <MapKit/MapKit.h>

@interface MapWithPhotoViewController () <MKMapViewDelegate>
{
    __weak IBOutlet MKMapView *mapView;
}

@end

@implementation MapWithPhotoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSString *title = _flickrPhoto.photoInfo[@"title"][@"_content"];
	self.navigationItem.title = title;

    float latitude = [_flickrPhoto.photoInfo[@"location"][@"latitude"] floatValue];
    float longitude = [_flickrPhoto.photoInfo[@"location"][@"longitude"] floatValue];
    NSLog (@"lat %f long %f",latitude, longitude);
    
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
    MKPointAnnotation *annotation = [MKPointAnnotation new];
    annotation.title = _flickrPhoto.photoInfo[@"title"][@"_content"];
    annotation.coordinate = coordinate;
    [mapView addAnnotation:annotation];
    MKCoordinateSpan span = MKCoordinateSpanMake(10.0, 10.0);
    MKCoordinateRegion region = MKCoordinateRegionMake(coordinate, span);
    [mapView setRegion:region animated:YES];
    
}

-(MKAnnotationView *)mapView:(MKMapView *)mV viewForAnnotation:(id<MKAnnotation>)annotation
{
    if(annotation == mapView.userLocation)
    {
        return nil;
    }
    MKAnnotationView *annotationView = [mV dequeueReusableAnnotationViewWithIdentifier:@"Photos"];
    if(annotationView ==nil)
    {
        annotationView = [[MKPinAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:@"Photos"];
    }
    else
    {
        annotationView.annotation = annotation;
    }
    annotationView.canShowCallout = YES;
    annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    return annotationView;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
