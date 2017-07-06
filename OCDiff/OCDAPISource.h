#import <Foundation/Foundation.h>

@class PLClangTranslationUnit;

@interface OCDAPISource : NSObject

+ (instancetype)APISourceWithTranslationUnit:(PLClangTranslationUnit *)translationUnit;
+ (instancetype)APISourceWithTranslationUnit:(PLClangTranslationUnit *)translationUnit containingPath:(NSString *)containingPath includeSystemHeaders:(BOOL)includeSystemHeaders;

@property (nonatomic, readonly) PLClangTranslationUnit *translationUnit;
@property (nonatomic, readonly) NSString *containingPath;
@property (nonatomic, readonly) BOOL includeSystemHeaders;

@end
