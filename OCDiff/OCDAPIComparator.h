#import <Foundation/Foundation.h>
#import <ObjectDoc/ObjectDoc.h>
#import "OCDifference.h"

@interface OCDAPIComparator : NSObject

+ (NSArray<OCDifference *> *)differencesBetweenOldTranslationUnit:(PLClangTranslationUnit *)oldTranslationUnit newTranslationUnit:(PLClangTranslationUnit *)newTranslationUnit;

@end
