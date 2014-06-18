/*
 * Copyright (c) 2013 Plausible Labs Cooperative, Inc.
 * All rights reserved.
 */

#import <Foundation/Foundation.h>
@class PLClangTranslationUnit;

@interface PLClangSourceLocation : NSObject

- (instancetype) initWithTranslationUnit: (PLClangTranslationUnit *) translationUnit
                                    file: (NSString *) path
                                  offset: (off_t) offset;

- (instancetype) initWithTranslationUnit: (PLClangTranslationUnit *) translationUnit
                                    file: (NSString *) path
                              lineNumber: (NSUInteger) lineNumber
                            columnNumber: (NSUInteger) columnNumber;

/**
 * The path of the file containing this source location.
 */
@property(nonatomic, readonly) NSString *path;

/**
 * The byte offset within the file.
 */
@property(nonatomic, readonly) off_t fileOffset;

/**
 * The line number within the file (1-based).
 */
@property(nonatomic, readonly) NSUInteger lineNumber;

/**
 * The column number within the file (1-based).
 */
@property(nonatomic, readonly) NSUInteger columnNumber;

/**
 * A Boolean value indicating whether the location is within the main file of the translation unit.
 */
@property(nonatomic, readonly) BOOL isInMainFile;

/**
 * A Boolean value indicating whether the location is within a system header.
 */
@property(nonatomic, readonly) BOOL isInSystemHeader;

@end
