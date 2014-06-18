/*
 * Copyright (c) 2013 Plausible Labs Cooperative, Inc.
 * All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "PLClangSourceLocation.h"

@interface PLClangSourceRange : NSObject

- (instancetype) initWithStartLocation: (PLClangSourceLocation *) startLocation
                           endLocation: (PLClangSourceLocation *) endLocation;

/**
 * The start location of this source range.
 */
@property(nonatomic, readonly) PLClangSourceLocation *startLocation;

/**
 * The end location of the this range.
 */
@property(nonatomic, readonly) PLClangSourceLocation *endLocation;

@end
