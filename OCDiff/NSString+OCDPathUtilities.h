#import <Foundation/Foundation.h>

@interface NSString (OCDPathUtilities)

/**
 * Returns a new string made from the receiver by expanding it to an absolute path, if necessary.
 *
 * If the receiver is a relative path it is treated as relative to the current working directory.
 */
- (NSString *)ocd_stringWithAbsolutePath;

@end
