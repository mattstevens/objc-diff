#import "OCDifference.h"

@implementation OCDifference

- (instancetype)initWithType:(OCDifferenceType)type name:(NSString *)name modifications:(NSArray *)modifications {
    if (!(self = [super init]))
        return nil;

    _type = type;
    _name = [name copy];
    _modifications = [modifications copy];

    return self;
}

+ (instancetype)differenceWithType:(OCDifferenceType)type name:(NSString *)name {
    return [[self alloc] initWithType:type name:name modifications:nil];
}

+ (instancetype)modificationDifferenceWithName:(NSString *)name modifications:(NSArray *)modifications {
    return [[self alloc] initWithType:OCDifferenceTypeModification name:name modifications:modifications];
}

- (NSString *)description {
    NSMutableString *result = [NSMutableString stringWithString:@"["];
    switch (self.type) {
        case OCDifferenceTypeAddition:
            [result appendString:@"A"];
            break;
        case OCDifferenceTypeRemoval:
            [result appendString:@"R"];
            break;
        case OCDifferenceTypeModification:
            [result appendString:@"M"];
            break;
    }
    [result appendString:@"] "];
    [result appendString:self.name];

    if ([self.modifications count]) {
        // TODO
        [result appendString:[self.modifications description]];
    }

    return result;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[OCDifference class]])
        return NO;

    OCDifference *other = object;

    return
    other.type == self.type &&
    (other.name == self.name || [other.name isEqual:self.name]) &&
    (other.modifications == self.modifications || [other.modifications isEqual:self.modifications]);
}

- (NSUInteger)hash {
    return self.type ^ [self.name hash] ^ [self.modifications hash];
}

@end
