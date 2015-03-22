//
//  UIApplication+NetworkActivity.h
//  GDIDataController
//
//  Created by Grant Davis on 2/22/15.
//  Copyright (c) 2015 Grant Davis Interactive, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIApplication (GDINetworkActivity)

+ (void)incrementNetworkActivityCount;
+ (void)decrementNetworkActivityCount;

@end
