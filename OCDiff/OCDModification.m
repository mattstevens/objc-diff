#import "OCDModification.h"

@implementation OCDModification

- (instancetype)initWithType:(OCDModificationType)type previousValue:(NSString *)previousValue currentValue:(NSString *)currentValue {
    if (!(self = [super init]))
        return nil;

    _type = type;
    _previousValue = [previousValue copy];
    _currentValue = [currentValue copy];

    return self;
}

+ (instancetype)modificationWithType:(OCDModificationType)type previousValue:(NSString *)previousValue currentValue:(NSString *)currentValue {
    return [[self alloc] initWithType:type previousValue:previousValue currentValue:currentValue];
}

- (NSString *)description {
    NSMutableString *result = [NSMutableString new];
    switch (self.type) {
        case OCDModificationTypeDeclaration:
            [result appendString:@"Declaration"];
            break;
        case OCDModificationTypeDeprecation:
            [result appendString:@"Deprecation"];
            break;
        case OCDModificationTypeSuperclass:
            [result appendString:@"Superclass"];
            break;
        case OCDModificationTypeOptional:
            [result appendString:@"Optional"];
            break;
        case OCDModificationTypeHeader:
            [result appendString:@"Header"];
            break;
    }

    [result appendString:@": "];
    [result appendString:self.previousValue ?: @"(nil)"];
    [result appendString:@" to "];
    [result appendString:self.currentValue ?: @"(nil)"];
    return result;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[OCDModification class]])
        return NO;

    OCDModification *other = object;

    return
    other.type == self.type &&
    (other.previousValue == self.previousValue || [other.previousValue isEqual:self.previousValue]) &&
    (other.currentValue == self.currentValue || [other.currentValue isEqual:self.currentValue]);
}

- (NSUInteger)hash {
    return self.type ^ [self.previousValue hash] ^ [self.currentValue hash];
}

@end
