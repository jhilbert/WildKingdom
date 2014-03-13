//
//  FlickrPhoto.m
//  Flickr Search
//
//  Based on version of Brandon Trebitowski on 6/28/12.
//  Created by Josef Hilbert on 23.01.14.
//  Copyright (c) 2014 Josef Hilbert. All rights reserved.
//

#import "FlickrPhoto.h"

@implementation FlickrPhoto

- (double)imageRatio
{
    if (self.thumbnail == nil)
        return 1;
    else
        return self.thumbnail.size.width /  self.thumbnail.size.height;
}

@end
