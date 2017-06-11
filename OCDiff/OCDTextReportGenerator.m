#import "OCDTextReportGenerator.h"
#import "OCDifference.h"

#define COLOR_RED   "\x1b[31m"
#define COLOR_GREEN "\x1b[32m"
#define COLOR_RESET "\x1b[0m"

@implementation OCDTextReportGenerator

- (void)generateReportForDifferences:(NSArray<OCDifference *> *)differences title:(NSString *)title {
    BOOL useColor = isatty(STDOUT_FILENO) && getenv("TERM") != NULL;

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
            for (NSUInteger i = 0; i < [file length]; i++) {
                printf("-");
            }
            printf("\n");
        }

        char indicator = ' ';
        switch (difference.type) {
            case OCDifferenceTypeAddition:
                indicator = '+';
                if (useColor) {
                    printf(COLOR_GREEN);
                }
                break;

            case OCDifferenceTypeRemoval:
                indicator = '-';
                if (useColor) {
                    printf(COLOR_RED);
                }
                break;

            case OCDifferenceTypeModification:
                indicator = ' ';
                break;
        }

        printf("%c %s\n", indicator, [difference.name UTF8String]);

        if (useColor) {
            printf(COLOR_RESET);
        }

        if ([difference.modifications count] > 0) {
            printf("\n");
        }

        for (OCDModification *modification in difference.modifications) {
            printf("          %s\n", [[OCDModification stringForModificationType:modification.type] UTF8String]);
            printf("    From: %s\n", modification.previousValue ? [modification.previousValue UTF8String] : "(none)");
            printf("      To: %s\n\n", modification.currentValue ? [modification.currentValue UTF8String] : "(none)");
        }
    }

}

@end
