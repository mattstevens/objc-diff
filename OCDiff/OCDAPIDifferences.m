#import "OCDAPIDifferences.h"

@implementation OCDAPIDifferences

- (instancetype)initWithModules:(NSArray<OCDModule *> *)modules {
    if (!(self = [super init]))
        return nil;

    _modules = [modules copy];

    return self;
}

+ (instancetype)APIDifferencesWithModules:(NSArray<OCDModule *> *)modules {
    return [[self alloc] initWithModules:modules];
}

@end

