/*
 * Copyright (c) 2013 Plausible Labs Cooperative, Inc.
 * All rights reserved.
 */

#import <Foundation/Foundation.h>

@interface PLClangVersion : NSObject

/**
 * The major version number, for example the 10 in 10.7.3.
 */
@property(nonatomic, readonly) int major;

/**
 * The minor version number, for example the 7 in 10.7.3.
 *
 * The value of this property will be -1 if no minor version number was provided.
 */
@property(nonatomic, readonly) int minor;

/**
 * The patch version number, for example the 3 in 10.7.3.
 *
 * The value of this property will be -1 if no patch version number was provided.
 */
@property(nonatomic, readonly) int patch;

@end
