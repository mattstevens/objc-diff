#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, OCDModificationType) {
    OCDModificationTypeDeclaration,
    OCDModificationTypeAvailability,
    OCDModificationTypeDeprecationMessage,
    OCDModificationTypeReplacement,
    OCDModificationTypeSuperclass,
    OCDModificationTypeProtocols,
    OCDModificationTypeOptional,
    OCDModificationTypeHeader
};

@interface OCDModification : NSObject

+ (instancetype)modificationWithType:(OCDModificationType)type previousValue:(NSString *)previousValue currentValue:(NSString *)currentValue;

@property (nonatomic, readonly) OCDModificationType type;
@property (nonatomic, readonly) NSString *previousValue;
@property (nonatomic, readonly) NSString *currentValue;

+ (NSString *)stringForModificationType:(OCDModificationType)type;

@end
