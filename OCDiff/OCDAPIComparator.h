#import <Foundation/Foundation.h>
#import "OCDifference.h"

@interface OCDAPIComparator : NSObject

- (instancetype)initWithOldTranslationUnits:(NSSet *)oldTranslationUnits newTranslationUnits:(NSSet *)newTranslationUnits;
- (instancetype)initWithOldTranslationUnits:(NSSet *)oldTranslationUnits newTranslationUnits:(NSSet *)newTranslationUnits unsavedFiles:(NSArray *)unsavedFiles;

- (NSArray *)computeDifferences;

@end
