#import "NSString+OCDPathUtilities.h"

@implementation NSString (OCDPathUtilities)

- (NSString *)ocd_absolutePath {
    if ([self isAbsolutePath]) {
        return [self copy];
    }

    NSURL *fileURL = [NSURL fileURLWithPath:[self stringByStandardizingPath]];
    return [fileURL path];
}

- (NSString *)ocd_stringWithPathRelativeToDirectory:(NSString *)directory {
    if (directory == nil) {
        return [self copy];
    }

    NSString *path = [self ocd_absolutePath];
    directory = [directory ocd_absolutePath];

    NSUInteger index = 0;
    NSMutableArray *baseComponents = [[directory pathComponents] mutableCopy];
    NSMutableArray *pathComponents = [[path pathComponents] mutableCopy];
    if ([[baseComponents lastObject] isEqualToString:@"/"]) {
        [baseComponents removeLastObject];
    }

    while (index < [baseComponents count] && index < [pathComponents count] && [baseComponents[index] isEqualToString:pathComponents[index]]) {
        index++;
    }

    [baseComponents removeObjectsInRange:NSMakeRange(0, index)];
    [pathComponents removeObjectsInRange:NSMakeRange(0, index)];

    for (index = 0; index < [baseComponents count]; index++) {
        [pathComponents insertObject:@".." atIndex:0];
    }

    return [NSString pathWithComponents:pathComponents];
}

- (BOOL)ocd_isFrameworkPath {
    return [[self pathExtension] isEqualToString:@"framework"];
}

@end
