//
//  ViewController.m
//  WildKingdom
//
//  Created by Josef Hilbert on 23.01.14.
//  Copyright (c) 2014 Josef Hilbert. All rights reserved.
//

#import "ViewController.h"
#import "MapWithPhotoViewController.h"
#import "FlickrPhotoCell.h"
#import "Flickr.h"
#import "FlickrPhoto.h"

@interface ViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITabBarControllerDelegate, UITabBarDelegate, UIApplicationDelegate>
{
    __weak IBOutlet UICollectionView *collectionView;
    
    NSArray *flickrPhotos;
    FlickrPhoto *flickrPhoto;
    FlickrPhotoCell *selectedFlickrPhotoCell;
    UICollectionViewFlowLayout *flowLayoutPortrait;
    UICollectionViewFlowLayout *flowLayoutLandscape;
    
    double heightRatio;
    float totalWidth;
    int cellGroupOffset;
}
@property(nonatomic, strong) Flickr *flickr;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // use cellGroupOffset to check how many images can be displayed in one row based on total witdh
    cellGroupOffset = 0;
    
    self.flickr = [[Flickr alloc] init];
    
    // default search is lion
    _searchString = @"lions";
    [self getFlickrImages];
    
    selectedFlickrPhotoCell = [[FlickrPhotoCell alloc] init];
    
    flowLayoutPortrait = [[UICollectionViewFlowLayout alloc] init];
    [flowLayoutPortrait setScrollDirection:UICollectionViewScrollDirectionVertical];
    flowLayoutPortrait.minimumLineSpacing = 0;
    flowLayoutPortrait.minimumInteritemSpacing=0;
    flowLayoutLandscape = [[UICollectionViewFlowLayout alloc] init];
    flowLayoutLandscape.minimumLineSpacing = 0;
    flowLayoutLandscape.minimumInteritemSpacing=0;
    [flowLayoutLandscape setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    
    [collectionView setCollectionViewLayout:flowLayoutPortrait animated:YES];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (IBAction)onInfoBarPressed:(id)sender {
    selectedFlickrPhotoCell.imageView.alpha = 0.5;
    [self removeOverlayImage:selectedFlickrPhotoCell];
}

- (void)getFlickrImages
{
    [self.flickr searchFlickrForTerm:_searchString completionBlock:^(NSString *searchTerm, NSArray *results, NSError *error) {
        if(results && [results count] > 0)
        {
            NSLog(@"Found %d photos matching %@",[results count],searchTerm);
            flickrPhotos = results;
            dispatch_async(dispatch_get_main_queue(), ^{
                [collectionView reloadData];
            });
            
        } else {
            NSLog(@"Error searching Flickr: %@", error.localizedDescription);
        }
    }];
}

-(void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    _searchString = @"";
    _searchString = item.title;
    [self getFlickrImages];
    
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    FlickrPhotoCell *photoCell = [cv dequeueReusableCellWithReuseIdentifier:@"FlickrCell" forIndexPath:indexPath];
    [self removeOverlayImage:photoCell];
    photoCell.imageView.alpha = 1.0;
    photoCell.photo = flickrPhotos[indexPath.row];
    //   photoCell.selectedBackgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"PinballBackground"]];
    return photoCell;
}


-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return flickrPhotos.count;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation))
    {
        [collectionView setCollectionViewLayout:flowLayoutLandscape animated:YES];
        [(UICollectionViewFlowLayout*)collectionView.collectionViewLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    }
    else
    {
        [collectionView setCollectionViewLayout:flowLayoutPortrait animated:YES];
        [(UICollectionViewFlowLayout*)collectionView.collectionViewLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    }
    [collectionView reloadData];
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)cv didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"did select");
    FlickrPhotoCell *cell = ((FlickrPhotoCell*)[collectionView cellForItemAtIndexPath:indexPath]);
    
    // UNDER CONSTRUCTION how to flip images
    //    UIImageView *flipView = (UIImageView*)[cell.imageView viewWithTag:100];
    //    if (!(flipView == nil))
    //    {
    //        [flipView removeFromSuperview];
    //    }
    //    else
    //    {
    if (cell.photo.photoInfo == nil)
    {
        [Flickr loadInfoForPhoto:((FlickrPhotoCell*)[collectionView cellForItemAtIndexPath:indexPath]).photo completionBlock:^(FlickrPhoto *photo, NSDictionary *photoInfo, NSError *error) {
            if(!error)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    //                       cell.imageView.frame = CGRectMake(cell.imageView.frame.size.width-50, cell.imageView.frame.size.height-50, 50, 50);
                    
                    cell.selectedBackgroundView = photo.infoView;
                    [self overlayImage:cell];
                });
            }
        }];
    }
    else
    {
        [self overlayImage:cell];
    }
    //    }
    //    cell.imageView.alpha = 0.5;
    selectedFlickrPhotoCell = cell;
}

- (void)collectionView:(UICollectionView *)cv didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"did deselect");
    FlickrPhotoCell *cell = ((FlickrPhotoCell*)[cv cellForItemAtIndexPath:indexPath]);
    cell.imageView.alpha = 1.0;
    [self removeOverlayImage:cell];
}

#pragma mark – UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)cv layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    flickrPhoto = flickrPhotos[indexPath.row];
    
    if (cellGroupOffset == 0)
    {
        heightRatio = 0;
        totalWidth = 0;
        while ((heightRatio < 2) && (cellGroupOffset + indexPath.row) < flickrPhotos.count) {
            FlickrPhoto *nextPhoto = flickrPhotos[indexPath.row + cellGroupOffset];
            totalWidth += nextPhoto.thumbnail.size.width * (150 / nextPhoto.thumbnail.size.height);
            heightRatio += nextPhoto.imageRatio;
            NSLog(@"i = %i ... i + IP: %d  ... count %i ... total Width: %f, ratio %f", cellGroupOffset, cellGroupOffset + indexPath.row, flickrPhotos.count, totalWidth, heightRatio);
            cellGroupOffset++;
        }
    }
    cellGroupOffset--;
    
    CGSize retval;
    float collectionViewWidth = cv.frame.size.width;
    float sizeFactor = totalWidth / (collectionViewWidth-1);
    
    if ([collectionViewLayout isEqual:flowLayoutLandscape])
    {
        retval = CGSizeMake(flickrPhoto.thumbnail.size.width * 200 / flickrPhoto.thumbnail.size.height, 200);
    }
    else
    {
        retval = CGSizeMake(flickrPhoto.thumbnail.size.width * (150 / flickrPhoto.thumbnail.size.height) / sizeFactor, flickrPhoto.thumbnail.size.height * (150 / flickrPhoto.thumbnail.size.height) / sizeFactor);
    }
    
    NSLog(@"x %f y %f   .... pic x %f y %f",retval.width, retval.height, flickrPhoto.thumbnail.size.width, flickrPhoto.thumbnail.size.height);
    
    return retval;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

//TESTING ONLY if-when this happens
- (UICollectionViewLayoutAttributes*)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    NSLog(@"disappear index %i", itemIndexPath.row);
    UICollectionViewLayoutAttributes *attributes = [flowLayoutPortrait finalLayoutAttributesForDisappearingItemAtIndexPath:itemIndexPath];
    return attributes;
}

-(void)overlayImage:(FlickrPhotoCell*)cell
{
    UIImageView *overlayView = (UIImageView*)[cell.imageView viewWithTag:100];
    if (overlayView == nil)
    {
        UILabel *overlay = [[UILabel alloc] initWithFrame:CGRectMake(0, cell.imageView.frame.size.height/4*3, cell.imageView.frame.size.width, cell.imageView.frame.size.height / 4)];
        [overlay setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.4]];
        overlay.tag = 100;
        overlay.text = cell.photo.photoInfo[@"dates"][@"taken"];
        overlay.font =[UIFont fontWithName:@"ArialRoundedMTBold" size:16];
        overlay.textColor = [UIColor whiteColor];
        NSLog(@"+overlay");
        [cell.imageView addSubview:overlay];
    }
}

-(void)removeOverlayImage:(FlickrPhotoCell*)cell
{
    UIImageView *overlayView = (UIImageView*)[cell.imageView viewWithTag:100];
    if (!(overlayView == nil))
    {
        NSLog(@"-overlay");
        [overlayView removeFromSuperview];
    }
}

-(void)removeFlipImage:(FlickrPhotoCell*)cell
{
    UIImageView *flipView = (UIImageView*)[cell.imageView viewWithTag:200];
    if (!(flipView == nil))
    {
        NSLog(@"-overlay");
        [flipView removeFromSuperview];
    }
}




-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
    
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"MapSegID"])
    {
        MapWithPhotoViewController *vc = segue.destinationViewController;
        vc.flickrPhoto = selectedFlickrPhotoCell.photo;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
