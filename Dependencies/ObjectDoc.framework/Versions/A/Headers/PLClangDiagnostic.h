/*
 * Copyright (c) 2013 Plausible Labs Cooperative, Inc.
 * All rights reserved.
 */

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, PLClangDiagnosticSeverity) {
    /** A diagnostic that has been suppressed, eg, by a command line option. */
    PLClangDiagnosticSeverityIgnored = 1,

    /** A diagnostic that indicates suspicious code that may be ill-formed. */
    PLClangDiagnosticSeverityWarning = 2,

    /** A diagnostic that indicates that the code is ill-formed. */
    PLClangDiagnosticSeverityError = 3,

    /** A diagnostic that indicates that the code is ill-formed and any further parser recovery is unlikely to
     * produce useful results. */
    PLClangDiagnosticSeverityFatal = 4,
};

@interface PLClangDiagnostic : NSObject

/** The formatted error message, as it would be presented by clang */
@property(nonatomic, readonly) NSString *formattedErrorMessage;

/** Diagnostic severity */
@property(nonatomic, readonly) PLClangDiagnosticSeverity severity;

/** Child diagnostics, as an ordered array of PLClangDiagnostic instances. */
@property(nonatomic, readonly) NSArray *childDiagnostics;

@end