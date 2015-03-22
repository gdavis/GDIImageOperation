//
//  GDIOperation.h
//
//  Created by Grant Davis on 2/21/15.
//  Copyright (c) 2015 Grant Davis Interactive, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GDIOperation : NSOperation

- (void)setFinished:(BOOL)finished;
- (void)setExecuting:(BOOL)executing;
- (void)setCancelled:(BOOL)cancelled;

@end
