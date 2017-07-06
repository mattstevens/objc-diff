#import "OCDHTMLReportGenerator.h"
#import <mach-o/dyld.h>
#import <mach-o/getsect.h>
#import <mach-o/ldsyms.h>

@implementation OCDHTMLReportGenerator {
    NSString *_outputDirectory;
    OCDLinkMap *_linkMap;
}

- (instancetype)initWithOutputDirectory:(NSString *)directory linkMap:(OCDLinkMap *)linkMap {
    if (!(self = [super init]))
        return nil;

    _outputDirectory = [directory copy];
    _linkMap = linkMap;

    return self;
}

- (void)generateReportForDifferences:(OCDAPIDifferences *)differences title:(NSString *)title {
    NSError *error = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:_outputDirectory withIntermediateDirectories:YES attributes:nil error:&error]) {
        fprintf(stderr, "Error creating directory at path %s: %s\n", [_outputDirectory UTF8String], [[error description] UTF8String]);
        exit(1);
    }

    NSString *outputFile;
    NSData *cssData = [self embeddedResouceDataWithName:@"apidiff.css"];
    NSAssert(cssData != nil, @"apidiff.css not found in executable");

    outputFile = [_outputDirectory stringByAppendingPathComponent:@"apidiff.css"];
    if (![cssData writeToFile:outputFile options:0 error:&error]) {
        fprintf(stderr, "Error writing HTML report to %s: %s\n", [outputFile UTF8String], [[error description] UTF8String]);
        exit(1);
    }

    if (differences.modules.count == 1) {
        outputFile = [_outputDirectory stringByAppendingPathComponent:@"apidiff.html"];
        [self generateFileForDifferences:differences.modules.firstObject.differences title:title path:outputFile];
    } else {
        BOOL hasDifferences = NO;
        NSMutableString *html = [[NSMutableString alloc] init];

        [html appendString:@"<html>\n<head>\n"];

        if (title != nil) {
            [html appendFormat:@"<title>%@</title>\n", title];
        }

        [html appendString:@"<link rel=\"stylesheet\" href=\"apidiff.css\" type=\"text/css\" />\n"];
        [html appendString:@"<meta charset=\"utf-8\" />\n"];
        [html appendString:@"</head>\n<body>\n"];

        if (title != nil) {
            [html appendFormat:@"\n<h1>%@</h1>\n", title];
        }

        for (OCDModule *module in differences.modules) {
            if (module.differenceType == OCDifferenceTypeRemoval) {
                if (hasDifferences == NO) {
                    hasDifferences = YES;
                    [html appendString:@"\n<ul>\n"];
                }
                [html appendFormat:@"<li>%@ <span class=\"status removed\">(Removed)</span></li>\n", module.name];
                continue;
            } else if (module.differences.count < 1) {
                continue;
            } else {
                if (hasDifferences == NO) {
                    hasDifferences = YES;
                    [html appendString:@"\n<ul>\n"];
                }
                [html appendFormat:@"<li><a href=\"%@.html\">%@</a>", module.name, module.name];
                if (module.differenceType == OCDifferenceTypeAddition) {
                    [html appendString:@" <span class=\"status added\">(Added)</span>"];
                }
                [html appendString:@"</li>\n"];
            }

            NSString *moduleTitle;
            if (title != nil) {
                moduleTitle = [NSString stringWithFormat:@"%@ %@", module.name, title ?: @""];
            } else {
                moduleTitle = module.name;
            }

            NSString *fileName = [module.name stringByAppendingPathExtension:@"html"];
            outputFile = [_outputDirectory stringByAppendingPathComponent:fileName];
            [self generateFileForDifferences:module.differences title:moduleTitle path:outputFile];
        }

        if (hasDifferences) {
            [html appendString:@"</ul>\n"];
        } else {
            [html appendString:@"<div class=\"message\">No differences</div>\n"];
        }

        [html appendString:@"</body>\n</html>\n"];

        outputFile = [_outputDirectory stringByAppendingPathComponent:@"index.html"];
        if (![html writeToFile:outputFile atomically:NO encoding:NSUTF8StringEncoding error:&error]) {
            fprintf(stderr, "Error writing HTML report to %s: %s\n", [outputFile UTF8String], [[error description] UTF8String]);
            exit(1);
        }
    }
}

- (void)generateFileForDifferences:(NSArray<OCDifference *> *)differences title:(NSString *)title path:(NSString *)outputFile {
    NSMutableString *html = [[NSMutableString alloc] init];

    [html appendString:@"<html>\n<head>\n"];

    if (title != nil) {
        [html appendFormat:@"<title>%@</title>\n", title];
    }

    [html appendString:@"<link rel=\"stylesheet\" href=\"apidiff.css\" type=\"text/css\" />\n"];
    [html appendString:@"<meta charset=\"utf-8\" />\n"];
    [html appendString:@"</head>\n<body>\n"];

    if (title != nil) {
        [html appendFormat:@"\n<h1>%@</h1>\n", title];
    }

    if ([differences count] == 0) {
        [html appendString:@"<div class=\"message\">No differences</div>\n"];
    }

    NSString *lastFile = @"";
    OCDifferenceType lastType = 0;
    NSUInteger typeCount = 0;

    for (OCDifference *difference in differences) {
        NSString *file = difference.path;
        if ([file isEqualToString:lastFile] == NO) {
            if ([lastFile length] > 0) {
                if (typeCount > 0) {
                    [html appendString:@"</div>\n\n"];
                    typeCount = 0;
                }

                [html appendString:@"</div>\n"];
            }

            [html appendString:@"\n<div class=\"headerFile\">\n"];
            [html appendFormat:@"<div class=\"headerName\">%@</div>\n", file];

            lastFile = file;
            lastType = NSUIntegerMax;
        }

        if (difference.type != lastType) {
            if (typeCount > 0) {
                [html appendString:@"</div>\n\n"];
                typeCount = 0;
            }

            lastType = difference.type;

            [html appendFormat:@"\n<div class=\"differenceGroup\">\n"];
        }


        NSURL *link;
        if (_linkMap != nil && difference.USR != nil) {
            link = [_linkMap URLForUSR:difference.USR];
        }

        [html appendFormat:@"<div class=\"difference\"><span class=\"status %@\">%@</span> ", [[self stringForDifferenceType:difference.type] lowercaseString], [self stringForDifferenceType:difference.type]];

        if (link != nil) {
            [html appendFormat:@"<a href=\"%@\">", link];
        }

        [html appendFormat:@"%@", difference.name];

        if (link != nil) {
            [html appendFormat:@"</a>"];
        }

        [html appendFormat:@"</div>\n"];

        if ([difference.modifications count] > 0) {
            [html appendString:@"<table>\n"];

            // Header
            [html appendString:@"<tr><th></th>"];

            for (OCDModification *modification in difference.modifications) {
                [html appendFormat:@"<th>%@</th>", [OCDModification stringForModificationType:modification.type]];
            }

            [html appendString:@"</tr>\n"];

            // From
            [html appendString:@"<tr><th>From</th>"];

            for (OCDModification *modification in difference.modifications) {
                [html appendFormat:@"<td%@>%@</td>", [self isDeclarationType:modification.type] ? @" class=\"declaration\"" : @"", [modification.previousValue length] > 0 ? [self stringByHTMLEscapingString:modification.previousValue] : @"<em>none</em>"];
            }

            [html appendString:@"</tr>\n"];

            // To
            [html appendString:@"<tr><th>To</th>"];

            for (OCDModification *modification in difference.modifications) {
                [html appendFormat:@"<td%@>%@</td>", [self isDeclarationType:modification.type] ? @" class=\"declaration\"" : @"", [modification.currentValue length] > 0 ? [self stringByHTMLEscapingString:modification.currentValue] : @"<em>none</em>"];
            }

            [html appendString:@"</tr>\n"];

            [html appendString:@"</table>\n"];
            [html appendString:@"<br>\n"];
        }

        typeCount++;
    }

    if (typeCount > 0) {
        [html appendString:@"</div>\n\n"];
    }

    if ([lastFile length] > 0) {
        [html appendString:@"</div>\n"];
    }

    [html appendString:@"</body>\n</html>\n"];

    NSError *error;
    if (![html writeToFile:outputFile atomically:NO encoding:NSUTF8StringEncoding error:&error]) {
        fprintf(stderr, "Error writing HTML report to %s: %s\n", [outputFile UTF8String], [[error description] UTF8String]);
        exit(1);
    }
}

- (NSData *)embeddedResouceDataWithName:(NSString *)name {
    unsigned long size = 0;
    uint8_t *data = getsectiondata(&_mh_execute_header, "__TEXT", [name UTF8String], &size);
    return data ? [NSData dataWithBytesNoCopy:data length:size freeWhenDone:NO] : nil;
}

- (NSString *)stringByHTMLEscapingString:(NSString *)string {
    return CFBridgingRelease(CFXMLCreateStringByEscapingEntities(kCFAllocatorDefault, (__bridge CFStringRef)string, NULL));
}

- (NSString *)stringForDifferenceType:(OCDifferenceType)type {
    switch (type) {
        case OCDifferenceTypeAddition:
            return @"Added";

        case OCDifferenceTypeRemoval:
            return @"Removed";

        case OCDifferenceTypeModification:
            return @"Modified";
    }

    abort();
}

- (BOOL)isDeclarationType:(OCDModificationType)type {
    switch (type) {
        case OCDModificationTypeDeclaration:
        case OCDModificationTypeReplacement:
            return YES;

        default:
            return NO;
    }
}

@end
