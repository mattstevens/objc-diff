#import <Foundation/Foundation.h>

@interface OCDTextReportGenerator : NSObject

- (void)generateReportForDifferences:(NSArray *)differences title:(NSString *)title;

@end
