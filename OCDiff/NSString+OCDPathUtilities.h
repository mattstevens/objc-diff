#import <Foundation/Foundation.h>

@interface NSString (OCDPathUtilities)

/**
 * Returns a new string made from the receiver by expanding it to an absolute path, if necessary.
 *
 * If the receiver is a relative path it is treated as relative to the current working directory.
 */
- (NSString *)ocd_absolutePath;

/**
 * Returns a new string made from the receiver by converting it to a path relative to the specified directory.
 *
 * @param directory The directory the new string's path should be relative to.
 */
- (NSString *)ocd_stringWithPathRelativeToDirectory:(NSString *)directory;

/**
 * Returns a Boolean value indicating whether the receiver contains a path to a framework.
 */
- (BOOL)ocd_isFrameworkPath;

@end
