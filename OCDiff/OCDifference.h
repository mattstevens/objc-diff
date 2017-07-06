#import <Foundation/Foundation.h>
#import "OCDModification.h"

typedef NS_ENUM(NSUInteger, OCDifferenceType) {
    OCDifferenceTypeRemoval,
    OCDifferenceTypeAddition,
    OCDifferenceTypeModification
};

@interface OCDifference : NSObject

+ (instancetype)differenceWithType:(OCDifferenceType)type name:(NSString *)name path:(NSString *)path lineNumber:(NSUInteger)lineNumber;
+ (instancetype)differenceWithType:(OCDifferenceType)type name:(NSString *)name path:(NSString *)path lineNumber:(NSUInteger)lineNumber USR:(NSString *)USR;
+ (instancetype)modificationDifferenceWithName:(NSString *)name path:(NSString *)path lineNumber:(NSUInteger)lineNumber modifications:(NSArray<OCDModification *> *)modifications;
+ (instancetype)modificationDifferenceWithName:(NSString *)name path:(NSString *)path lineNumber:(NSUInteger)lineNumber USR:(NSString *)USR modifications:(NSArray<OCDModification *> *)modifications;

@property (nonatomic, readonly) OCDifferenceType type;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *path;
@property (nonatomic, readonly) NSUInteger lineNumber;
@property (nonatomic, readonly) NSString *USR;

/**
 * For a modification difference, an array of OCDModification objects describing the modifications.
 */
@property (nonatomic, readonly) NSArray<OCDModification *> *modifications;

@end
