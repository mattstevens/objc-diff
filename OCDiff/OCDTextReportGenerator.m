#import "OCDTextReportGenerator.h"

#define COLOR_RED   "\x1b[31m"
#define COLOR_GREEN "\x1b[32m"
#define COLOR_RESET "\x1b[0m"

@implementation OCDTextReportGenerator

- (void)generateReportForDifferences:(OCDAPIDifferences *)differences title:(NSString *)title {
    BOOL useColor = isatty(STDOUT_FILENO) && getenv("TERM") != NULL;

    if (title != nil) {
        printf("%s\n", [title UTF8String]);
    }

    BOOL hasDifferences = NO;

    for (OCDModule *module in differences.modules) {
        if (differences.modules.count > 1) {
            if (module.differenceType != OCDifferenceTypeRemoval && module.differences.count < 1) {
                continue;
            }

            hasDifferences = YES;
            printf("\n%s", module.name.UTF8String);

            if (module.differenceType == OCDifferenceTypeAddition) {
                if (useColor) {
                    printf(COLOR_GREEN);
                }
                printf(" (Added)");
            } else if (module.differenceType == OCDifferenceTypeRemoval) {
                if (useColor) {
                    printf(COLOR_RED);
                }
                printf(" (Removed)");
            }

            if (useColor) {
                printf(COLOR_RESET);
            }

            printf("\n");

            for (NSUInteger i = 0; i < module.name.length; i++) {
                printf("=");
            }

            printf("\n");
        }

        if (module.differences.count > 0) {
            hasDifferences = YES;
            [self printDifferences:module.differences useColor:useColor];
        }
    }

    if (hasDifferences == NO) {
        printf("No differences\n");
    }
}

- (void)printDifferences:(NSArray<OCDifference *> *)differences useColor:(BOOL)useColor {
    NSString *lastFile = @"";

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
