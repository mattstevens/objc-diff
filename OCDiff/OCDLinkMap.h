#import <Foundation/Foundation.h>

/**
 * A mapping of Clang Unified Symbol Resolutions to documentation URLs.
 *
 * The format of a linkmap is a property list with the following entries:
 *
 * BaseURL: The base URL that all path entries in USRMap are relative to.
 * Query: An optional query string to append to all URLs.
 * USRMap: A dictionary of USR strings to URL paths.
 */
@interface OCDLinkMap : NSObject

- (instancetype)initWithPath:(NSString *)path;

- (NSURL *)URLForUSR:(NSString *)USR;

@end

