/*
 * Copyright (c) 2013 Plausible Labs Cooperative, Inc.
 * All rights reserved.
 */

#import <Foundation/Foundation.h>

extern NSString * const PLClangErrorDomain;

/**
 * Error codes in the PLClangErrorDomain.
 */
typedef NS_ENUM(NSInteger, PLClangErrorCode) {
    /**
     * An unknown error occurred.
     *
     * If this error code is received it is a bug and should be reported.
     */
    PLClangErrorUnknown = 0,

    /**
     * An unrecoverable compiler error occurred.
     */
    PLClangErrorCompiler = 1,

    /**
     * Indicates that an error occurred while writing a translation unit to disk.
     */
    PLClangErrorSaveFailed = 2,

    /**
     * Indicates that the specified translation unit was invalid.
     */
    PLClangErrorInvalidTranslationUnit = 3
};

#import "PLClangSourceIndex.h"

FOUNDATION_EXPORT NSString *PLClangGetVersionString(void);
