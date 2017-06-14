#import <Foundation/Foundation.h>
#import "OCDAPIDifferences.h"

@protocol OCDReportGenerator <NSObject>

- (void)generateReportForDifferences:(OCDAPIDifferences *)differences title:(NSString *)title;

@end
