//
//  UIImageView+ImageLoading.h
//  GDIDataController
//
//  Created by Grant Davis on 2/21/15.
//  Copyright (c) 2015 Grant Davis Interactive, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef void (^UIImageViewCompletionBlock)(UIImage *image, NSError *error);

@interface UIImageView (GDIImageLoading)

- (void)setImageWithURL:(NSURL *)URL;
- (void)setImageWithURL:(NSURL *)URL completion:(UIImageViewCompletionBlock)completion;
- (void)cancelImageLoad;
+ (void)cancelAllImageLoads;
- (void)setURLSession:(NSURLSession *)URLSession;

@end
