#import <Foundation/Foundation.h>
#import <ObjectDoc/ObjectDoc.h>
#import <getopt.h>

#import "OCDAPIComparator.h"

static void print_usage(void) {
    printf(""
    "Usage: ocdiff --old <path to old API> --new <path to new API> [options]\n"
    "\n"
    "Generates an Objective-C API diff report.\n"
    "\n"
    "Options:\n"
    "  -h, --help       Show this help message and exit\n"
    "  -o, --old        Path to the old API header(s)\n"
    "  -n, --new        Path to the new API header(s)\n"
    "      --version    Show the version and exit \n");
}

int main(int argc, char *argv[]) {
    @autoreleasepool {
        NSString *oldPath;
        NSString *newPath;
        NSMutableArray *oldCompilerArguments = [NSMutableArray array];
        NSMutableArray *newCompilerArguments = [NSMutableArray array];
        int optchar;

        [oldCompilerArguments addObject:@"-x"];
        [oldCompilerArguments addObject:@"objective-c-header"];
        [newCompilerArguments addObject:@"-x"];
        [newCompilerArguments addObject:@"objective-c-header"];

        static struct option longopts[] = {
            { "help",         no_argument,        NULL,          'h' },
            { "old",          required_argument,  NULL,          'o' },
            { "new",          required_argument,  NULL,          'n' },
            { "Xold",         required_argument,  NULL,          'x' },
            { "Xnew",         required_argument,  NULL,          'y' },
            { "version",      no_argument,        NULL,          'v' },
            { NULL,           0,                  NULL,           0  }
        };

        while ((optchar = getopt_long(argc, argv, "hon", longopts, NULL)) != -1) {
            switch (optchar) {
                case 'h':
                    print_usage();
                    return 0;
                case 'o':
                    oldPath = @(optarg);
                    break;
                case 'n':
                    newPath = @(optarg);
                    break;
                case 'v':
                    printf("ocdiff %s\n", "DEV");
                    return 0;
                case 'x':
                    [oldCompilerArguments addObject:@(optarg)];
                    break;
                case 'y':
                    [newCompilerArguments addObject:@(optarg)];
                    break;
                case 0:
                    break;
                case '?':
                    return 1;
                default:
                    // Unhandled options are passed to the compiler
                    [oldCompilerArguments addObject:@(optarg)];
                    [newCompilerArguments addObject:@(optarg)];
                    break;
            }
        }
        argc -= optind;
        argv += optind;

        if ([oldPath length] < 1) {
            fprintf(stderr, "No old API path specified");
            return 1;
        }

        if ([newPath length] < 1) {
            fprintf(stderr, "No old API path specified");
            return 1;
        }

        for (int i = 0; i < argc; i++) {
            // Unhandled arguments are passed to the compiler
            [oldCompilerArguments addObject:@(argv[i])];
            [newCompilerArguments addObject:@(argv[i])];
        }

        // Parse the translation units

        PLClangSourceIndex *index = [PLClangSourceIndex indexWithOptions:PLClangIndexCreationDisplayDiagnostics];

        NSError *error;
        PLClangTranslationUnit *oldTU = [index addTranslationUnitWithSourcePath:oldPath
                                                              compilerArguments:oldCompilerArguments
                                                                        options:PLClangTranslationUnitCreationDetailedPreprocessingRecord |
                                                                                PLClangTranslationUnitCreationSkipFunctionBodies
                                                                          error:&error];
        if (oldTU == nil) {
            return 1;
        }

        PLClangTranslationUnit *newTU = [index addTranslationUnitWithSourcePath:newPath
                                                              compilerArguments:newCompilerArguments
                                                                        options:PLClangTranslationUnitCreationDetailedPreprocessingRecord |
                                                                                PLClangTranslationUnitCreationSkipFunctionBodies
                                                                          error:&error];
        if (newTU == nil) {
            return 1;
        }

        OCDAPIComparator *comparator = [[OCDAPIComparator alloc] initWithOldTranslationUnits:[NSSet setWithObject:oldTU] newTranslationUnits:[NSSet setWithObject:newTU]];

        NSArray *differences = [comparator computeDifferences];
        differences = [differences sortedArrayUsingComparator:^NSComparisonResult(OCDifference *obj1, OCDifference *obj2) {
            if (obj1.type != obj2.type) {
                return obj1.type == OCDifferenceTypeRemoval ? NSOrderedAscending : NSOrderedDescending;
            }

            return [obj1.name localizedStandardCompare:obj2.name];
        }];

        for (OCDifference *difference in differences) {
            printf("%s\n", [[difference description] UTF8String]);
        }

    }

    return 0;
}
