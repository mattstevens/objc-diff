#import <Foundation/Foundation.h>
#import "OCDModification.h"

typedef NS_ENUM(NSUInteger, OCDifferenceType) {
    OCDifferenceTypeAddition,
    OCDifferenceTypeRemoval,
    OCDifferenceTypeModification
};

@interface OCDifference : NSObject

+ (instancetype)differenceWithType:(OCDifferenceType)type name:(NSString *)name;
+ (instancetype)modificationDifferenceWithName:(NSString *)name modifications:(NSArray *)modifications;

@property (nonatomic, readonly) OCDifferenceType type;
@property (nonatomic, readonly) NSString *name;

/**
 * For a modification difference, an array of OCDModification objects describing the modifications.
 */
@property (nonatomic, readonly) NSArray *modifications;

@end
