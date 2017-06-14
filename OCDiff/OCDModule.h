#import <Foundation/Foundation.h>
#import "OCDifference.h"

@interface OCDModule : NSObject

+ (instancetype)moduleWithName:(NSString *)name differenceType:(OCDifferenceType)differenceType differences:(NSArray<OCDifference *> *)differences;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) OCDifferenceType differenceType;
@property (nonatomic, readonly) NSArray<OCDifference *> *differences;

@end
