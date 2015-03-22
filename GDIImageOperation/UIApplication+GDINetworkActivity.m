//
//  UIApplication+NetworkActivity.m
//  GDIDataController
//
//  Created by Grant Davis on 2/22/15.
//  Copyright (c) 2015 Grant Davis Interactive, LLC. All rights reserved.
//

#import "UIApplication+GDINetworkActivity.h"


NSUInteger * UIApplicationNetworkActivityCount = 0;


@implementation UIApplication (GDINetworkActivity)

+ (void)incrementNetworkActivityCount
{
    UIApplicationNetworkActivityCount++;
    [self updateIndicator];
}


+ (void)decrementNetworkActivityCount
{
    UIApplicationNetworkActivityCount--;
    [self updateIndicator];
}


+ (void)updateIndicator
{
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL isIndicatorVisible = UIApplicationNetworkActivityCount > 0;
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:isIndicatorVisible];
    });
}

@end
