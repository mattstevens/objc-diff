#import <XCTest/XCTest.h>
#import "OCDTitleGenerator.h"

@interface OCDTitleGeneratorTests : XCTestCase
@end

@implementation OCDTitleGeneratorTests {
    NSString *_sdksDir;
}

- (void)setUp {
    [super setUp];
    _sdksDir = [[NSBundle bundleForClass:[self class]] pathForResource:@"SDKs" ofType:@""];
    XCTAssertNotNil(_sdksDir, @"Could not locate test SDKs directory in test bundle.");
}

- (void)testInvalidInputs {
    XCTAssertNil([OCDTitleGenerator reportTitleForOldPath:nil newPath:nil]);

    NSString *newSDKPath = [_sdksDir stringByAppendingPathComponent:@"MacOSX10.13.sdk"];
    XCTAssertNil([OCDTitleGenerator reportTitleForOldPath:nil newPath:newSDKPath]);
}

- (void)testsSDKs {
    NSString *oldSDKPath = [_sdksDir stringByAppendingPathComponent:@"MacOSX10.9.sdk"];
    NSString *newSDKPath = [_sdksDir stringByAppendingPathComponent:@"MacOSX10.13.sdk"];
    NSString *title = [OCDTitleGenerator reportTitleForOldPath:oldSDKPath newPath:newSDKPath];
    XCTAssertEqualObjects(title, @"macOS 10.9 to 10.13 API Differences");
}

- (void)testsSDKDotRelease {
    NSString *oldSDKPath = [_sdksDir stringByAppendingPathComponent:@"MacOSX10.13.sdk"];
    NSString *newSDKPath = [_sdksDir stringByAppendingPathComponent:@"MacOSX10.13.4.sdk"];
    NSString *title = [OCDTitleGenerator reportTitleForOldPath:oldSDKPath newPath:newSDKPath];
    XCTAssertEqualObjects(title, @"macOS 10.13.2 to 10.13.4 API Differences");
}

@end
