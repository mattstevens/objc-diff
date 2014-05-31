#import <Foundation/Foundation.h>

@protocol OCDReportGenerator <NSObject>

- (void)generateReportForDifferences:(NSArray *)differences title:(NSString *)title;

@end