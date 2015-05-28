//
//  GDIImageOperation.m
//
//  Created by Grant Davis on 2/21/15.
//  Copyright (c) 2015 Grant Davis Interactive, LLC. All rights reserved.
//

#import "GDIImageOperation.h"
#import "NSFileManager+GDISizeCalculation.h"


#pragma mark - GDIImageOperation

NSString * const GDIImageOperationCacheDirectorySizeCalculatedNotification = @"GDIImageOperationCacheDirectorySizeCalculatedNotification";
NSString * const GDIImageOperationNetworkRequestDidStartNotification = @"GDIImageOperationNetworkRequestDidStartNotification";
NSString * const GDIImageOperationNetworkRequestDidFinishNotification = @"GDIImageOperationNetworkRequestDidFinishNotification";

static NSString * const GDIImageOperationSaveDirectory = @"GDIImageOperationCache";
static NSTimeInterval const GDIImageOperationExpirationDuration = 12.0 * 60.0 * 60.0;  // 12 hours
static NSInteger const GDIImageOperationMemoryBytesCacheLimit = 1024 * 1024 * 100;     // 100 MiB = (1024 bytes in a kilobyte x 100) http://stackoverflow.com/questions/2365100/converting-bytes-to-megabytes

static NSInteger _memoryCacheSizeLimit = GDIImageOperationMemoryBytesCacheLimit;
static NSInteger _diskCacheSizeLimit = 0;
static NSInteger _diskCacheSize = 0;
static NSInteger _numberOfFilesInCache = 0;
static BOOL _hasCalculatedCacheSize = NO;
static BOOL _isCalculatingCacheSize = NO;


@interface GDIImageOperation ()

@property (strong, nonatomic) NSURLSessionDataTask *dataTask;

@end


@implementation GDIImageOperation


#pragma mark - Instance Methods


- (instancetype)initWithImageURL:(NSURL *)imageURL
{
    self = [super init];
    if (self) {
        self.imageURL = imageURL;
    }
    return self;
}


- (BOOL)isAsynchronous
{
    return YES;
}


- (void)start
{
    if (self.isCancelled) {
        self.executing = NO;
        self.finished = YES;
        return;
    }
    
    self.executing = YES;
    self.finished = NO;
    
    NSString *savePath = [[self class] savePathForURL:self.imageURL];
    
    if ([self hasImageExpiredOnDiskAtPath:savePath] == NO) {
        
        UIImage *cachedImage = [self imageFromCacheAtPath:savePath];
        
        if (self.isCancelled == NO) {
            self.image = cachedImage;
        }
        
        self.executing = NO;
        self.finished = YES;
    }
    else {
        [self requestImageFromNetwork];
    }
}


- (UIImage *)imageFromCacheAtPath:(NSString *)savePath
{
    UIImage *cachedImage = [[self memoryCache] objectForKey:savePath];
    UIImage *image;
    
    if (cachedImage != nil) {
        image = cachedImage;
    }
    else {
        image = [self imageFromDiskAtPath:savePath];
        if (image != nil) {
            [self cacheImage:image key:savePath];
        }
    }
    
    return image;
}


- (void)cancel
{
    [super cancel];
    
    [self.dataTask cancel];
}


- (void)requestImageFromNetwork
{
    __weak typeof(self) weakSelf = self;
    NSURLSession *session = self.URLSession;
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:self.imageURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (weakSelf == nil) {
            return;
        }
        
        if (weakSelf.isCancelled) {
            weakSelf.executing = NO;
            weakSelf.finished = YES;
            [weakSelf postNetworkRequestDidFinish];
            return;
        }
        
        if (error == nil) {
            [weakSelf handleImageData:data];
        }
        else {
            [weakSelf handleError:error];
        }
        
        [weakSelf postNetworkRequestDidFinish];
    }];
    
    [dataTask resume];
    
    self.dataTask = dataTask;
    
    [self postNetworkRequestDidStart];
}


- (void)handleError:(NSError *)error
{
    self.error = error;
    
    if (self.isCancelled == NO) {
        
        NSString *savePath = [[self class] savePathForURL:self.imageURL];
        
        if ([self hasImageOnDiskAtPath:savePath]) {
            UIImage *cachedImage = [self imageFromCacheAtPath:savePath];
            self.image = cachedImage;
        }
    }
    
    self.executing = NO;
    self.finished = YES;
}


- (void)handleImageData:(NSData *)data
{
    if (data != nil && self.isCancelled == NO) {
        
        UIImage *image = [UIImage imageWithData:data];
        
        if (image != nil) {
            
            NSString *savePath = [[self class] savePathForURL:self.imageURL];
            
            if ([[self class] diskCacheSizeLimit] >= 0) {
                [self saveImageDataToDisk:data path:savePath];
            }
            
            if (self.isCancelled == NO) {
                [self cacheImage:image key:savePath];
                self.image = image;
            }
        }
    }
    
    self.executing = NO;
    self.finished = YES;
}


#pragma mark - Disk IO


- (BOOL)hasImageOnDiskAtPath:(NSString *)savePath
{
    return [[NSFileManager defaultManager] fileExistsAtPath:savePath];
}


- (BOOL)hasImageExpiredOnDiskAtPath:(NSString *)savePath
{
    if ([self hasImageOnDiskAtPath:savePath]) {
        
        NSError *error;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSDictionary *attributes = [fileManager attributesOfItemAtPath:savePath error:&error];
        NSDate *lastModifiedDate = [attributes objectForKey:NSFileModificationDate];
        NSDate *now = [NSDate date];
        
        if (lastModifiedDate != nil && [now timeIntervalSinceDate:lastModifiedDate] > GDIImageOperationExpirationDuration) {
            return YES;
        }
        return NO;
    }
    return YES;
}


- (UIImage *)imageFromDiskAtPath:(NSString *)path
{
    return [UIImage imageWithContentsOfFile:path];
}


- (void)saveImageDataToDisk:(NSData *)data path:(NSString *)path
{
    NSString *directoryPath = [path stringByDeletingLastPathComponent];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL directoryPathExists = [fileManager fileExistsAtPath:directoryPath];
    
    if (directoryPathExists == NO) {
        NSError *createDirectoriesError;
        directoryPathExists = [fileManager createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:&createDirectoriesError];
        if (directoryPathExists == NO) {
            NSLog(@"[GDIImageOperation] Error creating image directory: %@", createDirectoriesError);
        }
    }
    
    if (directoryPathExists) {
        NSDate *now = [NSDate date];
        NSDictionary *attributes = @{ NSFileModificationDate: now };
        [fileManager createFileAtPath:path contents:data attributes:attributes];
    }
}


- (void)cacheImage:(UIImage *)image key:(NSString *)key
{
    NSUInteger imageCost = CGImageGetHeight(image.CGImage) * CGImageGetBytesPerRow(image.CGImage);
    [[self memoryCache] setObject:image forKey:key cost:imageCost];
}


#pragma mark - Notifications


- (void)postNetworkRequestDidStart
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:GDIImageOperationNetworkRequestDidStartNotification object:self];
    });
}

- (void)postNetworkRequestDidFinish
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:GDIImageOperationNetworkRequestDidFinishNotification object:self];
    });
}


#pragma mark - Lazy Properties


- (NSURLSession *)URLSession
{
    if (_URLSession == nil) {
        return [[self class] imageURLSession];
    }
    return _URLSession;
}


- (NSCache *)memoryCache
{
    if (_memoryCache == nil) {
        return [[self class] imageCache];
    }
    return _memoryCache;
}


#pragma mark - Class "Properties"


+ (BOOL)isCalculatingDiskSize
{
    return _isCalculatingCacheSize;
}


+ (BOOL)hasCalculatedDiskSize
{
    return _hasCalculatedCacheSize;
}


+ (NSInteger)numberOfFilesInCache
{
    return _numberOfFilesInCache;
}


+ (NSInteger)diskCacheSize
{
    return _diskCacheSize;
}


+ (NSInteger)diskCacheSizeLimit
{
    return _diskCacheSizeLimit;
}


+ (void)setDiskCacheSizeLimit:(NSInteger)bytes
{
    _diskCacheSizeLimit = bytes;
    
    [self clearDiskCacheIfNecessary];
}


+ (NSInteger)memoryCacheSizeLimit
{
    return _memoryCacheSizeLimit;
}


+ (void)setMemoryCacheSizeLimit:(NSInteger)bytes
{
    _memoryCacheSizeLimit = bytes;
    
    [self imageCache].totalCostLimit = bytes;
}


#pragma mark - Class Methods


+ (void)clearDiskCacheIfNecessary
{
    if (_diskCacheSizeLimit > 0) {
        
        if (_diskCacheSize == 0) {
            [self updateDiskCacheSize];
            return;
        }
        
        if (_diskCacheSize >= [self diskCacheSizeLimit]) {
            [self clearDiskCache];
        }
    }
}


+ (void)clearDiskCache
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0ul), ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *savePath = [self savePathForURL:[NSURL new]];
        NSURL *saveURL = [NSURL URLWithString:savePath];
        NSArray *keys = @[NSURLNameKey, NSURLIsDirectoryKey, NSFileModificationDate, NSFileSize];
        NSDirectoryEnumerationOptions options = (NSDirectoryEnumerationSkipsHiddenFiles);
        NSDirectoryEnumerator *dirEnumerator = [fileManager enumeratorAtURL:saveURL
                                                 includingPropertiesForKeys:keys
                                                                    options:options
                                                               errorHandler:nil];
        
        for (NSURL *fileURL in dirEnumerator) {
            NSString *fileName;
            [fileURL getResourceValue:&fileName forKey:NSURLNameKey error:NULL];
            
            NSNumber *isDirectory;
            [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
            
            NSNumber *fileSize;
            [fileURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:NULL];
            
            if (_diskCacheSize > [self diskCacheSizeLimit] && [fileManager removeItemAtURL:fileURL error:NULL]) {
                _diskCacheSize -= [fileSize integerValue];
                _numberOfFilesInCache--;
                
                if (_diskCacheSize <= [self diskCacheSizeLimit]) {
                    break;
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:GDIImageOperationCacheDirectorySizeCalculatedNotification object:self];
        });
    });
}


+ (void)updateDiskCacheSize
{
    if (_isCalculatingCacheSize) {
        return;
    }
    
    _isCalculatingCacheSize = YES;
    
    __weak typeof(self) weakSelf = self;
    NSString *savePath = [self savePathForURL:[NSURL new]];
    [NSFileManager calculateSizeOfContentsOfDirectoryAtPath:savePath completion:^(NSInteger numberOfFiles, NSInteger bytes) {
        
        _numberOfFilesInCache = numberOfFiles;
        _diskCacheSize = bytes;
        _isCalculatingCacheSize = NO;
        _hasCalculatedCacheSize = YES;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:GDIImageOperationCacheDirectorySizeCalculatedNotification object:self];
        
        if (_diskCacheSize > 0) {
            [weakSelf clearDiskCacheIfNecessary];
        }
    }];
}


+ (BOOL)clearCacheForImageURL:(NSURL *)imageURL
{
    NSString *imagePath = [self savePathForURL:imageURL];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
        return [[NSFileManager defaultManager] removeItemAtPath:imagePath error:nil];
    }
    
    [[self imageCache] removeObjectForKey:imagePath];
    
    return NO;
}


+ (NSString *)savePathForURL:(NSURL *)URL
{
    NSString *savePath = [[self imageCacheDirectory] mutableCopy];
    NSString *host = URL.host;
    
    if (host.length > 0) {
        if (host.length > 32) {
            host = [host substringToIndex:32];
        }
        savePath = [savePath stringByAppendingPathComponent:host];
    }
    savePath = [savePath stringByAppendingPathComponent:URL.relativePath];
    return [savePath copy];
}


+ (NSString *)imageCacheDirectory
{
    static dispatch_once_t onceToken;
    static NSString *documentsPath;
    
    dispatch_once(&onceToken, ^{
        NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        documentsPath = [searchPaths lastObject];
        documentsPath = [documentsPath stringByAppendingPathComponent:GDIImageOperationSaveDirectory];
    });
    
    return documentsPath;
}


+ (NSURLSession *)imageURLSession
{
    static NSURLSession *imageURLSession;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.URLCache = nil;
        imageURLSession = [NSURLSession sessionWithConfiguration:configuration];
    });
    
    return imageURLSession;
}


+ (NSCache *)imageCache
{
    static NSCache *cache;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        cache = [[NSCache alloc] init];
        cache.totalCostLimit = [self memoryCacheSizeLimit];
    });
    
    return cache;
}


@end
