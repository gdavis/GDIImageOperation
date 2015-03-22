//
//  NSFileManager+SizeCalculation.m
//  ChampionArchitect
//
//  Created by Grant Davis on 3/3/15.
//  Copyright (c) 2015 Gravity Core Apps, LLC. All rights reserved.
//

#import "NSFileManager+GDISizeCalculation.h"

@implementation NSFileManager (SizeCalculation)

+ (void)calculateSizeOfContentsOfDirectoryAtPath:(NSString *)path completion:(NSFileManagerCalculateSizeBlock)completionBlock
{
    NSParameterAssert(path);
    NSParameterAssert(completionBlock);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *diskCacheURL = [NSURL fileURLWithPath:path isDirectory:YES];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0ul), ^{
        NSUInteger fileCount = 0;
        NSUInteger totalSize = 0;
        
        NSDirectoryEnumerator *fileEnumerator = [fileManager enumeratorAtURL:diskCacheURL
                                                  includingPropertiesForKeys:@[NSFileSize]
                                                                     options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                errorHandler:NULL];
        
        for (NSURL *fileURL in fileEnumerator) {
            NSNumber *fileSize;
            [fileURL getResourceValue:&fileSize forKey:NSURLFileSizeKey error:NULL];
            totalSize += [fileSize unsignedIntegerValue];
            fileCount += 1;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(fileCount, totalSize);
        });
    });
}

@end
