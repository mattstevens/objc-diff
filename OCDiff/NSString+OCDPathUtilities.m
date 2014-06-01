#import "NSString+OCDPathUtilities.h"

@implementation NSString (OCDPathUtilities)

- (NSString *)ocd_stringWithAbsolutePath {
    if ([self isAbsolutePath]) {
        return [self copy];
    }

    NSURL *fileURL = [NSURL fileURLWithPath:[self stringByStandardizingPath]];
    return [fileURL path];
}

@end
