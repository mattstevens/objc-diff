#import <Foundation/Foundation.h>

@interface OCDXMLReportGenerator : NSObject

- (void)generateReportForDifferences:(NSArray *)differences title:(NSString *)title;

@end
