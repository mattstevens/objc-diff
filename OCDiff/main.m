#import <Foundation/Foundation.h>
#import <ObjectDoc/ObjectDoc.h>
#import <ObjectDoc/PLClang.h>
#import <getopt.h>

#import "OCDAPIComparator.h"
#import "OCDTextReportGenerator.h"

enum OCDReportTypes {
    OCDReportTypeText = 1 << 0,
    OCDReportTypeXML  = 1 << 1,
    OCDReportTypeHTML = 1 << 2
};

enum OCDAPIDestination {
    OCDAPIOld  = 1 << 0,
    OCDAPINew  = 1 << 1,
    OCDAPIBoth = OCDAPIOld | OCDAPINew
};

static NSString *sdkPath;
static NSString *sdkVersion;

static void print_usage(void) {
    printf(""
    "Usage: ocdiff [--old <path to old API>] --new <path to new API> [options]\n"
    "\n"
    "Generates an Objective-C API diff report.\n"
    "\n"
    "Options:\n"
    "  -h, --help           Show this help message and exit\n"
    "      --sdk <name>     Use the specified SDK\n"
    "  -o, --old <path>     Path to the old API header(s)\n"
    "  -n, --new <path>     Path to the new API header(s)\n"
    "  -t, --title          Title of the generated report\n"
    "      --args <args>    Compiler arguments for both API versions\n"
    "      --oldargs <args> Compiler arguments for the old API version\n"
    "      --newargs <args> Compiler arguments for the new API version\n"
    "      --version        Show the version and exit\n");
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

    if (translationUnit == nil) {
        fprintf(stderr, "Failed to create translation unit: %s\n", [[error description] UTF8String]);
        return nil;
    }

    if (translationUnit.didFail) {
        for (PLClangDiagnostic *diagnostic in translationUnit.diagnostics) {
            fprintf(stderr, "%s\n", [diagnostic.formattedErrorMessage UTF8String]);
        }
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

int main(int argc, char *argv[]) {
    @autoreleasepool {
        NSString *sdk;
        NSString *oldPath;
        NSString *newPath;
        NSString *title;
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
            { "sdk",          required_argument,  NULL,          's' },
            { "old",          required_argument,  NULL,          'o' },
            { "new",          required_argument,  NULL,          'n' },
            { "title",        required_argument,  NULL,          't' },
            { "args",         no_argument,        NULL,          'x' },
            { "oldargs",      no_argument,        NULL,          'y' },
            { "newargs",      no_argument,        NULL,          'z' },
            { "version",      no_argument,        NULL,          'v' },
            { NULL,           0,                  NULL,           0  }
        };

        BOOL parseCompilerArguments = NO;

        while (!parseCompilerArguments && (optchar = getopt_long(argc, argv, "ho:n:t:", longopts, NULL)) != -1) {
            switch (optchar) {
                case 'h':
                    print_usage();
                    return 0;
                case 's':
                    sdk = @(optarg);
                    break;
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
                    printf("ocdiff %s\n%s\n", "DEV", [PLClangGetVersionString() UTF8String]);
                    return 0;
                case 'x':
                case 'y':
                case 'z':
                    parseCompilerArguments = YES;
                    optind--;
                    break;
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

        if ([newPath length] < 1) {
            fprintf(stderr, "No new API path specified.\n");
            print_usage();
            return 1;
        }

        if (parseCompilerArguments == NO && argc > 0) {
            fprintf(stderr, "unknown argument %s\n", argv[0]);
            return 1;
        }

        int argDestination = 0;

        for (int i = 0; i < argc; i++) {
            NSString *argument = @(argv[i]);
            if ([argument isEqualToString:@"--args"]) {
                argDestination = OCDAPIBoth;
            } else if ([argument isEqualToString:@"--oldargs"]) {
                argDestination = OCDAPIOld;
            } else if ([argument isEqualToString:@"--newargs"]) {
                argDestination = OCDAPINew;
            } else {
                assert(argDestination != 0 && "No argument destination");

                if (argDestination & OCDAPIOld) {
                    [oldCompilerArguments addObject:argument];
                }

                if (argDestination & OCDAPINew) {
                    [newCompilerArguments addObject:argument];
                }
            }
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

        OCDAPIComparator *comparator = [[OCDAPIComparator alloc] initWithOldTranslationUnit:oldTU newTranslationUnit:newTU];

        NSArray *differences = [comparator computeDifferences];

        if (reportTypes == 0) {
            reportTypes = OCDReportTypeText;
        }

        if (reportTypes & OCDReportTypeText) {
            OCDTextReportGenerator *generator = [[OCDTextReportGenerator alloc] init];
            [generator generateReportForDifferences:differences title:title];
        }
    }

    return 0;
}
