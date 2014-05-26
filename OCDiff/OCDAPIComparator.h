#import <Foundation/Foundation.h>
#import <ObjectDoc/ObjectDoc.h>
#import "OCDifference.h"

@interface OCDAPIComparator : NSObject

- (instancetype)initWithOldTranslationUnit:(PLClangTranslationUnit *)oldTranslationUnit newTranslationUnit:(PLClangTranslationUnit *)newTranslationUnit;
- (instancetype)initWithOldTranslationUnit:(PLClangTranslationUnit *)oldTranslationUnit newTranslationUnit:(PLClangTranslationUnit *)newTranslationUnit unsavedFiles:(NSArray *)unsavedFiles;

- (NSArray *)computeDifferences;

@end
