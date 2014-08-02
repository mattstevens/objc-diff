#import <Foundation/Foundation.h>
#import <ObjectDoc/ObjectDoc.h>
#import <ObjectDoc/PLClang.h>
#import <getopt.h>

#import "NSString+OCDPathUtilities.h"
#import "OCDAPIComparator.h"
#import "OCDHTMLReportGenerator.h"
#import "OCDTextReportGenerator.h"
#import "OCDXMLReportGenerator.h"

enum OCDReportTypes {
    OCDReportTypeText = 1 << 0,
    OCDReportTypeXML  = 1 << 1,
    OCDReportTypeHTML = 1 << 2
};

static NSString *sdkPath;
static NSString *sdkVersion;

static void print_usage(void) {
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *name = [bundle objectForInfoDictionaryKey:@"CFBundleName"];

    printf(""
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

static BOOL IsFrameworkAtPath(NSString *path) {
    return [[path pathExtension] isEqualToString:@"framework"];
}

/**
 * Returns a translation unit for the specified header paths.
 *
 * To represent the API in a single translation unit and to improve performance a virtual umbrella header is
 * generated importing all of the specified header paths. This way system headers like Foundation.h that
 * include many declarations are only iterated over once per API, instead of once per header.
 */
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

    if (translationUnit == nil) {
        fprintf(stderr, "Failed to create translation unit: %s\n", [[error description] UTF8String]);
        return nil;
    }

    if (translationUnit.didFail) {
        for (PLClangDiagnostic *diagnostic in translationUnit.diagnostics) {
            if (diagnostic.severity >= PLClangDiagnosticSeverityError) {
                fprintf(stderr, "%s\n", [diagnostic.formattedErrorMessage UTF8String]);
            }
        }
        return nil;
    }

    return translationUnit;
}

static PLClangTranslationUnit *TranslationUnitForPath(PLClangSourceIndex *index, NSString *path, NSArray *compilerArguments) {
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
        return TranslationUnitForHeaderPaths(index, [path stringByDeletingLastPathComponent], @[[path lastPathComponent]], compilerArguments);
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

static NSString *XCRunResultForArguments(NSArray *arguments) {
    NSPipe *outputPipe = [NSPipe pipe];
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/xcrun";
    task.arguments = arguments;
    task.standardInput = [NSPipe pipe];
    task.standardOutput = outputPipe;
    task.standardError = [NSPipe pipe];
    [task launch];
    [task waitUntilExit];

    if ([task terminationStatus] != 0) {
        return nil;
    }

    NSData *resultData = [outputPipe.fileHandleForReading readDataToEndOfFile];
    NSString *path = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
    path = [path stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return path;
}

static NSString *PathForSDK(NSString *sdk) {
    NSString *result = XCRunResultForArguments(@[@"--sdk", sdk, @"--show-sdk-path"]);
    if (result == nil) {
        fprintf(stderr, "Could not locate SDK \"%s\" using xcrun\n", [sdk UTF8String]);
        exit(1);
    }

    return result;
}

static NSString *VersionForSDK(NSString *sdk) {
    NSString *result = XCRunResultForArguments(@[@"--sdk", sdk, @"--show-sdk-version"]);
    if (result == nil) {
        fprintf(stderr, "Could not identify version of SDK \"%s\" using xcrun\n", [sdk UTF8String]);
        exit(1);
    }

    return result;
}

static BOOL ArrayContainsStringWithPrefix(NSArray *array, NSString *prefix) {
    for (NSString *string in array) {
        if ([string hasPrefix:prefix]) {
            return YES;
        }
    }

    return NO;
}

static void ApplySDKToCompilerArguments(NSString *sdk, NSMutableArray *compilerArguments) {
    if ([compilerArguments containsObject:@"-isysroot"] == NO && getenv("SDKROOT") == NULL) {
        if (sdkPath == nil) {
            sdkPath = PathForSDK(sdk);
        }

        [compilerArguments addObjectsFromArray:@[@"-isysroot", sdkPath]];
    }

    // A deployment target must be specified for iOS
    if ([sdk rangeOfString:@"iphoneos"].location != NSNotFound) {
        if (ArrayContainsStringWithPrefix(compilerArguments, @"-mios-version-min") == NO && getenv("IPHONEOS_DEPLOYMENT_TARGET") == NULL) {
            if (sdkVersion == nil) {
                sdkVersion = VersionForSDK(sdk);
            }

            [compilerArguments addObject:[NSString stringWithFormat:@"-mios-version-min=%@", sdkVersion]];
        }
    } else if ([sdk rangeOfString:@"iphonesimulator"].location != NSNotFound) {
        if (ArrayContainsStringWithPrefix(compilerArguments, @"-mios-simulator-version-min") == NO && getenv("IOS_SIMULATOR_DEPLOYMENT_TARGET") == NULL) {
            if (sdkVersion == nil) {
                sdkVersion = VersionForSDK(sdk);
            }

            [compilerArguments addObject:[NSString stringWithFormat:@"-mios-simulator-version-min=%@", sdkVersion]];
        }
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
        NSString *sdk;
        NSString *oldPath;
        NSString *newPath;
        NSString *title;
        NSString *htmlOutputDirectory;
        NSMutableArray *oldCompilerArguments = [NSMutableArray array];
        NSMutableArray *newCompilerArguments = [NSMutableArray array];
        int reportTypes = 0;
        int optchar;

        [oldCompilerArguments addObject:@"-x"];
        [oldCompilerArguments addObject:@"objective-c-header"];
        [newCompilerArguments addObject:@"-x"];
        [newCompilerArguments addObject:@"objective-c-header"];

        static struct option longopts[] = {
            { "help",         no_argument,        NULL,          'h' },
            { "title",        required_argument,  NULL,          't' },
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
                    print_usage();
                    return 0;
                case 't':
                    title = @(optarg);
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
                    sdk = @(optarg);
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
            print_usage();
            return 1;
        }

        if ((reportTypes & OCDReportTypeText) && (reportTypes & OCDReportTypeXML)) {
            fprintf(stderr, "Only one of --text or --xml may be specified\n");
            return 1;
        }

        if (title == nil) {
            title = GeneratedTitleForPaths(oldPath, newPath);
        }

        if (sdk == nil) {
            sdk = @"macosx";
        }

        ApplySDKToCompilerArguments(sdk, oldCompilerArguments);
        ApplySDKToCompilerArguments(sdk, newCompilerArguments);

        // Parse the translation units

        PLClangSourceIndex *index = [PLClangSourceIndex indexWithOptions:0];

        PLClangTranslationUnit *oldTU = nil;
        if (oldPath != nil) {
            oldTU = TranslationUnitForPath(index, oldPath, oldCompilerArguments);
            if (oldTU == nil) {
                return 1;
            }
        }

        PLClangTranslationUnit *newTU = TranslationUnitForPath(index, newPath, newCompilerArguments);
        if (newTU == nil) {
            return 1;
        }

        NSArray *differences = [OCDAPIComparator differencesBetweenOldTranslationUnit:oldTU newTranslationUnit:newTU];

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
            OCDHTMLReportGenerator *htmlGenerator = [[OCDHTMLReportGenerator alloc] initWithOutputDirectory:htmlOutputDirectory];
            [htmlGenerator generateReportForDifferences:differences title:title];
        }
    }

    return 0;
}
