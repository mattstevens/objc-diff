#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, OCDPlatform) {
    OCDPlatformIOS,
    OCDPlatformMacOS,
    OCDPlatformTVOS,
    OCDPlatformWatchOS
};

@interface OCDSDK : NSObject

- (instancetype)initWithPath:(NSString *)path;
+ (instancetype)SDKForName:(NSString *)sdkName;

/**
 * Returns the SDK that the specified path resides within, if any.
 */
+ (instancetype)containingSDKForPath:(NSString *)path;

@property (nonatomic, readonly, copy) NSString *path;
@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, readonly, copy) NSString *version;
@property (nonatomic, readonly) OCDPlatform platform;
@property (nonatomic, readonly) NSString *platformDisplayName;
@property (nonatomic, readonly, copy) NSString *platformVersion;
@property (nonatomic, readonly, copy) NSString *platformBuild;
@property (nonatomic, readonly, copy) NSString *deploymentTarget;
@property (nonatomic, readonly) NSString *deploymentTargetCompilerArgument;
@property (nonatomic, readonly) NSString *deploymentTargetEnvironmentVariable;
@property (nonatomic, readonly) NSString *defaultArchitecture;

@end
