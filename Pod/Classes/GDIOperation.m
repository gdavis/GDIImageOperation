//
//  GDIOperation.m
//
//  Created by Grant Davis on 2/21/15.
//  Copyright (c) 2015 Grant Davis Interactive, LLC. All rights reserved.
//

#import "GDIOperation.h"

@implementation GDIOperation {
    BOOL _finished;
    BOOL _executing;
    BOOL _cancelled;
}


- (void)setFinished:(BOOL)finished
{
    [self willChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
    _finished = finished;
    [self didChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
}


- (void)setExecuting:(BOOL)executing
{
    [self willChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
    _executing = executing;
    [self didChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
}


- (void)setCancelled:(BOOL)cancelled
{
    [self willChangeValueForKey:NSStringFromSelector(@selector(isCancelled))];
    _cancelled = cancelled;
    [self didChangeValueForKey:NSStringFromSelector(@selector(isCancelled))];
}


- (BOOL)isExecuting
{
    return _executing;
}


- (BOOL)isFinished
{
    return _finished;
}


- (BOOL)isCancelled
{
    return _cancelled;
}


- (void)cancel
{
    self.cancelled = YES;
}

@end
