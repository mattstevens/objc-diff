#import <Foundation/Foundation.h>
#import <ObjectDoc/ObjectDoc.h>
#import "OCDAPISource.h"
#import "OCDifference.h"

@interface OCDAPIComparator : NSObject

+ (NSArray<OCDifference *> *)differencesBetweenOldAPISource:(OCDAPISource *)oldAPISource newAPISource:(OCDAPISource *)newAPISource;

+ (NSArray<OCDifference *> *)differencesBetweenOldTranslationUnit:(PLClangTranslationUnit *)oldTranslationUnit newTranslationUnit:(PLClangTranslationUnit *)newTranslationUnit;

@end
