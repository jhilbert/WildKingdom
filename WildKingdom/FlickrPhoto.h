//
//  FlickrPhoto.h
//  Flickr Search
//
//  Based on version of Brandon Trebitowski on 6/28/12.
//  Created by Josef Hilbert on 23.01.14.
//  Copyright (c) 2014 Josef Hilbert. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FlickrPhoto : NSObject
@property(nonatomic,strong) UIImage *thumbnail;
@property(nonatomic,strong) UIImage *largeImage;
@property(nonatomic,strong) UILabel *infoView;
@property(nonatomic,strong) NSDictionary *photoInfo;

// Lookup info
@property(nonatomic) long long photoID;
@property(nonatomic) NSInteger farm;
@property(nonatomic) NSInteger server;
@property(nonatomic,strong) NSString *secret;
@property(nonatomic) double imageRatio;

@end
