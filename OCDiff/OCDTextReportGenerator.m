#import "OCDTextReportGenerator.h"
#import "OCDifference.h"

@implementation OCDTextReportGenerator

- (void)generateReportForDifferences:(NSArray *)differences title:(NSString *)title {
    NSString *lastFile = @"";

    if (title != nil) {
        printf("%s\n", [title UTF8String]);
    }

    if ([differences count] == 0) {
        printf("No differences\n");
        return;
    }

    for (OCDifference *difference in differences) {
        NSString *file = difference.path;
        if ([file isEqualToString:lastFile] == NO) {
            lastFile = file;
            printf("\n%s\n", [file UTF8String]);
        }

        char indicator = ' ';
        switch (difference.type) {
            case OCDifferenceTypeAddition:
                indicator = '+';
                break;

            case OCDifferenceTypeRemoval:
                indicator = '-';
                break;

            case OCDifferenceTypeModification:
                indicator = ' ';
                break;
        }

        printf("%c %s\n", indicator, [difference.name UTF8String]);
        for (OCDModification *modification in difference.modifications) {
            printf("\n");
            printf("          %s\n", [[OCDModification stringForModificationType:modification.type] UTF8String]);
            printf("    From: %s\n", [modification.previousValue UTF8String]);
            printf("      To: %s\n\n", [modification.currentValue UTF8String]);
        }
    }

}

@end
