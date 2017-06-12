/*
 * Copyright (c) 2013 Plausible Labs Cooperative, Inc.
 * All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "PLClangPlatformAvailability.h"

/**
 * The availability kind of an entity.
 */
typedef NS_ENUM(NSUInteger, PLClangAvailabilityKind) {
    /**
     * The entity is available.
     */
    PLClangAvailabilityKindAvailable    = 0,

    /**
     * The entity is available, but deprecated.
     */
    PLClangAvailabilityKindDeprecated   = 1,

    /**
     * The entity is unavailable.
     */
    PLClangAvailabilityKindUnavailable  = 2,

    /**
     * The entity is available, but inaccessible.
     */
    PLClangAvailabilityKindInaccessible = 3
};

@interface PLClangAvailability : NSObject

/**
 * The overall availability kind of the entity.
 *
 * This takes into account both unconditional deprecation and unavailability attributes as well as those
 * specific to the target platform.
 */
@property(nonatomic, readonly) PLClangAvailabilityKind kind;

/**
 * A Boolean value indicating whether the entity is deprecated on all platforms.
 */
@property(nonatomic, readonly) BOOL isUnconditionallyDeprecated;

/**
 * The message provided along with the unconditional deprecation of the entity, or nil if no message was provided.
 */
@property(nonatomic, readonly) NSString *unconditionalDeprecationMessage;

/**
 * The replacement provided along with the unconditional deprecation of the entity, or nil if no replacement was provided.
 */
@property(nonatomic, readonly) NSString *unconditionalDeprecationReplacement;

/**
 * A Boolean value indicating whether the entity is unavailable on all platforms.
 */
@property(nonatomic, readonly) BOOL isUnconditionallyUnavailable;

/**
 * The message provided along with the unconditional unavailability of the entity, or nil if no message was provided.
 */
@property(nonatomic, readonly) NSString *unconditionalUnavailabilityMessage;

/**
 * An array of PLClangPlatformAvailability objects with plaform-specific availability information.
 */
@property(nonatomic, readonly) NSArray *platformAvailabilityEntries;

@end
