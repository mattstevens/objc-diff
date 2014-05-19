#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, OCDModificationType) {
    OCDModificationTypeDeclaration,
    OCDModificationTypeDeprecation,
    OCDModificationTypeOptional
};

@interface OCDModification : NSObject

+ (instancetype)modificationWithType:(OCDModificationType)type previousValue:(NSString *)previousValue currentValue:(NSString *)currentValue;

@property (nonatomic, readonly) OCDModificationType type;
@property (nonatomic, readonly) NSString *previousValue;
@property (nonatomic, readonly) NSString *currentValue;

@end
