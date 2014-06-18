/*
 * Copyright (c) 2013 Plausible Labs Cooperative, Inc.
 * All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "PLClangCursor.h"

/**
 * The kind of a PLClangToken.
 */
typedef NS_ENUM(NSUInteger, PLClangTokenKind) {
    /** A token that contains some kind of punctuation. */
    PLClangTokenKindPunctuation,

    /** A language keyword. */
    PLClangTokenKindKeyword,

    /** An identifier (that is not a keyword). */
    PLClangTokenKindIdentifier,

    /** A numeric, string, or character literal. */
    PLClangTokenKindLiteral,

    /** A comment. */
    PLClangTokenKindComment
};

@interface PLClangToken : NSObject

/**
 * The token's kind.
 */
@property(nonatomic, readonly) PLClangTokenKind kind;

/**
 * A string representation of the token.
 */
@property(nonatomic, readonly) NSString *spelling;

/**
 * The token's source location.
 */
@property(nonatomic, readonly) PLClangSourceLocation *location;

/**
 * The source range covering this token.
 */
@property(nonatomic, readonly) PLClangSourceRange *extent;

/**
 * The cursor for the token, or nil if it cannot be mapped to a specific entity within the abstract syntax tree.
 */
@property(nonatomic, readonly) PLClangCursor *cursor;

@end
