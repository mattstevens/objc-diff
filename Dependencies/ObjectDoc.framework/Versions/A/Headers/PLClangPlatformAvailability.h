/*
 * Copyright (c) 2013 Plausible Labs Cooperative, Inc.
 * All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "PLClangVersion.h"

@interface PLClangPlatformAvailability : NSObject

/**
 * The name of the platform.
 *
 * Possible values are "ios" and "macosx".
 */
@property(nonatomic, readonly) NSString *platformName;

/**
 * The version in which the entity was introduced.
 */
@property(nonatomic, readonly) PLClangVersion *introducedVersion;

/**
 * The version in which the entity was deprecated (but is still available).
 */
@property(nonatomic, readonly) PLClangVersion *deprecatedVersion;

/**
 * The version in which the entity was obsoleted, and therefore is no longer available.
 */
@property(nonatomic, readonly) PLClangVersion *obsoletedVersion;

/**
 * An optional message to provide to a user of a deprecated or obsoleted entity, possibly to suggest replacement APIs.
 */
@property(nonatomic, copy) NSString *message;

/**
 * Optional message text that Clang will use to provide Fix-It when emitting a warning about use of a deprecated declaration.
 */
@property(nonatomic, copy) NSString *replacement;

@end
