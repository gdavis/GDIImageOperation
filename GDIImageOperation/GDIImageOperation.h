//
//  GDIImageOperation.h
//
//  Created by Grant Davis on 2/21/15.
//  Copyright (c) 2015 Grant Davis Interactive, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "GDIOperation.h"

extern NSString * const GDIImageOperationCacheDirectorySizeCalculatedNotification;
extern NSString * const GDIImageOperationNetworkRequestDidStartNotification;
extern NSString * const GDIImageOperationNetworkRequestDidFinishNotification;

@interface GDIImageOperation : GDIOperation

@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) NSURL *imageURL;
@property (strong, nonatomic) NSError *error;
@property (strong, nonatomic) NSCache *memoryCache;
@property (strong, nonatomic) NSURLSession *URLSession;

- (instancetype)initWithImageURL:(NSURL *)imageURL;

+ (NSString *)savePathForURL:(NSURL *)URL;
+ (BOOL)clearCacheForImageURL:(NSURL *)imageURL;
+ (NSCache *)imageCache;
+ (NSString *)imageCacheDirectory;
+ (void)setImageCacheDirectoryWithPath:(NSString *)directoryPath;

+ (BOOL)isCalculatingDiskSize;
+ (BOOL)hasCalculatedDiskSize;
+ (void)updateDiskCacheSize;
+ (NSInteger)numberOfFilesInCache;
+ (NSInteger)diskCacheSize;
+ (NSInteger)diskCacheSizeLimit;
+ (NSInteger)memoryCacheSizeLimit;
+ (void)setDiskCacheSizeLimit:(NSInteger)bytes;
+ (void)setMemoryCacheSizeLimit:(NSInteger)bytes;

@end
