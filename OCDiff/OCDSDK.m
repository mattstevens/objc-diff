#import "OCDSDK.h"

static NSString * const PlatformNameMacOS = @"macosx";
static NSString * const PlatformNameIOS = @"iphoneos";
static NSString * const PlatformNameIOSSimulator = @"iphonesimulator";
static NSString * const PlatformNameTVOS = @"appletvos";
static NSString * const PlatformNameTVOSSimulator = @"appletvsimulator";
static NSString * const PlatformNameWatchOS = @"watchos";
static NSString * const PlatformNameWatchOSSimulator = @"watchsimulator";
static NSString * const ArchARM64 = @"arm64";

@implementation OCDSDK

- (instancetype)initWithPath:(NSString *)path {
    if (!(self = [super init]))
        return nil;

    NSString *settingsPath = [path stringByAppendingPathComponent:@"SDKSettings.plist"];
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:settingsPath];
    if (settings == nil) {
        return nil;
    }

    _path = [path copy];
    _name = settings[@"DisplayName"] ?: settings[@"name"];
    _version = settings[@"Version"];

    if (_version == nil && _name != nil) {
        // Old SDKs did not have a Version property, parse the version from the name
        NSCharacterSet *numericSet = [NSCharacterSet decimalDigitCharacterSet];
        NSUInteger start = [_name rangeOfCharacterFromSet:numericSet].location;
        NSUInteger end = [_name rangeOfCharacterFromSet:numericSet options:NSBackwardsSearch].location;
        if (start != NSNotFound && end > start) {
            _version = [_name substringWithRange:NSMakeRange(start, (end + 1) - start)];
        }
    }

    NSDictionary *buildSettings = settings[@"DefaultProperties"] ?: settings[@"buildSettings"];
    if (buildSettings != nil) {
        NSString *platformName = buildSettings[@"PLATFORM_NAME"];
        if (platformName == nil) {
            platformName = PlatformNameMacOS;
        }

        if ([platformName isEqualToString:PlatformNameMacOS]) {
            _platform = OCDPlatformMacOS;
            _deploymentTargetCompilerArgument = @"-mmacosx-version-min";
            _deploymentTargetEnvironmentVariable = @"MACOSX_DEPLOYMENT_TARGET";
        } else if ([platformName isEqualToString:PlatformNameIOS]) {
            _platform = OCDPlatformIOS;
            _defaultArchitecture = ArchARM64;
            _deploymentTargetCompilerArgument = @"-mios-version-min";
            _deploymentTargetEnvironmentVariable = @"IPHONEOS_DEPLOYMENT_TARGET";
        } else if ([platformName isEqualToString:PlatformNameIOSSimulator]) {
            _platform = OCDPlatformIOS;
            _deploymentTargetCompilerArgument = @"-mios-simulator-version-min";
            _deploymentTargetEnvironmentVariable = @"IPHONEOS_DEPLOYMENT_TARGET";
        } else if ([platformName isEqualToString:PlatformNameTVOS]) {
            _platform = OCDPlatformTVOS;
            _defaultArchitecture = ArchARM64;
            _deploymentTargetCompilerArgument = @"-mtvos-version-min";
            _deploymentTargetEnvironmentVariable = @"TVOS_DEPLOYMENT_TARGET";
        } else if ([platformName isEqualToString:PlatformNameTVOSSimulator]) {
            _platform = OCDPlatformTVOS;
            _deploymentTargetCompilerArgument = @"-mtvos-simulator-version-min";
            _deploymentTargetEnvironmentVariable = @"TVOS_DEPLOYMENT_TARGET";
        } else if ([platformName isEqualToString:PlatformNameWatchOS]) {
            _platform = OCDPlatformWatchOS;
            _defaultArchitecture = ArchARM64;
            _deploymentTargetCompilerArgument = @"-mwatchos-version-min";
            _deploymentTargetEnvironmentVariable = @"WATCHOS_DEPLOYMENT_TARGET";
        } else if ([platformName isEqualToString:PlatformNameWatchOSSimulator]) {
            _platform = OCDPlatformWatchOS;
            _deploymentTargetCompilerArgument = @"-mwatchos-simulator-version-min";
            _deploymentTargetEnvironmentVariable = @"WATCHOS_DEPLOYMENT_TARGET";
        }

        if (_deploymentTargetEnvironmentVariable != nil) {
            _deploymentTarget = buildSettings[_deploymentTargetEnvironmentVariable];
        }
    }

    NSString *systemVersionPath = [path stringByAppendingPathComponent:@"System/Library/CoreServices/SystemVersion.plist"];
    NSDictionary *systemVersion = [NSDictionary dictionaryWithContentsOfFile:systemVersionPath];
    if (systemVersionPath != nil) {
        _platformVersion = systemVersion[@"ProductVersion"];
        _platformBuild = systemVersion[@"ProductBuildVersion"];
    }

    return self;
}

+ (instancetype)SDKForName:(NSString *)sdkName {
    if ([sdkName isAbsolutePath]) {
        return [[self alloc] initWithPath:sdkName];
    } else {
        NSString *sdkPath = [self XCRunResultForArguments:@[@"--sdk", sdkName, @"--show-sdk-path"]];
        return [[self alloc] initWithPath:sdkPath];
    }
}

+ (instancetype)containingSDKForPath:(NSString *)path {
    do {
        OCDSDK *sdk = [[self alloc] initWithPath:path];
        if (sdk != nil) {
            return sdk;
        }
    } while ((path = [path stringByDeletingLastPathComponent]) && [path length] > 1);

    return nil;
}

- (NSString *)platformDisplayName {
    switch (self.platform) {
        case OCDPlatformIOS:
            return @"iOS";

        case OCDPlatformMacOS:
            return @"macOS";

        case OCDPlatformTVOS:
            return @"tvOS";

        case OCDPlatformWatchOS:
            return @"watchOS";
    }

    return nil;
}

- (NSString *)description {
    return self.name;
}

+ (NSString *)XCRunResultForArguments:(NSArray *)arguments {
    NSPipe *outputPipe = [NSPipe pipe];
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/xcrun";
    task.arguments = arguments;
    task.standardInput = [NSPipe pipe];
    task.standardOutput = outputPipe;
    task.standardError = [NSPipe pipe];
    [task launch];
    [task waitUntilExit];

    if ([task terminationStatus] != 0) {
        return nil;
    }

    NSData *resultData = [outputPipe.fileHandleForReading readDataToEndOfFile];
    NSString *result = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
    result = [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return result;
}

@end
