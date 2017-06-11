#import <Foundation/Foundation.h>
@class OCDifference;

@protocol OCDReportGenerator <NSObject>

- (void)generateReportForDifferences:(NSArray<OCDifference *> *)differences title:(NSString *)title;

@end
