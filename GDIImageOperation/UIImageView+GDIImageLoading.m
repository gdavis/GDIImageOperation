//
//  UIImageView+ImageLoading.m
//  GDIDataController
//
//  Created by Grant Davis on 2/21/15.
//  Copyright (c) 2015 Grant Davis Interactive, LLC. All rights reserved.
//

#import "UIImageView+GDIImageLoading.h"
#import "GDIImageOperation.h"


@implementation UIImageView (GDIImageLoading)


#pragma mark - Class Methods
#pragma mark Operations


+ (void)addOperation:(GDIImageOperation *)operation imageView:(UIImageView *)imageView
{
    GDIImageOperation *activeOperation = [self imageOperationForImageView:imageView];
    if (activeOperation != nil) {
        [activeOperation cancel];
    }
    
    [[self activeOperations] setObject:operation forKey:[imageView address]];
    [[self imageOperationQueue] addOperation:operation];
}


+ (void)removeOperationForImageView:(UIImageView *)imageView
{
    [[self activeOperations] removeObjectForKey:[imageView address]];
}


+ (GDIImageOperation *)imageOperationForImageView:(UIImageView *)imageView
{
    return [[self activeOperations] objectForKey:[imageView address]];
}


+ (NSMutableDictionary *)activeOperations
{
    static NSMutableDictionary *activeOperations;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        activeOperations = [NSMutableDictionary dictionary];
    });
    return activeOperations;
}


+ (NSOperationQueue *)imageOperationQueue
{
    static NSOperationQueue *imageOperationQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imageOperationQueue = [[NSOperationQueue alloc] init];
        imageOperationQueue.name = @"com.grantdavisinteractive.imageOperationQueue";
    });
    return imageOperationQueue;
}


#pragma mark URLSession


+ (NSURLSession *)sessionForImageView:(UIImageView *)imageView
{
    return [[self imageViewURLSessions] objectForKey:[imageView address]];
}


+ (void)setURLSession:(NSURLSession *)session imageView:(UIImageView *)imageView
{
    [[self imageViewURLSessions] setObject:session forKey:[imageView address]];
}


+ (void)removeURLSessionForImageView:(UIImageView *)imageView
{
    [[self imageViewURLSessions] removeObjectForKey:[imageView address]];
}


+ (NSMutableDictionary *)imageViewURLSessions
{
    static NSMutableDictionary *imageViewURLSessions;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imageViewURLSessions = [NSMutableDictionary dictionary];
    });
    return imageViewURLSessions;
}


#pragma mark - Instance Methods


- (void)dealloc
{
    [[self class] removeURLSessionForImageView:self];
    
    GDIImageOperation *imageOperation = [[self class] imageOperationForImageView:self];
    if (imageOperation != nil) {
        [[self class] removeOperationForImageView:self];
        [imageOperation cancel];
    }
}


- (NSNumber *)address
{
    return @((int)self);
}


#pragma mark - Public


- (void)setURLSession:(NSURLSession *)URLSession
{
    [[self class] setURLSession:URLSession imageView:self];
}


- (void)setImageWithURL:(NSURL *)URL
{
    [self setImageWithURL:URL completion:nil];
}


- (void)setImageWithURL:(NSURL *)URL completion:(UIImageViewCompletionBlock)completion
{
    GDIImageOperation *imageOperation = [[GDIImageOperation alloc] initWithImageURL:URL];
    
    NSURLSession *session = [[self class] sessionForImageView:self];
    if (session != nil) {
        imageOperation.URLSession = session;
    }
    
    NSString *savePath = [GDIImageOperation savePathForURL:URL];
    UIImage *cachedImage = [[GDIImageOperation imageCache] objectForKey:savePath];
    
    if (cachedImage != nil) {
        self.image = cachedImage;
    }
    
    __weak typeof(self) weakSelf = self;
    __weak typeof(imageOperation) weakOperation = imageOperation;
    
    imageOperation.completionBlock = ^(void) {
        
        if (weakOperation.isCancelled) {
            return;
        }
        
        __strong typeof (weakOperation) strongOperation = weakOperation;
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (weakSelf == nil) {
                return;
            }
            
            [[weakSelf class] removeOperationForImageView:weakSelf];
            
            if (strongOperation.isCancelled == NO) {
                weakSelf.image = strongOperation.image;
                
                if (completion != nil) {
                    completion(strongOperation.image, strongOperation.error);
                }
            }
        });
    };
    
    [[self class] addOperation:imageOperation imageView:self];
}


- (void)cancelImageLoad
{
    GDIImageOperation *operation = [[self class] imageOperationForImageView:self];
    if (operation != nil) {
        [operation cancel];
        [[self class] removeOperationForImageView:self];
    }
}


+ (void)cancelAllImageLoads
{
    NSOperationQueue *operationQueue = [self imageOperationQueue];
    [operationQueue cancelAllOperations];
}


@end
