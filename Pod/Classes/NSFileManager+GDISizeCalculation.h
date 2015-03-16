//
//  NSFileManager+SizeCalculation.h
//  ChampionArchitect
//
//  Created by Grant Davis on 3/3/15.
//  Copyright (c) 2015 Gravity Core Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^NSFileManagerCalculateSizeBlock)(NSInteger numberOfFiles, NSInteger bytes);

@interface NSFileManager (SizeCalculation)

+ (void)calculateSizeOfContentsOfDirectoryAtPath:(NSString *)path completion:(NSFileManagerCalculateSizeBlock)completionBlock;

@end
