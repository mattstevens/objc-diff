#import "OCDTitleGenerator.h"
#import "NSString+OCDPathUtilities.h"
#import "OCDSDK.h"

@implementation OCDTitleGenerator

+ (NSString *)reportTitleForOldFrameworkPath:(NSString *)oldPath newFrameworkPath:(NSString *)newPath {
    if ([oldPath ocd_isFrameworkPath] && [newPath ocd_isFrameworkPath]) {
        // Attempt to obtain API name and version information from the framework's Info.plist
        NSDictionary *oldInfo = [NSDictionary dictionaryWithContentsOfFile:[oldPath stringByAppendingPathComponent:@"Resources/Info.plist"]];
        NSDictionary *newInfo = [NSDictionary dictionaryWithContentsOfFile:[newPath stringByAppendingPathComponent:@"Resources/Info.plist"]];
        if (oldInfo != nil && newInfo != nil) {
            NSString *bundleName = newInfo[@"CFBundleName"];
            NSString *oldVersion = oldInfo[@"CFBundleShortVersionString"];
            NSString *newVersion = newInfo[@"CFBundleShortVersionString"];
            if (oldVersion == nil || newVersion == nil) {
                oldVersion = oldInfo[@"CFBundleVersion"];
                newVersion = newInfo[@"CFBundleVersion"];
            }

            if (bundleName != nil && oldVersion != nil && newVersion != nil && [oldVersion isEqualToString:newVersion] == NO) {
                return [NSString stringWithFormat:@"%@ %@ to %@ API Differences", bundleName, oldVersion, newVersion];
            }
        }
    }

    return nil;
}

+ (NSString *)reportTitleForOldSDK:(OCDSDK *)oldSDK newSDK:(OCDSDK *)newSDK {
    if (newSDK.platformDisplayName != nil && oldSDK.version != nil && newSDK.version != nil) {
        NSString *platformName = newSDK.platformDisplayName;
        NSString *oldVersion = oldSDK.version;
        NSString *newVersion = newSDK.version;

        if ([oldVersion isEqualToString:newVersion] && oldSDK.platformVersion != nil && newSDK.platformVersion != nil) {
            oldVersion = oldSDK.platformVersion;
            newVersion = newSDK.platformVersion;

            if ([oldVersion isEqualToString:newVersion] && oldSDK.platformBuild != nil && newSDK.platformBuild != nil) {
                platformName = [platformName stringByAppendingFormat:@" %@", newVersion];
                oldVersion = oldSDK.platformBuild;
                newVersion = newSDK.platformBuild;
            }
        }

        if ([oldVersion isEqualToString:newVersion] == NO) {
            return [NSString stringWithFormat:@"%@ %@ to %@ API Differences", platformName, oldVersion, newVersion];
        }
    }

    return nil;
}

+ (NSString *)reportTitleForOldPath:(NSString *)oldPath newPath:(NSString *)newPath {
    OCDSDK *oldSDK = [OCDSDK containingSDKForPath:oldPath];
    OCDSDK *newSDK = [OCDSDK containingSDKForPath:newPath];

    BOOL oldPathIsSDK = [oldSDK.path isEqualToString:oldPath];
    BOOL newPathIsSDK = [newSDK.path isEqualToString:newPath];

    if (oldPathIsSDK && newPathIsSDK) {
        return [self reportTitleForOldSDK:oldSDK newSDK:newSDK];
    }

    return [self reportTitleForOldFrameworkPath:oldPath newFrameworkPath:newPath];
}

@end
