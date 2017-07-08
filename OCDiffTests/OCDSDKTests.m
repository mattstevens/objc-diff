#import <XCTest/XCTest.h>
#import "OCDSDK.h"

@interface OCDSDKTests : XCTestCase
@end

@implementation OCDSDKTests {
    NSString *_sdksDir;
}

- (void)setUp {
    [super setUp];
    _sdksDir = [[NSBundle bundleForClass:[self class]] pathForResource:@"SDKs" ofType:@""];
    XCTAssertNotNil(_sdksDir, @"Could not locate test SDKs directory in test bundle.");
}

- (void)testInvalidPath {
    XCTAssertNil([[OCDSDK alloc] initWithPath:nil]);
    XCTAssertNil([[OCDSDK alloc] initWithPath:@"/"]);
    XCTAssertNil([[OCDSDK alloc] initWithPath:[_sdksDir stringByAppendingPathComponent:@"NotFound.sdk"]]);
}

- (void)testNameLookup {
    OCDSDK *sdk = [OCDSDK SDKForName:@"macosx"];
    XCTAssertNotNil(sdk);
    XCTAssertEqual(sdk.platform, OCDPlatformMacOS);
}

- (void)testNameLookupForPath {
    NSString *path = [_sdksDir stringByAppendingPathComponent:@"MacOSX10.9.sdk"];
    OCDSDK *sdk = [OCDSDK SDKForName:path];
    XCTAssertNotNil(sdk);
    XCTAssertEqualObjects(sdk.path, path);
}

- (void)testMacOS {
    NSString *path = [_sdksDir stringByAppendingPathComponent:@"MacOSX10.9.sdk"];
    OCDSDK *sdk = [[OCDSDK alloc] initWithPath:path];
    XCTAssertEqualObjects(sdk.path, path);
    XCTAssertEqualObjects(sdk.name, @"OS X 10.9");
    XCTAssertEqualObjects(sdk.version, @"10.9");
    XCTAssertEqual(sdk.platform, OCDPlatformMacOS);
    XCTAssertEqualObjects(sdk.platformDisplayName, @"macOS");
    XCTAssertEqualObjects(sdk.deploymentTarget, @"10.9");
    XCTAssertEqualObjects(sdk.deploymentTargetCompilerArgument, @"-mmacosx-version-min");
    XCTAssertEqualObjects(sdk.deploymentTargetEnvironmentVariable, @"MACOSX_DEPLOYMENT_TARGET");
    XCTAssertNil(sdk.defaultArchitecture);
}

- (void)testMacOSOldFormat {
    NSString *path = [_sdksDir stringByAppendingPathComponent:@"MacOSX10.1.sdk"];
    OCDSDK *sdk = [[OCDSDK alloc] initWithPath:path];
    XCTAssertEqualObjects(sdk.path, path);
    XCTAssertEqualObjects(sdk.name, @"Mac OS X 10.1.5");
    XCTAssertEqualObjects(sdk.version, @"10.1.5");
    XCTAssertEqual(sdk.platform, OCDPlatformMacOS);
    XCTAssertEqualObjects(sdk.platformDisplayName, @"macOS");
    XCTAssertEqualObjects(sdk.deploymentTarget, @"10.1");
    XCTAssertEqualObjects(sdk.deploymentTargetCompilerArgument, @"-mmacosx-version-min");
    XCTAssertEqualObjects(sdk.deploymentTargetEnvironmentVariable, @"MACOSX_DEPLOYMENT_TARGET");
    XCTAssertNil(sdk.defaultArchitecture);
}

- (void)testIOS {
    NSString *path = [_sdksDir stringByAppendingPathComponent:@"iPhoneOS7.0.sdk"];
    OCDSDK *sdk = [[OCDSDK alloc] initWithPath:path];
    XCTAssertEqualObjects(sdk.path, path);
    XCTAssertEqualObjects(sdk.name, @"iOS 7.0");
    XCTAssertEqualObjects(sdk.version, @"7.0");
    XCTAssertEqual(sdk.platform, OCDPlatformIOS);
    XCTAssertEqualObjects(sdk.platformDisplayName, @"iOS");
    XCTAssertEqualObjects(sdk.deploymentTarget, @"7.0");
    XCTAssertEqualObjects(sdk.deploymentTargetCompilerArgument, @"-mios-version-min");
    XCTAssertEqualObjects(sdk.deploymentTargetEnvironmentVariable, @"IPHONEOS_DEPLOYMENT_TARGET");
    XCTAssertEqualObjects(sdk.defaultArchitecture, @"arm64");
}

- (void)testIOSSimulator {
    NSString *path = [_sdksDir stringByAppendingPathComponent:@"iPhoneSimulator7.0.sdk"];
    OCDSDK *sdk = [[OCDSDK alloc] initWithPath:path];
    XCTAssertEqualObjects(sdk.path, path);
    XCTAssertEqualObjects(sdk.name, @"Simulator - iOS 7.0");
    XCTAssertEqualObjects(sdk.version, @"7.0");
    XCTAssertEqual(sdk.platform, OCDPlatformIOS);
    XCTAssertEqualObjects(sdk.platformDisplayName, @"iOS");
    XCTAssertEqualObjects(sdk.deploymentTarget, @"7.0");
    XCTAssertEqualObjects(sdk.deploymentTargetCompilerArgument, @"-mios-simulator-version-min");
    XCTAssertEqualObjects(sdk.deploymentTargetEnvironmentVariable, @"IPHONEOS_DEPLOYMENT_TARGET");
    XCTAssertNil(sdk.defaultArchitecture);
}

- (void)testTVOS {
    NSString *path = [_sdksDir stringByAppendingPathComponent:@"AppleTVOS10.2.sdk"];
    OCDSDK *sdk = [[OCDSDK alloc] initWithPath:path];
    XCTAssertEqualObjects(sdk.path, path);
    XCTAssertEqualObjects(sdk.name, @"tvOS 10.2");
    XCTAssertEqualObjects(sdk.version, @"10.2");
    XCTAssertEqual(sdk.platform, OCDPlatformTVOS);
    XCTAssertEqualObjects(sdk.platformDisplayName, @"tvOS");
    XCTAssertEqualObjects(sdk.deploymentTarget, @"10.2");
    XCTAssertEqualObjects(sdk.deploymentTargetCompilerArgument, @"-mtvos-version-min");
    XCTAssertEqualObjects(sdk.deploymentTargetEnvironmentVariable, @"TVOS_DEPLOYMENT_TARGET");
    XCTAssertEqualObjects(sdk.defaultArchitecture, @"arm64");
}

- (void)testTVOSSimulator {
    NSString *path = [_sdksDir stringByAppendingPathComponent:@"AppleTVSimulator10.2.sdk"];
    OCDSDK *sdk = [[OCDSDK alloc] initWithPath:path];
    XCTAssertEqualObjects(sdk.path, path);
    XCTAssertEqualObjects(sdk.name, @"Simulator - tvOS 10.2");
    XCTAssertEqualObjects(sdk.version, @"10.2");
    XCTAssertEqual(sdk.platform, OCDPlatformTVOS);
    XCTAssertEqualObjects(sdk.platformDisplayName, @"tvOS");
    XCTAssertEqualObjects(sdk.deploymentTarget, @"10.2");
    XCTAssertEqualObjects(sdk.deploymentTargetCompilerArgument, @"-mtvos-simulator-version-min");
    XCTAssertEqualObjects(sdk.deploymentTargetEnvironmentVariable, @"TVOS_DEPLOYMENT_TARGET");
    XCTAssertNil(sdk.defaultArchitecture);
}

- (void)testWatchOS {
    NSString *path = [_sdksDir stringByAppendingPathComponent:@"WatchOS3.2.sdk"];
    OCDSDK *sdk = [[OCDSDK alloc] initWithPath:path];
    XCTAssertEqualObjects(sdk.path, path);
    XCTAssertEqualObjects(sdk.name, @"watchOS 3.2");
    XCTAssertEqualObjects(sdk.version, @"3.2");
    XCTAssertEqual(sdk.platform, OCDPlatformWatchOS);
    XCTAssertEqualObjects(sdk.platformDisplayName, @"watchOS");
    XCTAssertEqualObjects(sdk.deploymentTarget, @"3.2");
    XCTAssertEqualObjects(sdk.deploymentTargetCompilerArgument, @"-mwatchos-version-min");
    XCTAssertEqualObjects(sdk.deploymentTargetEnvironmentVariable, @"WATCHOS_DEPLOYMENT_TARGET");
    XCTAssertEqualObjects(sdk.defaultArchitecture, @"arm64");
}

- (void)testWatchOSSimulator {
    NSString *path = [_sdksDir stringByAppendingPathComponent:@"WatchSimulator3.2.sdk"];
    OCDSDK *sdk = [[OCDSDK alloc] initWithPath:path];
    XCTAssertEqualObjects(sdk.path, path);
    XCTAssertEqualObjects(sdk.name, @"Simulator - watchOS 3.2");
    XCTAssertEqualObjects(sdk.version, @"3.2");
    XCTAssertEqual(sdk.platform, OCDPlatformWatchOS);
    XCTAssertEqualObjects(sdk.platformDisplayName, @"watchOS");
    XCTAssertEqualObjects(sdk.deploymentTarget, @"3.2");
    XCTAssertEqualObjects(sdk.deploymentTargetCompilerArgument, @"-mwatchos-simulator-version-min");
    XCTAssertEqualObjects(sdk.deploymentTargetEnvironmentVariable, @"WATCHOS_DEPLOYMENT_TARGET");
    XCTAssertNil(sdk.defaultArchitecture);
}

@end
