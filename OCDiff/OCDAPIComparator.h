#import <Foundation/Foundation.h>
#import <ObjectDoc/ObjectDoc.h>
#import "OCDifference.h"

@interface OCDAPIComparator : NSObject

+ (NSArray *)differencesBetweenOldTranslationUnit:(PLClangTranslationUnit *)oldTranslationUnit newTranslationUnit:(PLClangTranslationUnit *)newTranslationUnit;
+ (NSArray *)differencesBetweenOldTranslationUnit:(PLClangTranslationUnit *)oldTranslationUnit newTranslationUnit:(PLClangTranslationUnit *)newTranslationUnit unsavedFiles:(NSArray *)unsavedFiles;

@end
