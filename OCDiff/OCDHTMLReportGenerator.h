#import "OCDReportGenerator.h"

@interface OCDHTMLReportGenerator : NSObject <OCDReportGenerator>

- (instancetype)initWithOutputDirectory:(NSString *)directory;

@end
