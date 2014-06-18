/*
 * Copyright (c) 2013 Plausible Labs Cooperative, Inc.
 * All rights reserved.
 */

#import <Foundation/Foundation.h>

@interface PLClangUnsavedFile : NSObject

+ (instancetype) unsavedFileWithPath: (NSString *) path data: (NSData *) data;

/**
 * The path where the file is expected to be stored on disk.
 */
@property(nonatomic, readonly) NSString *path;

/**
 * The file's data.
 */
@property(nonatomic, readonly) NSData *data;

@end
