//
//  FlickrPhotoCell.h
//  WildKingdom
//
//  Created by Josef Hilbert on 23.01.14.
//  Copyright (c) 2014 Josef Hilbert. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FlickrPhoto;

@interface FlickrPhotoCell : UICollectionViewCell
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) UILabel *infoView;
@property(nonatomic, strong) FlickrPhoto *photo;

@end
