#import <Foundation/Foundation.h>
#import <ObjectDoc/ObjectDoc.h>
#import <ObjectDoc/PLClang.h>
#import <getopt.h>

#import "NSString+OCDPathUtilities.h"
#import "OCDAPIComparator.h"
#import "OCDAPIDifferences.h"
#import "OCDSDK.h"
#import "OCDHTMLReportGenerator.h"
#import "OCDTextReportGenerator.h"
#import "OCDTitleGenerator.h"
#import "OCDXMLReportGenerator.h"

enum OCDReportTypes {
    OCDReportTypeText = 1 << 0,
    OCDReportTypeXML  = 1 << 1,
    OCDReportTypeHTML = 1 << 2
};

static void PrintUsage(void) {
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *name = [bundle objectForInfoDictionaryKey:@"CFBundleName"];

    printf(
    "Usage: %s [--old <path to old API>] --new <path to new API> [options]\n"
    "\n"
    "Generates an Objective-C API diff report.\n"
    "\n"
    "API paths may be specified as a path to a framework, a path to a single\n"
    "header, or a path to a directory of headers.\n"
    "\n"
    "Options:\n"
    "  --help             Show this help message and exit\n"
    "  --title            Title of the generated report\n"
    "  --text             Write a text report to standard output (the default)\n"
    "  --xml              Write an XML report to standard output\n"
    "  --html <directory> Write an HTML report to the specified directory\n"
    "  --sdk <name>       Use the specified SDK\n"
    "  --old <path>       Path to the old API\n"
    "  --new <path>       Path to the new API\n"
    "  --args <args>      Compiler arguments for both API versions\n"
    "  --oldargs <args>   Compiler arguments for the old API version\n"
    "  --newargs <args>   Compiler arguments for the new API version\n"
    "  --version          Show the version and exit\n",
    [name UTF8String]);
}

NSString *ContainingFrameworkForPath(NSString *path) {
    do {
        if ([path ocd_isFrameworkPath]) {
            return path;
        }
    } while ((path = [path stringByDeletingLastPathComponent]) && [path length] > 1);

    return nil;
}

static NSDictionary<NSString *, NSString *> *FrameworksForSDKAtPath(NSString *sdkPath) {
    NSMutableDictionary<NSString *, NSString *> *frameworks = [NSMutableDictionary dictionary];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSString *frameworksPath = [sdkPath stringByAppendingPathComponent:@"System/Library/Frameworks"];
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:frameworksPath error:nil];
    for (NSString *frameworkName in contents) {
        NSString *frameworkPath = [frameworksPath stringByAppendingPathComponent:frameworkName];
        NSString *headersPath = [frameworkPath stringByAppendingPathComponent:@"Headers"];
        if ([frameworkPath ocd_isFrameworkPath] && [fileManager fileExistsAtPath:headersPath]) {
            frameworks[frameworkName] = frameworkPath;
        }
    }

    NSString *includePath = [sdkPath stringByAppendingPathComponent:@"usr/include"];
    NSDictionary<NSString *, NSString *> *supportedModules = @{
        @"CommonCrypto": @"CommonCrypto",
        @"dispatch": @"Dispatch",
        @"objc": @"Objective-C",
        @"os": @"os",
        @"xpc": @"XPC"
    };

    for (NSString *directoryName in supportedModules) {
        NSString *path = [includePath stringByAppendingPathComponent:directoryName];
        if ([fileManager fileExistsAtPath:path]) {
            NSString *displayName = supportedModules[directoryName];
            frameworks[displayName] = path;
        }
    }

    return frameworks;
}

static PLClangTranslationUnit *TranslationUnitForSource(PLClangSourceIndex *index, NSString *baseDirectory, NSString *source, NSArray *compilerArguments, BOOL printErrors) {

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

    if (translationUnit == nil) {
        fprintf(stderr, "Failed to create translation unit: %s\n", [[error description] UTF8String]);
        return nil;
    }

    if (translationUnit.didFail) {
        if (printErrors) {
            for (PLClangDiagnostic *diagnostic in translationUnit.diagnostics) {
                if (diagnostic.severity >= PLClangDiagnosticSeverityError) {
                    fprintf(stderr, "%s\n", [diagnostic.formattedErrorMessage UTF8String]);
                }
            }
        }
        return nil;
    }

    return translationUnit;
}

/**
 * Returns a translation unit for the specified header paths.
 *
 * To represent the API in a single translation unit and to improve performance a virtual umbrella header is
 * generated importing all of the specified header paths. This way system headers like Foundation.h that
 * include many declarations are only iterated over once per API, instead of once per header.
 */
static PLClangTranslationUnit *TranslationUnitForHeaderPaths(PLClangSourceIndex *index, NSString *baseDirectory, NSArray *paths, NSArray *compilerArguments, BOOL printErrors) {
    NSMutableString *source = [[NSMutableString alloc] init];
    for (NSString *path in paths) {
        [source appendFormat:@"#import \"%@\"\n", path];
    }

    return TranslationUnitForSource(index, baseDirectory, source, compilerArguments, printErrors);
}

static PLClangTranslationUnit *TranslationUnitForPath(PLClangSourceIndex *index, NSString *path, NSArray *compilerArguments, BOOL printErrors) {
    BOOL isDirectory = NO;

    path = [path ocd_absolutePath];

    if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory] == NO) {
        fprintf(stderr, "%s not found\n", [path UTF8String]);
        return nil;
    }

    if (isDirectory) {
        // If the specified path is a framework, search its headers and automatically add its parent
        // directory to the framework search paths. This enables #import <FrameworkName/Header.h> to
        // be resolved without any additional configuration.
        if ([path ocd_isFrameworkPath]) {
            compilerArguments = [compilerArguments arrayByAddingObject:[@"-F" stringByAppendingString:[path stringByDeletingLastPathComponent]]];
            path = [path stringByAppendingPathComponent:@"Headers"];
            return TranslationUnitForPath(index, path, compilerArguments, printErrors);
        }

        NSMutableArray *paths = [NSMutableArray array];
        NSDirectoryEnumerator *enumerator  = [[NSFileManager defaultManager] enumeratorAtPath:path];
        for (NSString *file in enumerator) {
            if ([[file pathExtension] isEqual:@"h"]) {
                [paths addObject:file];
            }
        }

        return TranslationUnitForHeaderPaths(index, path, paths, compilerArguments, printErrors);
    } else {
        NSString *containingFrameworkPath = ContainingFrameworkForPath(path);
        if (containingFrameworkPath != nil) {
            compilerArguments = [compilerArguments arrayByAddingObject:[@"-F" stringByAppendingString:[containingFrameworkPath stringByDeletingLastPathComponent]]];
        }

        return TranslationUnitForHeaderPaths(index, [path stringByDeletingLastPathComponent], @[[path lastPathComponent]], compilerArguments, printErrors);
    }
}

static PLClangTranslationUnit *TranslationUnitForSDKFramework(PLClangSourceIndex *index, NSString *path, NSArray *compilerArguments) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *frameworkName = [[path lastPathComponent] stringByDeletingPathExtension];

    path = [path ocd_absolutePath];

    if ([path ocd_isFrameworkPath]) {
        path = [path stringByAppendingPathComponent:@"Headers"];
    }

    if ([fileManager fileExistsAtPath:path] == NO) {
        fprintf(stderr, "%s not found\n", [path UTF8String]);
        return nil;
    }

    NSString *umbrellaHeader = [frameworkName stringByAppendingPathExtension:@"h"];
    BOOL umbrellaHeaderExists = [fileManager fileExistsAtPath:[path stringByAppendingPathComponent:umbrellaHeader]];

    NSDirectoryEnumerator *enumerator  = [fileManager enumeratorAtPath:path];

    NSMutableString *source = [[NSMutableString alloc] init];

    // If an umbrella header exists, include it first
    if (umbrellaHeaderExists) {
        [source appendFormat:@"#import <%@/%@>\n", frameworkName, umbrellaHeader];
    }

    for (NSString *file in enumerator) {
        if ([[file pathExtension] isEqual:@"h"]) {
            if (umbrellaHeaderExists && [file isEqualToString:umbrellaHeader]) {
                continue;
            }

            [source appendFormat:@"#import <%@/%@>\n", frameworkName, file];
        }
    }

    PLClangTranslationUnit *translationUnit = TranslationUnitForSource(index, path, source, compilerArguments, !umbrellaHeaderExists);
    if (translationUnit == nil && umbrellaHeaderExists) {
        // Some SDK frameworks can only be parsed through their umbrella header.
        // If parsing all headers fails, retry through the umbrella header.
        // TODO: Look into using module definition to avoid this issue.
        NSString *umbrellaSource = [NSString stringWithFormat:@"#import <%@/%@.h>\n", frameworkName, frameworkName];
        translationUnit = TranslationUnitForSource(index, path, umbrellaSource, compilerArguments, YES);
    }

    return translationUnit;
}

static OCDAPIDifferences *DiffSDKs(NSString *oldSDKPath, NSArray *oldCompilerArguments, NSString *newSDKPath, NSArray *newCompilerArguments) {
    NSMutableArray *modules = [NSMutableArray array];
    NSDictionary<NSString *, NSString *> *oldFrameworks = FrameworksForSDKAtPath(oldSDKPath);
    NSDictionary<NSString *, NSString *> *newFrameworks = FrameworksForSDKAtPath(newSDKPath);

    // The following frameworks cannot currently be parsed.
    NSArray *unsupportedFrameworks = @[
        @"IOKit.framework", // Uses C++ unconditionally
        @"Kernel.framework", // Must include headers in specific order
        @"Tk.framework" // Requires X11
    ];

    PLClangSourceIndex *index = [PLClangSourceIndex indexWithOptions:0];

    for (NSString *frameworkName in oldFrameworks) {
        if (newFrameworks[frameworkName] == nil) {
            [modules addObject:[OCDModule moduleWithName:[frameworkName stringByDeletingPathExtension]
                                          differenceType:OCDifferenceTypeRemoval
                                             differences:nil]];
        }
    }

    NSSortDescriptor *nameSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES selector:@selector(localizedStandardCompare:)];
    NSArray *orderedNewFrameworks = [newFrameworks.allKeys sortedArrayUsingDescriptors:@[nameSortDescriptor]];

    for (NSString *frameworkName in orderedNewFrameworks) {
        @autoreleasepool {
            if ([unsupportedFrameworks containsObject:frameworkName]) {
                printf("Skipping %s (unsupported)\n", frameworkName.UTF8String);
                continue;
            }

            printf("Comparing %s\n", frameworkName.UTF8String);

            NSString *oldPath = oldFrameworks[frameworkName];
            NSString *newPath = newFrameworks[frameworkName];

            if (oldPath != nil) {
                PLClangTranslationUnit *oldTU = TranslationUnitForSDKFramework(index, oldPath, oldCompilerArguments);
                if (oldTU == nil) {
                    continue;
                }

                PLClangTranslationUnit *newTU = TranslationUnitForSDKFramework(index, newPath, newCompilerArguments);
                if (newTU == nil) {
                    continue;
                }

                OCDAPISource *oldSource = [OCDAPISource APISourceWithTranslationUnit:oldTU containingPath:oldPath includeSystemHeaders:YES];
                OCDAPISource *newSource = [OCDAPISource APISourceWithTranslationUnit:newTU containingPath:newPath includeSystemHeaders:YES];
                NSArray<OCDifference *> *differences = [OCDAPIComparator differencesBetweenOldAPISource:oldSource newAPISource:newSource];

                [modules addObject:[OCDModule moduleWithName:[frameworkName stringByDeletingPathExtension]
                                              differenceType:OCDifferenceTypeModification
                                                 differences:differences]];
            } else {
                PLClangTranslationUnit *newTU = TranslationUnitForSDKFramework(index, newPath, newCompilerArguments);
                if (newTU == nil) {
                    continue;
                }

                OCDAPISource *newSource = [OCDAPISource APISourceWithTranslationUnit:newTU containingPath:newPath includeSystemHeaders:YES];
                NSArray<OCDifference *> *differences = [OCDAPIComparator differencesBetweenOldAPISource:nil newAPISource:newSource];

                [modules addObject:[OCDModule moduleWithName:[frameworkName stringByDeletingPathExtension]
                                              differenceType:OCDifferenceTypeAddition
                                                 differences:differences]];
            }
        }
    }

    [modules sortUsingComparator:^NSComparisonResult(OCDModule *obj1, OCDModule *obj2) {
        return [obj1.name localizedStandardCompare:obj2.name];
    }];

    return [OCDAPIDifferences APIDifferencesWithModules:modules];
}

static BOOL ArrayContainsStringWithPrefix(NSArray *array, NSString *prefix) {
    for (NSString *string in array) {
        if ([string hasPrefix:prefix]) {
            return YES;
        }
    }

    return NO;
}

static void ApplySDKToCompilerArguments(OCDSDK *sdk, NSMutableArray *compilerArguments) {
    if ([compilerArguments containsObject:@"-isysroot"] == NO) {
        [compilerArguments addObjectsFromArray:@[@"-isysroot", [sdk.path stringByStandardizingPath]]];
    }

    if (ArrayContainsStringWithPrefix(compilerArguments, sdk.deploymentTargetCompilerArgument) == NO) {
        const char *environmentDeploymentTarget = getenv([sdk.deploymentTargetEnvironmentVariable UTF8String]);
        NSString *deploymentTarget = environmentDeploymentTarget ? @(environmentDeploymentTarget) : sdk.deploymentTarget;
        [compilerArguments addObject:[NSString stringWithFormat:@"%@=%@", sdk.deploymentTargetCompilerArgument, deploymentTarget]];
        [compilerArguments addObject:[NSString stringWithFormat:@"-DAPI_TO_BE_DEPRECATED=%@", deploymentTarget]];
    }

    if (sdk.defaultArchitecture != nil && [compilerArguments containsObject:@"-arch"] == NO) {
        [compilerArguments addObject:@"-arch"];
        [compilerArguments addObject:sdk.defaultArchitecture];
    }
}

static NSArray *GetCompilerArguments(int argc, char *argv[]) {
    NSMutableArray *arguments = [[NSMutableArray alloc] init];

    for (int i = 0; i < argc; i++) {
        NSString *argument = @(argv[i]);
        if ([argument hasPrefix:@"--"]) {
            break;
        }

        [arguments addObject:argument];
    }

    return arguments;
}

int main(int argc, char *argv[]) {
    @autoreleasepool {
        NSString *sdkName;
        NSString *oldPath;
        NSString *newPath;
        NSString *title;
        NSString *linkMapPath;
        NSString *htmlOutputDirectory;
        NSMutableArray *oldCompilerArguments = [NSMutableArray arrayWithObjects:@"-x", @"objective-c-header", nil];
        NSMutableArray *newCompilerArguments = [oldCompilerArguments mutableCopy];
        int reportTypes = 0;
        int optchar;

        static struct option longopts[] = {
            { "help",         no_argument,        NULL,          'h' },
            { "title",        required_argument,  NULL,          't' },
            { "linkmap",      required_argument,  NULL,          'l' },
            { "text",         no_argument,        NULL,          'T' },
            { "xml",          no_argument,        NULL,          'X' },
            { "html",         required_argument,  NULL,          'H' },
            { "sdk",          required_argument,  NULL,          's' },
            { "old",          required_argument,  NULL,          'o' },
            { "new",          required_argument,  NULL,          'n' },
            { "args",         no_argument,        NULL,          'A' },
            { "oldargs",      no_argument,        NULL,          'O' },
            { "newargs",      no_argument,        NULL,          'N' },
            { "version",      no_argument,        NULL,          'v' },
            { NULL,           0,                  NULL,           0  }
        };

        while ((optchar = getopt_long(argc, argv, "h", longopts, NULL)) != -1) {
            switch (optchar) {
                case 'h':
                    PrintUsage();
                    return 0;
                case 't':
                    title = @(optarg);
                    break;
                case 'l':
                    linkMapPath = @(optarg);
                    break;
                case 'T':
                    reportTypes |= OCDReportTypeText;
                    break;
                case 'X':
                    reportTypes |= OCDReportTypeXML;
                    break;
                case 'H':
                    reportTypes |= OCDReportTypeHTML;
                    htmlOutputDirectory = @(optarg);
                    break;
                case 's':
                    sdkName = @(optarg);
                    break;
                case 'o':
                    oldPath = @(optarg);
                    break;
                case 'n':
                    newPath = @(optarg);
                    break;
                case 'v':
                {
                    NSBundle *bundle = [NSBundle mainBundle];
                    NSString *name = [bundle objectForInfoDictionaryKey:@"CFBundleName"];
                    NSString *version = [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
                    printf("%s %s\nBased on %s\n",
                           [name UTF8String],
                           [version UTF8String],
                           [PLClangGetVersionString() UTF8String]);

                    return 0;
                }
                case 'A':
                {
                    NSArray *arguments = GetCompilerArguments(argc - optind, argv + optind);
                    [oldCompilerArguments addObjectsFromArray:arguments];
                    [newCompilerArguments addObjectsFromArray:arguments];
                    optind += [arguments count];
                    break;
                }
                case 'O':
                {
                    NSArray *arguments = GetCompilerArguments(argc - optind, argv + optind);
                    [oldCompilerArguments addObjectsFromArray:arguments];
                    optind += [arguments count];
                    break;
                }
                case 'N':
                {
                    NSArray *arguments = GetCompilerArguments(argc - optind, argv + optind);
                    [newCompilerArguments addObjectsFromArray:arguments];
                    optind += [arguments count];
                    break;
                }
                case 0:
                    break;
                case '?':
                    return 1;
                default:
                    fprintf(stderr, "unhandled option -%c\n", optchar);
                    break;
            }
        }
        argc -= optind;
        argv += optind;

        if (argc > 0) {
            fprintf(stderr, "Unknown argument \"%s\"\n", argv[0]);
            return 1;
        }

        if ([newPath length] < 1) {
            fprintf(stderr, "No new API path specified\n");
            PrintUsage();
            return 1;
        }

        if ((reportTypes & OCDReportTypeText) && (reportTypes & OCDReportTypeXML)) {
            fprintf(stderr, "Only one of --text or --xml may be specified\n");
            return 1;
        }

        if (title == nil) {
            title = [OCDTitleGenerator reportTitleForOldPath:oldPath newPath:newPath];
        }

        if (sdkName == nil) {
            const char *sdkRoot = getenv("SDKROOT");
            if (sdkRoot != nil) {
                sdkName = @(sdkRoot);
            } else {
                sdkName = @"macosx";
            }
        }

        OCDSDK *defaultSDK = nil;
        OCDSDK *oldSDK = [OCDSDK containingSDKForPath:oldPath];
        OCDSDK *newSDK = [OCDSDK containingSDKForPath:newPath];

        BOOL oldPathIsSDK = [oldSDK.path isEqualToString:oldPath];
        BOOL newPathIsSDK = [newSDK.path isEqualToString:newPath];

        if (oldPathIsSDK != newPathIsSDK) {
            fprintf(stderr, "An SDK can only be compared against another SDK\n");
            return 1;
        }

        if (oldSDK == nil || newSDK == nil) {
            defaultSDK = [OCDSDK SDKForName:sdkName];
            if (defaultSDK == nil) {
                fprintf(stderr, "Could not locate SDK \"%s\"\n", [sdkName UTF8String]);
                return 1;
            }
        }

        ApplySDKToCompilerArguments(oldSDK ?: defaultSDK, oldCompilerArguments);
        ApplySDKToCompilerArguments(newSDK ?: defaultSDK, newCompilerArguments);

        OCDAPIDifferences *differences;

        if (oldPathIsSDK) {
            differences = DiffSDKs(oldPath, oldCompilerArguments, newPath, newCompilerArguments);
        } else {
            PLClangSourceIndex *index = [PLClangSourceIndex indexWithOptions:0];

            OCDAPISource *oldSource;
            if (oldPath != nil) {

                if (oldSDK != nil) {
                    PLClangTranslationUnit *oldTU = TranslationUnitForSDKFramework(index, oldPath, oldCompilerArguments);
                    oldSource = [OCDAPISource APISourceWithTranslationUnit:oldTU containingPath:oldPath includeSystemHeaders:YES];
                } else {
                    PLClangTranslationUnit *oldTU = TranslationUnitForPath(index, oldPath, oldCompilerArguments, YES);
                    oldSource = [OCDAPISource APISourceWithTranslationUnit:oldTU];
                }

                if (oldSource == nil) {
                    return 1;
                }
            }

            OCDAPISource *newSource;

            if (newSDK != nil) {
                PLClangTranslationUnit *newTU = TranslationUnitForSDKFramework(index, newPath, newCompilerArguments);
                newSource = [OCDAPISource APISourceWithTranslationUnit:newTU containingPath:newPath includeSystemHeaders:YES];
            } else {
                PLClangTranslationUnit *newTU = TranslationUnitForPath(index, newPath, newCompilerArguments, YES);
                newSource = [OCDAPISource APISourceWithTranslationUnit:newTU];
            }

            if (newSource == nil) {
                return 1;
            }

            NSString *moduleName = [[newPath lastPathComponent] stringByDeletingPathExtension];
            NSArray<OCDifference *> *moduleDifferences = [OCDAPIComparator differencesBetweenOldAPISource:oldSource newAPISource:newSource];
            OCDModule *module = [OCDModule moduleWithName:moduleName differenceType:OCDifferenceTypeModification differences:moduleDifferences];
            differences = [OCDAPIDifferences APIDifferencesWithModules:@[module]];
        }

        if (reportTypes == 0) {
            reportTypes = OCDReportTypeText;
        }

        if (reportTypes & OCDReportTypeText) {
            OCDTextReportGenerator *generator = [[OCDTextReportGenerator alloc] init];
            [generator generateReportForDifferences:differences title:title];
        }

        if (reportTypes & OCDReportTypeXML) {
            OCDXMLReportGenerator *generator = [[OCDXMLReportGenerator alloc] init];
            [generator generateReportForDifferences:differences title:title];
        }

        if (reportTypes & OCDReportTypeHTML) {
            OCDLinkMap *linkMap = [[OCDLinkMap alloc] initWithPath:linkMapPath];
            OCDHTMLReportGenerator *htmlGenerator = [[OCDHTMLReportGenerator alloc] initWithOutputDirectory:htmlOutputDirectory linkMap:linkMap];
            [htmlGenerator generateReportForDifferences:differences title:title];
        }
    }

    return 0;
}
