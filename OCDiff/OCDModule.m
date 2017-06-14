#import "OCDModule.h"

@implementation OCDModule

- (instancetype)initWithName:(NSString *)name differenceType:(OCDifferenceType)differenceType differences:(NSArray<OCDifference *> *)differences {
    if (!(self = [super init]))
        return nil;

    _name = [name copy];
    _differenceType = differenceType;
    _differences = [differences copy];

    return self;
}

+ (instancetype)moduleWithName:(NSString *)name differenceType:(OCDifferenceType)differenceType differences:(NSArray<OCDifference *> *)differences {
    return [[self alloc] initWithName:name differenceType:differenceType differences:differences];
}

@end
