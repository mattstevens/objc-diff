#import "OCDAPISource.h"

@implementation OCDAPISource

- (instancetype)initWithTranslationUnit:(PLClangTranslationUnit *)translationUnit containingPath:(NSString *)containingPath includeSystemHeaders:(BOOL)includeSystemHeaders {
    self = [super init];
    if (self) {
        _translationUnit = translationUnit;
        _containingPath = [containingPath copy];
        _includeSystemHeaders = includeSystemHeaders;
    }

    return self;
}

+ (instancetype)APISourceWithTranslationUnit:(PLClangTranslationUnit *)translationUnit {
    return [[self alloc] initWithTranslationUnit:translationUnit containingPath:nil includeSystemHeaders:NO];
}

+ (instancetype)APISourceWithTranslationUnit:(PLClangTranslationUnit *)translationUnit containingPath:(NSString *)containingPath includeSystemHeaders:(BOOL)includeSystemHeaders {
    return [[self alloc] initWithTranslationUnit:translationUnit containingPath:containingPath includeSystemHeaders:includeSystemHeaders];
}

@end
