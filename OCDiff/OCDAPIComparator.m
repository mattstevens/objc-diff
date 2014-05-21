#import "OCDAPIComparator.h"
#import <ObjectDoc/ObjectDoc.h>

@implementation OCDAPIComparator {
    NSSet *_oldTranslationUnits;
    NSSet *_newTranslationUnits;
    NSMutableDictionary *_fileHandles;
    NSMutableDictionary *_unsavedFileData;
}

- (instancetype)initWithOldTranslationUnits:(NSSet *)oldTranslationUnits newTranslationUnits:(NSSet *)newTranslationUnits {
    return [self initWithOldTranslationUnits:oldTranslationUnits newTranslationUnits:newTranslationUnits unsavedFiles:nil];
}

- (instancetype)initWithOldTranslationUnits:(NSSet *)oldTranslationUnits newTranslationUnits:(NSSet *)newTranslationUnits unsavedFiles:(NSArray *)unsavedFiles {
    if (!(self = [super init]))
        return nil;

    _oldTranslationUnits = [oldTranslationUnits copy];
    _newTranslationUnits = [newTranslationUnits copy];
    _fileHandles = [[NSMutableDictionary alloc] init];
    _unsavedFileData = [[NSMutableDictionary alloc] init];

    for (PLClangUnsavedFile *unsavedFile in unsavedFiles) {
        _unsavedFileData[unsavedFile.path] = unsavedFile.data;
    }

    return self;
}

- (NSArray *)computeDifferences {
    NSMutableArray *differences = [NSMutableArray array];
    PLClangTranslationUnit *oldTU = [_oldTranslationUnits allObjects][0];
    PLClangTranslationUnit *newTU = [_newTranslationUnits allObjects][0];
    NSDictionary *oldAPI = [self APIForTranslationUnit:oldTU];
    NSDictionary *newAPI = [self APIForTranslationUnit:newTU];

    NSMutableSet *additions = [NSMutableSet setWithArray:[newAPI allKeys]];
    [additions minusSet:[NSSet setWithArray:[oldAPI allKeys]]];

    for (NSString *USR in oldAPI) {
        if (newAPI[USR] != nil) {
            OCDifference *difference = [self differenceBetweenOldCursor:oldAPI[USR] newCursor:newAPI[USR]];
            if (difference != nil) {
                [differences addObject:difference];
            }
        } else {
            PLClangCursor *cursor = oldAPI[USR];
            if (cursor.isImplicit)
                continue;

            OCDifference *difference = [OCDifference differenceWithType:OCDifferenceTypeRemoval name:[self displayNameForCursor:cursor]];
            [differences addObject:difference];
        }
    }

    for (NSString *USR in additions) {
        PLClangCursor *cursor = newAPI[USR];
        if (cursor.isImplicit)
            continue;

        OCDifference *difference = [OCDifference differenceWithType:OCDifferenceTypeAddition name:[self displayNameForCursor:cursor]];
        [differences addObject:difference];
    }

    return differences;
}

- (NSDictionary *)APIForTranslationUnit:(PLClangTranslationUnit *)translationUnit {
    NSMutableDictionary *api = [NSMutableDictionary dictionary];

    [translationUnit.cursor visitChildrenUsingBlock:^PLClangCursorVisitResult(PLClangCursor *cursor) {
        if (cursor.location.isInSystemHeader)
            return PLClangCursorVisitContinue;

        if (cursor.isDeclaration && [cursor.canonicalCursor isEqual:cursor]) {
            if (cursor.kind != PLClangCursorKindEnumDeclaration) {
                [api setObject:cursor forKey:cursor.USR];
            }
        } else if (cursor.kind == PLClangCursorKindMacroDefinition && [self isEmptyMacroDefinitionAtCursor:cursor] == NO) {
            [api setObject:cursor forKey:cursor.USR];
        }

        switch (cursor.kind) {
            case PLClangCursorKindObjCInterfaceDeclaration:
            case PLClangCursorKindObjCProtocolDeclaration:
            case PLClangCursorKindEnumDeclaration:
                return PLClangCursorVisitRecurse;
            default:
                break;
        }

        return PLClangCursorVisitContinue;
    }];

    return api;
}

/**
 * Returns a Boolean value indicating whether the specified cursor represents an empty macro definition
 *
 * An empty definition can be identified by an extent that includes only the macro's spelling.
 */
- (BOOL)isEmptyMacroDefinitionAtCursor:(PLClangCursor *)cursor {
    if (cursor.kind != PLClangCursorKindMacroDefinition)
        return NO;

    if (cursor.extent.startLocation.lineNumber != cursor.extent.endLocation.lineNumber)
        return NO;

    NSInteger extentLength = cursor.extent.endLocation.columnNumber - cursor.extent.startLocation.columnNumber;
    return extentLength == [cursor.spelling length];
}

- (OCDifference *)differenceBetweenOldCursor:(PLClangCursor *)oldCursor newCursor:(PLClangCursor *)newCursor {
    NSMutableArray *modifications = [NSMutableArray array];

    PLClangType *oldType = oldCursor.type;
    PLClangType *newType = newCursor.type;

    if (oldCursor.kind == PLClangCursorKindTypedefDeclaration) {
        oldType = oldCursor.underlyingType;
        newType = newCursor.underlyingType;
    }

    if (oldCursor.kind == PLClangCursorKindObjCInstanceMethodDeclaration || oldCursor.kind == PLClangCursorKindObjCClassMethodDeclaration) {
        if ([oldCursor.objCTypeEncoding isEqual:newCursor.objCTypeEncoding] == NO && oldCursor.isImplicit == NO && newCursor.isImplicit == NO) {
            OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                                    previousValue:[self stringForSourceRange:oldCursor.extent]
                                                                     currentValue:[self stringForSourceRange:newCursor.extent]];
            [modifications addObject:modification];
        }

        if (oldCursor.isObjCOptional != newCursor.isObjCOptional) {
            OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeOptional
                                                                    previousValue:oldCursor.isObjCOptional ? @"YES" : @"NO"
                                                                     currentValue:newCursor.isObjCOptional ? @"YES" : @"NO"];
            [modifications addObject:modification];
        }
    } else if (oldType != newType && [oldType.spelling isEqual:newType.spelling] == NO) {
        OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                                previousValue:[self stringForSourceRange:oldCursor.extent]
                                                                 currentValue:[self stringForSourceRange:newCursor.extent]];
        [modifications addObject:modification];
    } else if (oldCursor.kind == PLClangCursorKindObjCPropertyDeclaration && oldCursor.objCPropertyAttributes != newCursor.objCPropertyAttributes) {
        OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                                previousValue:[self stringForSourceRange:oldCursor.extent]
                                                                 currentValue:[self stringForSourceRange:newCursor.extent]];
        [modifications addObject:modification];
    }

    if (oldCursor.availability.isDeprecated != newCursor.availability.isDeprecated) {
        OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeprecation
                                                                previousValue:oldCursor.availability.isDeprecated ? @"YES" : @"NO"
                                                                 currentValue:newCursor.availability.isDeprecated ? @"YES" : @"NO"];
        [modifications addObject:modification];
    }

    if ([modifications count] > 0) {
        return [OCDifference modificationDifferenceWithName:[self displayNameForCursor:oldCursor] modifications:modifications];
    }

    return nil;
}

- (NSString *)stringForSourceRange:(PLClangSourceRange *)range {
    NSData *data;
    NSString *path = range.startLocation.path;

    data = _unsavedFileData[path];
    if (data != nil) {
        data = [data subdataWithRange:NSMakeRange(range.startLocation.fileOffset, (NSUInteger)(range.endLocation.fileOffset - range.startLocation.fileOffset))];
    } else {
        NSFileHandle *file = _fileHandles[path];
        if (!file) {
            file = [NSFileHandle fileHandleForReadingAtPath:path];
            if (!file) {
                return nil;
            }
            _fileHandles[path] = file;
        }

        [file seekToFileOffset:(unsigned long long)range.startLocation.fileOffset];
        data = [file readDataOfLength:(NSUInteger)(range.endLocation.fileOffset - range.startLocation.fileOffset)];
    }

    NSString *result = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];

    NSMutableCharacterSet *characterSet = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    [characterSet addCharactersInString:@";"];
    return [result stringByTrimmingCharactersInSet: characterSet];
}

- (NSString *)displayNameForCursor:(PLClangCursor *)cursor {
    if (cursor.kind == PLClangCursorKindObjCInstanceMethodDeclaration) {
        return [NSString stringWithFormat:@"-[%@ %@]", cursor.semanticParent.spelling, cursor.spelling];
    } else if (cursor.kind == PLClangCursorKindObjCClassMethodDeclaration) {
        return [NSString stringWithFormat:@"+[%@ %@]", cursor.semanticParent.spelling, cursor.spelling];
    } else if (cursor.kind == PLClangCursorKindObjCPropertyDeclaration) {
        return [NSString stringWithFormat:@"%@.%@", cursor.semanticParent.spelling, cursor.spelling];
    } else if (cursor.kind == PLClangCursorKindMacroDefinition) {
        return [NSString stringWithFormat:@"#def %@", cursor.spelling];
    }

    return cursor.displayName;
}

@end
