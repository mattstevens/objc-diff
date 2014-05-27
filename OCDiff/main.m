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
    "  -t, --title      Title of the generated report\n"
    "      --version    Show the version and exit \n");
}

static BOOL IsFrameworkAtPath(NSString *path) {
    return [[path pathExtension] isEqualToString:@"framework"];
}

static PLClangTranslationUnit *TranslationUnitForHeaderPaths(PLClangSourceIndex *index, NSString *baseDirectory, NSArray *paths, NSArray *compilerArguments) {
    NSMutableString *source = [[NSMutableString alloc] init];
    for (NSString *path in paths) {
        [source appendFormat:@"#import \"%@\"\n", path];
    }

    NSString *combinedHeaderPath = [baseDirectory stringByAppendingPathComponent:@"_OCDAPI.h"];
    PLClangUnsavedFile *unsavedFile = [PLClangUnsavedFile unsavedFileWithPath:combinedHeaderPath
                                                                         data:[source dataUsingEncoding:NSUTF8StringEncoding]];

    NSError *error;
    PLClangTranslationUnit *translationUnit = [index addTranslationUnitWithSourcePath:combinedHeaderPath
                                                                         unsavedFiles:@[unsavedFile]
                                                                    compilerArguments:compilerArguments
                                                                              options:PLClangTranslationUnitCreationDetailedPreprocessingRecord |
                                                                                      PLClangTranslationUnitCreationSkipFunctionBodies
                                                                                error:&error];

    if (translationUnit == nil || translationUnit.didFail) {
        // TODO: Log error
        return nil;
    }

    return translationUnit;
}

static PLClangTranslationUnit *TranslationUnitForPath(PLClangSourceIndex *index, NSString *path, NSArray *compilerArguments) {
    BOOL isDirectory = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory] == NO) {
        fprintf(stderr, "%s not found\n", [path UTF8String]);
        return nil;
    }

    if (isDirectory) {
        // If the specified path is a framework, search its headers and automatically add its parent
        // directory to the framework search paths. This enables #import <FrameworkName/Header.h> to
        // be resolved without any additional configuration.
        if (IsFrameworkAtPath(path)) {
            compilerArguments = [compilerArguments arrayByAddingObjectsFromArray:@[@"-F", [path stringByDeletingLastPathComponent]]];
            path = [path stringByAppendingPathComponent:@"Headers"];
            return TranslationUnitForPath(index, path, compilerArguments);
        }

        NSMutableArray *paths = [NSMutableArray array];
        NSDirectoryEnumerator *enumerator  = [[NSFileManager defaultManager] enumeratorAtPath:path];
        for (NSString *file in enumerator) {
            if ([[file pathExtension] isEqual:@"h"]) {
                [paths addObject:file];
            }
        }

        return TranslationUnitForHeaderPaths(index, path, paths, compilerArguments);
    } else {
        return TranslationUnitForHeaderPaths(index, [path stringByDeletingLastPathComponent], @[path], compilerArguments);
    }
}

static NSString *GeneratedTitleForPaths(NSString *oldPath, NSString *newPath) {
    if (IsFrameworkAtPath(oldPath) && IsFrameworkAtPath(newPath)) {
        // Attempt to obtain API name and version information from the framework's Info.plist
        NSDictionary *oldInfo = [NSDictionary dictionaryWithContentsOfFile:[oldPath stringByAppendingPathComponent:@"Resources/Info.plist"]];
        NSDictionary *newInfo = [NSDictionary dictionaryWithContentsOfFile:[newPath stringByAppendingPathComponent:@"Resources/Info.plist"]];
        if (oldInfo != nil && newInfo != nil) {
            NSString *bundleName = newInfo[@"CFBundleName"];
            NSString *oldVersion = oldInfo[@"CFBundleShortVersionString"];
            NSString *newVersion = newInfo[@"CFBundleShortVersionString"];
            if (oldVersion == nil && newVersion == nil) {
                oldVersion = oldInfo[@"CFBundleVersion"];
                newVersion = newInfo[@"CFBundleVersion"];
            }

            if (bundleName != nil && oldVersion != nil && newVersion != nil && [oldVersion isEqualToString:newVersion] == NO) {
                return [NSString stringWithFormat:@"%@ %@ to %@ API Differences", bundleName, oldVersion, newVersion];
            }
        }
    }

    return nil;
}

int main(int argc, char *argv[]) {
    @autoreleasepool {
        NSString *oldPath;
        NSString *newPath;
        NSString *title = nil;
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
            { "title",        required_argument,  NULL,          't' },
            { "Xold",         required_argument,  NULL,          'x' },
            { "Xnew",         required_argument,  NULL,          'y' },
            { "version",      no_argument,        NULL,          'v' },
            { NULL,           0,                  NULL,           0  }
        };

        while ((optchar = getopt_long(argc, argv, "hont", longopts, NULL)) != -1) {
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
                case 't':
                    title = @(optarg);
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
            fprintf(stderr, "No new API path specified");
            return 1;
        }

        for (int i = 0; i < argc; i++) {
            // Unhandled arguments are passed to the compiler
            [oldCompilerArguments addObject:@(argv[i])];
            [newCompilerArguments addObject:@(argv[i])];
        }

        if (title == nil) {
            title = GeneratedTitleForPaths(oldPath, newPath);
        }

        // Parse the translation units

        PLClangSourceIndex *index = [PLClangSourceIndex indexWithOptions:PLClangIndexCreationDisplayDiagnostics];

        PLClangTranslationUnit *oldTU = TranslationUnitForPath(index, oldPath, oldCompilerArguments);
        if (oldTU == nil)
            return 1;

        PLClangTranslationUnit *newTU = TranslationUnitForPath(index, newPath, newCompilerArguments);
        if (newTU == nil)
            return 1;

        OCDAPIComparator *comparator = [[OCDAPIComparator alloc] initWithOldTranslationUnit:oldTU newTranslationUnit:newTU];

        NSArray *differences = [comparator computeDifferences];
        differences = [differences sortedArrayUsingComparator:^NSComparisonResult(OCDifference *obj1, OCDifference *obj2) {
            NSComparisonResult result = [[obj1.path lastPathComponent] caseInsensitiveCompare:[obj2.path lastPathComponent]];
            if (result != NSOrderedSame)
                return result;

            // TODO: Sort additions before modifications
            if (obj1.type != obj2.type) {
                return obj1.type == OCDifferenceTypeRemoval ? NSOrderedAscending : NSOrderedDescending;
            }

            if (obj1.lineNumber < obj2.lineNumber) {
                return NSOrderedAscending;
            } else if (obj1.lineNumber > obj2.lineNumber) {
                return NSOrderedDescending;
            }

            return [obj1.name caseInsensitiveCompare:obj2.name];
        }];

        NSString *lastFile = @"";

        for (OCDifference *difference in differences) {
            NSString *file = [difference.path lastPathComponent];
            if ([file isEqualToString:lastFile] == NO) {
                lastFile = file;
                printf("\n%s\n", [file UTF8String]);
            }

            printf("%s\n", [[difference description] UTF8String]);
        }

    }

    return 0;
}
