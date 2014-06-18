/*
 * Copyright (c) 2013 Plausible Labs Cooperative, Inc.
 * All rights reserved.
 */

#import <Foundation/Foundation.h>

#import "PLClangTranslationUnit.h"
#import "PLClangUnsavedFile.h"

/**
 * Options used when creating an index.
 */
typedef NS_OPTIONS(NSUInteger, PLClangIndexCreationOptions) {
    /**
     * Specifies that the index should only allow enumeration of "local"
     * declarations when loading new translation units. A "local" declaration
     * is one that belongs in the translation unit itself and not in a precompiled
     * header.
     */
    PLClangIndexCreationExcludePCHDeclarations = 1UL << 0,

    /**
     * Specifies that diagnostics should be output to the console when parsing
     * translation units.
     */
    PLClangIndexCreationDisplayDiagnostics     = 1UL << 1
};

/**
 * Options used when creating a translation unit.
 */
typedef NS_OPTIONS(NSUInteger, PLClangTranslationUnitCreationOptions) {
    /**
     * Specifies that the parser should construct a detailed preprocessing
     * record that includes all macro definitions and instantiations.
     *
     * Constructing a detailed preprocessing record requires more memory
     * and time to parse since the information contained in the record
     * is usually not retained. However, it can be useful for
     * applications that require more detailed information about the
     * behavior of the preprocessor.
     */
    PLClangTranslationUnitCreationDetailedPreprocessingRecord          = 1UL << 0,

    /**
     * Specifies that the translation unit is incomplete.
     *
     * When a translation unit is considered incomplete semantic analysis that
     * is typically performed at the end of the translation unit will be
     * suppressed. For example, this suppresses the completion of tentative
     * declarations in C and of instantiation of implicitly-instantiated function
     * templates in C++. This option is typically used when parsing a header with
     * the intent of producing a precompiled header.
     */
    PLClangTranslationUnitCreationIncomplete                           = 1UL << 1,

    /**
     * Specifies that the translation unit should be built with an implicit
     * precompiled header for the preamble.
     *
     * An implicit precompiled header can be used as an optimization when a
     * particular translation unit is likely to be reparsed many times and the
     * sources aren't changing that often. In this case, an implicit precompiled
     * header will be built containing all of the initial includes at the top of
     * the main file (the "preamble" of the file). In subsequent parses, if the
     * preamble or the files in it have not changed, reparsing the translation
     * unit will re-use the implicit precompiled header to improve parsing
     * performance.
     */
    PLClangTranslationUnitCreationPrecompilePreamble                   = 1UL << 2,

    /**
     * Specifies that the translation unit should cache some code-completion
     * results with each reparse of the source file.
     *
     * Caching of code-completion results is a performance optimization that
     * introduces some overhead to reparsing but improves the performance of
     * code-completion operations.
     */
    PLClangTranslationUnitCreationCacheCodeCompletionResults           = 1UL << 3,

    /**
     * Specifies that the translation unit will later be saved to disk.
     *
     * This option is typically used when parsing a header with the intent of
     * producing a precompiled header.
     */
    PLClangTranslationUnitCreationForSerialization                     = 1UL << 4,

    /**
     * Specifies that function and method bodies should be skipped while parsing.
     *
     * This option can be used to improve parsing performance when the translation
     * unit will only be searched for declarations/definitions while ignoring the
     * usages.
     */
    PLClangTranslationUnitCreationSkipFunctionBodies                   = 1UL << 5,

    /**
     * Specifies that brief documentation comments should be included in the set
     * of code completions returned from a translation unit.
     */
    PLClangTranslationUnitCreationIncludeBriefCommentsInCodeCompletion = 1UL << 6
};

@interface PLClangSourceIndex : NSObject

+ (instancetype) indexWithOptions: (PLClangIndexCreationOptions) options;

- (PLClangTranslationUnit *) addTranslationUnitWithASTPath: (NSString *) path
                                                   error: (NSError **) error;

- (PLClangTranslationUnit *) addTranslationUnitWithSourcePath: (NSString *) path
                                            unsavedFiles: (NSArray *) files
                                       compilerArguments: (NSArray *) arguments
                                                 options: (PLClangTranslationUnitCreationOptions) options
                                                   error: (NSError **) error;

- (PLClangTranslationUnit *) addTranslationUnitWithSourcePath: (NSString *) path
                                                fileData: (NSData *) data
                                       compilerArguments: (NSArray *) arguments
                                                 options: (PLClangTranslationUnitCreationOptions) options
                                                   error: (NSError **) error;

- (PLClangTranslationUnit *) addTranslationUnitWithCompilerArguments: (NSArray *) arguments
                                                 options: (PLClangTranslationUnitCreationOptions) options
                                                   error: (NSError **) error;

- (PLClangTranslationUnit *) addTranslationUnitWithSourcePath: (NSString *) path
                                       compilerArguments: (NSArray *) arguments
                                                 options: (PLClangTranslationUnitCreationOptions) options
                                                   error: (NSError **) error;

@end