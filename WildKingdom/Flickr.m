//
//  Flickr.m
//  Flickr Search
//
//  Based on version of Brandon Trebitowski on 6/28/12.
//  Created by Josef Hilbert on 23.01.14.
//  Copyright (c) 2014 Josef Hilbert. All rights reserved.

//

#import "Flickr.h"
#import "FlickrPhoto.h"

// Josefs API KEY!
#define kFlickrAPIKey @"12b21e49e93ed585d6e2bd20bea9f41a"

@implementation Flickr

+ (NSString *)flickrSearchURLForSearchTerm:(NSString *) searchTerm
{
    searchTerm = [searchTerm stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [NSString stringWithFormat:@"http://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=%@&text=%@&per_page=20&license=Attribution-NonCommercial+License&sort=relevance&has_geo=YES&format=json&nojsoncallback=1",kFlickrAPIKey,searchTerm];
}

+ (NSString *)flickrPhotoURLForFlickrPhoto:(FlickrPhoto *) flickrPhoto size:(NSString *) size
{
    if(!size)
    {
        size = @"m";
    }
    return [NSString stringWithFormat:@"http://farm%d.staticflickr.com/%d/%lld_%@_%@.jpg",flickrPhoto.farm,flickrPhoto.server,flickrPhoto.photoID,flickrPhoto.secret,size];
}

- (void)searchFlickrForTerm:(NSString *) term completionBlock:(FlickrSearchCompletionBlock) completionBlock
{
    NSString *searchURL = [Flickr flickrSearchURLForSearchTerm:term];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(queue, ^{
        NSError *error = nil;
        NSString *searchResultString = [NSString stringWithContentsOfURL:[NSURL URLWithString:searchURL]
                                                                encoding:NSUTF8StringEncoding
                                                                   error:&error];
        if (error != nil) {
            completionBlock(term,nil,error);
        }
        else
        {
            // Parse the JSON Response
            NSData *jsonData = [searchResultString dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *searchResultsDict = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                              options:kNilOptions
                                                                                error:&error];
            if(error != nil)
            {
                completionBlock(term,nil,error);
            }
            else
            {
                NSString * status = searchResultsDict[@"stat"];
                if ([status isEqualToString:@"fail"]) {
                    NSError * error = [[NSError alloc] initWithDomain:@"FlickrSearch" code:0 userInfo:@{NSLocalizedFailureReasonErrorKey: searchResultsDict[@"message"]}];
                    completionBlock(term, nil, error);
                } else {
                    
                    NSArray *objPhotos = searchResultsDict[@"photos"][@"photo"];
                    NSMutableArray *flickrPhotos = [@[] mutableCopy];
                    for(NSMutableDictionary *objPhoto in objPhotos)
                    {
                        FlickrPhoto *photo = [[FlickrPhoto alloc] init];
                        photo.farm = [objPhoto[@"farm"] intValue];
                        photo.server = [objPhoto[@"server"] intValue];
                        photo.secret = objPhoto[@"secret"];
                        photo.photoID = [objPhoto[@"id"] longLongValue];
                        
                        NSString *searchURL = [Flickr flickrPhotoURLForFlickrPhoto:photo size:@"m"];
                        NSLog(@"FOTO URL: %@", searchURL);
                        
                        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:searchURL]
                                                                  options:0
                                                                    error:&error];
                        UIImage *image = [UIImage imageWithData:imageData];
                        photo.thumbnail = image;
                        
                        [flickrPhotos addObject:photo];
                    }
                    
                    completionBlock(term,flickrPhotos,nil);
                }
            }
        }
    });
}

+ (void)loadImageForPhoto:(FlickrPhoto *)flickrPhoto thumbnail:(BOOL)thumbnail completionBlock:(FlickrPhotoCompletionBlock) completionBlock
{
    
    NSString *size = thumbnail ? @"m" : @"b";
    
    NSString *searchURL = [Flickr flickrPhotoURLForFlickrPhoto:flickrPhoto size:size];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(queue, ^{
        NSError *error = nil;
        
        NSData *imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:searchURL]
                                                  options:0
                                                    error:&error];
        if(error)
        {
            completionBlock(nil,error);
        }
        else
        {
            UIImage *image = [UIImage imageWithData:imageData];
            if([size isEqualToString:@"m"])
            {
                flickrPhoto.thumbnail = image;
            }
            else
            {
                flickrPhoto.largeImage = image;
            }
            completionBlock(image,nil);
        }
        
    });
}

+ (void)loadInfoForPhoto:(FlickrPhoto *)flickrPhoto completionBlock:(FlickrInfoCompletionBlock) completionBlock
{
    
    NSString *getInfoString = [NSString stringWithFormat:@"http://api.flickr.com/services/rest/?method=flickr.photos.getInfo&api_key=%@&photo_id=%lld&format=json&nojsoncallback=1",kFlickrAPIKey,flickrPhoto.photoID];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(queue, ^{
        NSError *error = nil;
        NSString *getInfoResultString = [NSString stringWithContentsOfURL:[NSURL URLWithString:getInfoString]
                                                                 encoding:NSUTF8StringEncoding
                                                                    error:&error];
        if (error != nil) {
            completionBlock(flickrPhoto,nil,error);
        }
        else
        {
            // Parse the JSON Response
            NSData *jsonData = [getInfoResultString dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *getInfoResultsDict = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                               options:kNilOptions
                                                                                 error:&error];
            if(error != nil)
            {
                completionBlock(flickrPhoto,nil,error);
            }
            else
            {
                NSString * status = getInfoResultsDict[@"stat"];
                if ([status isEqualToString:@"fail"]) {
                    NSError * error = [[NSError alloc] initWithDomain:@"FlickrGetInfo" code:0 userInfo:@{NSLocalizedFailureReasonErrorKey: getInfoResultsDict[@"message"]}];
                    completionBlock(flickrPhoto, nil, error);
                } else {
                    
                    flickrPhoto.photoInfo = getInfoResultsDict[@"photo"];
                    
                    UILabel *overlay = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, flickrPhoto.thumbnail.size.width, flickrPhoto.thumbnail.size.height)];
                    [overlay setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0]];
                    overlay.tag = 101;
                    overlay.text = [NSString stringWithFormat:@"Date: %@", flickrPhoto.photoInfo[@"dates"][@"taken"]];
                    overlay.text = [NSString stringWithFormat:@"%@\nCountry: %@", overlay.text, flickrPhoto.photoInfo[@"location"][@"country"][@"_content"]];
                    overlay.numberOfLines = 0;
                    overlay.lineBreakMode = NSLineBreakByWordWrapping;
                    overlay.font =[UIFont fontWithName:@"ArialRoundedMTBold" size:14];
                    overlay.textColor = [UIColor whiteColor];
                    
                    flickrPhoto.infoView = overlay;


                    NSLog(@"FOTO INFO found for PicID: %lld", flickrPhoto.photoID);
                }
                
                completionBlock(flickrPhoto,flickrPhoto.photoInfo, nil);
            }
        }
    });
}

@end
