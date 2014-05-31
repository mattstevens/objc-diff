#import "OCDAPIComparator.h"
#import <ObjectDoc/ObjectDoc.h>

@implementation OCDAPIComparator {
    PLClangTranslationUnit *_oldTranslationUnit;
    PLClangTranslationUnit *_newTranslationUnit;
    NSString *_oldBaseDirectory;
    NSString *_newBaseDirectory;
    NSMutableDictionary *_fileHandles;
    NSMutableDictionary *_unsavedFileData;

    /**
     * Keys for property declarations that have been converted to or from explicit accessor declarations.
     *
     * This is used to suppress reporting of the addition or removal of the property declaration, as this change is
     * instead reported as a modification to the declaration of the accessor methods.
     */
    NSMutableSet *_convertedProperties;
}

- (instancetype)initWithOldTranslationUnit:(PLClangTranslationUnit *)oldTranslationUnit newTranslationUnit:(PLClangTranslationUnit *)newTranslationUnit {
    return [self initWithOldTranslationUnit:oldTranslationUnit newTranslationUnit:newTranslationUnit unsavedFiles:nil];
}

- (instancetype)initWithOldTranslationUnit:(PLClangTranslationUnit *)oldTranslationUnit newTranslationUnit:(PLClangTranslationUnit *)newTranslationUnit unsavedFiles:(NSArray *)unsavedFiles {
    if (!(self = [super init]))
        return nil;

    _oldTranslationUnit = oldTranslationUnit;
    _newTranslationUnit = newTranslationUnit;
    _oldBaseDirectory = [oldTranslationUnit.spelling stringByDeletingLastPathComponent];
    _newBaseDirectory = [newTranslationUnit.spelling stringByDeletingLastPathComponent];
    _fileHandles = [[NSMutableDictionary alloc] init];
    _unsavedFileData = [[NSMutableDictionary alloc] init];
    _convertedProperties = [[NSMutableSet alloc] init];

    for (PLClangUnsavedFile *unsavedFile in unsavedFiles) {
        _unsavedFileData[unsavedFile.path] = unsavedFile.data;
    }

    return self;
}

- (NSArray *)computeDifferences {
    NSMutableArray *differences = [NSMutableArray array];
    NSDictionary *oldAPI = [self APIForTranslationUnit:_oldTranslationUnit];
    NSDictionary *newAPI = [self APIForTranslationUnit:_newTranslationUnit];
    NSMutableArray *removals = [NSMutableArray array];

    NSMutableSet *additions = [NSMutableSet setWithArray:[newAPI allKeys]];
    [additions minusSet:[NSSet setWithArray:[oldAPI allKeys]]];

    for (NSString *USR in oldAPI) {
        if (newAPI[USR] != nil) {
            NSArray *cursorDifferences = [self differencesBetweenOldCursor:oldAPI[USR] newCursor:newAPI[USR]];
            if (cursorDifferences != nil) {
                [differences addObjectsFromArray:cursorDifferences];
            }
        } else {
            [removals addObject:USR];
        }
    }

    for (NSString *USR in removals) {
        PLClangCursor *cursor = oldAPI[USR];
        if (cursor.isImplicit || [_convertedProperties containsObject:USR])
            continue;

        NSString *relativePath = [self pathForFile:cursor.location.path relativeToDirectory:_oldBaseDirectory];
        OCDifference *difference = [OCDifference differenceWithType:OCDifferenceTypeRemoval name:[self displayNameForCursor:cursor] path:relativePath lineNumber:cursor.location.lineNumber];
        [differences addObject:difference];
    }

    for (NSString *USR in additions) {
        PLClangCursor *cursor = newAPI[USR];
        if (cursor.isImplicit || [_convertedProperties containsObject:USR])
            continue;

        NSString *relativePath = [self pathForFile:cursor.location.path relativeToDirectory:_newBaseDirectory];
        OCDifference *difference = [OCDifference differenceWithType:OCDifferenceTypeAddition name:[self displayNameForCursor:cursor] path:relativePath lineNumber:cursor.location.lineNumber];
        [differences addObject:difference];
    }

    [self sortDifferences:differences];

    return differences;
}

- (void)sortDifferences:(NSMutableArray *)differences {
    [differences sortUsingComparator:^NSComparisonResult(OCDifference *obj1, OCDifference *obj2) {
        NSComparisonResult result = [obj1.path localizedStandardCompare:obj2.path];
        if (result != NSOrderedSame)
            return result;

        if (obj1.type < obj2.type) {
            return NSOrderedAscending;
        } else if (obj1.type > obj2.type) {
            return NSOrderedDescending;
        }

        if (obj1.lineNumber < obj2.lineNumber) {
            return NSOrderedAscending;
        } else if (obj1.lineNumber > obj2.lineNumber) {
            return NSOrderedDescending;
        }

        return [obj1.name caseInsensitiveCompare:obj2.name];
    }];
}

- (NSDictionary *)APIForTranslationUnit:(PLClangTranslationUnit *)translationUnit {
    NSMutableDictionary *api = [NSMutableDictionary dictionary];

    [translationUnit.cursor visitChildrenUsingBlock:^PLClangCursorVisitResult(PLClangCursor *cursor) {
        if (cursor.location.isInSystemHeader || cursor.location.path == nil)
            return PLClangCursorVisitContinue;

        if ([self shouldIncludeEntityAtCursor:cursor] == NO) {
            if (cursor.kind == PLClangCursorKindEnumDeclaration) {
                // Enum declarations are excluded, but enum constants are included.
                return PLClangCursorVisitRecurse;
            } else {
                return PLClangCursorVisitContinue;
            }
        }

        [api setObject:cursor forKey:[self keyForCursor:cursor]];

        switch (cursor.kind) {
            case PLClangCursorKindObjCInterfaceDeclaration:
            case PLClangCursorKindObjCCategoryDeclaration:
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
 * Returns a key suitable for identifying the specified cursor across translation units.
 *
 * For declarations that are not externally visible Clang includes location information in the USR if the declaration
 * is not in a system header. This makes the USR an inappropriate key for comparison between two API versions, as
 * moving the declaration to a different file or line number would be detected as a removal and addition. As a result
 * a custom key is generated in place of the USR for these declarations.
 */
- (NSString *)keyForCursor:(PLClangCursor *)cursor {
    NSString *prefix = nil;

    switch (cursor.kind) {
        case PLClangCursorKindEnumConstantDeclaration:
            prefix = @"ocd_E_";
            break;
        case PLClangCursorKindTypedefDeclaration:
            prefix = @"ocd_T_";
            break;
        case PLClangCursorKindMacroDefinition:
            prefix = @"ocd_M_";
            break;
        case PLClangCursorKindFunctionDeclaration:
            if (cursor.linkage == PLClangLinkageInternal) {
                // Static inline function
                prefix = @"ocd_F_";
            }
            break;
        default:
            break;
    }

    return prefix ? [prefix stringByAppendingString:cursor.spelling] : cursor.USR;
}

/**
 * Returns a Boolean value indicating whether the specified cursor represents the canonical cursor for a declaration.
 *
 * This works around a Clang bug where a forward declaration of a class or protocol appearing before the actual
 * declaration is incorrectly considered the canonical declaration. Since the actual declaration for these types are
 * the only cursors that will have a cursor kind of Objective-C class or protocol, it is safe to special-case them to
 * always be considered canonical.
 */
- (BOOL)isCanonicalCursor:(PLClangCursor *)cursor {
    switch (cursor.kind) {
        case PLClangCursorKindObjCInterfaceDeclaration:
        case PLClangCursorKindObjCCategoryDeclaration:
        case PLClangCursorKindObjCProtocolDeclaration:
            return YES;
        default:
            return [cursor.canonicalCursor isEqual:cursor];
    }
}

/**
 * Returns a Boolean value indicating whether the entity at the specified cursor should be included in the API.
 */
- (BOOL)shouldIncludeEntityAtCursor:(PLClangCursor *)cursor {
    if ((cursor.isDeclaration && [self shouldIncludeDeclarationAtCursor:cursor]) ||
        (cursor.kind == PLClangCursorKindMacroDefinition && [self isEmptyMacroDefinitionAtCursor:cursor] == NO)) {
        return ([cursor.spelling length] > 0 && [cursor.spelling hasPrefix:@"_"] == NO);
    }

    return NO;
}

/**
 * Returns a Boolean value indicating whether the declaration at the specified cursor should be included in the API.
 */
- (BOOL)shouldIncludeDeclarationAtCursor:(PLClangCursor *)cursor {
    if ([self isCanonicalCursor:cursor] == NO) {
        return NO;
    }

    switch (cursor.kind) {
        // Exclude enum declarations, in Objective-C these are typically accessed through an appropriate typedef.
        case PLClangCursorKindEnumDeclaration:
            return NO;

        case PLClangCursorKindObjCInstanceVariableDeclaration:
            return NO;

        case PLClangCursorKindModuleImportDeclaration:
            return NO;

        default:
            break;
    }

    if (cursor.availability.availabilityKind == PLClangAvailabilityKindUnavailable ||
        cursor.availability.availabilityKind == PLClangAvailabilityKindInaccessible) {
        return NO;
    }

    return YES;
}

/**
 * Returns a Boolean value indicating whether the specified cursor represents an empty macro definition.
 *
 * An empty definition can be identified by an extent that includes only the macro's spelling.
 */
- (BOOL)isEmptyMacroDefinitionAtCursor:(PLClangCursor *)cursor {
    if (cursor.kind != PLClangCursorKindMacroDefinition)
        return NO;

    if (cursor.extent.startLocation.lineNumber != cursor.extent.endLocation.lineNumber)
        return NO;

    NSUInteger extentLength = cursor.extent.endLocation.columnNumber - cursor.extent.startLocation.columnNumber;
    return extentLength == [cursor.spelling length];
}

- (NSArray *)differencesBetweenOldCursor:(PLClangCursor *)oldCursor newCursor:(PLClangCursor *)newCursor {
    NSMutableArray *modifications = [NSMutableArray array];
    BOOL reportDifferenceForOldLocation = NO;

    // Ignore changes to implicit declarations like synthesized property accessors
    if (oldCursor.isImplicit && newCursor.isImplicit)
        return nil;

    NSString *oldRelativePath = [self pathForFile:oldCursor.location.path relativeToDirectory:_oldBaseDirectory];
    NSString *newRelativePath = [self pathForFile:newCursor.location.path relativeToDirectory:_newBaseDirectory];
    if (oldRelativePath != newRelativePath && [oldRelativePath isEqual:newRelativePath] == NO && [self shouldReportHeaderChangeForCursor:oldCursor]) {
        OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeHeader
                                                                previousValue:oldRelativePath
                                                                 currentValue:newRelativePath];
        [modifications addObject:modification];

        reportDifferenceForOldLocation = YES;
    }

    if (oldCursor.isImplicit != newCursor.isImplicit) {
        // Report conversions between properties and explicit accessor methods as modifications to the declaration
        // rather than additions or removals. This is less straightforward to identify but is a more accurate
        // difference - the methods have not been added or removed, only their declaration has changed.
        NSString *oldDeclaration;
        NSString *newDeclaration;
        PLClangCursor *propertyCursor;

        if (newCursor.isImplicit) {
            propertyCursor = [_newTranslationUnit cursorForSourceLocation:newCursor.location];
            NSAssert(propertyCursor != nil, @"Failed to locate property cursor for conversion from explicit accesor");

            oldDeclaration = [self declarationStringForCursor:oldCursor];
            newDeclaration = [self declarationStringForCursor:propertyCursor];
        } else {
            propertyCursor = [_oldTranslationUnit cursorForSourceLocation:oldCursor.location];
            NSAssert(propertyCursor != nil, @"Failed to locate property cursor for conversion to explicit accesor");

            oldDeclaration = [self declarationStringForCursor:propertyCursor];
            newDeclaration = [self declarationStringForCursor:newCursor];
        }

        [_convertedProperties addObject:[self keyForCursor:propertyCursor]];

        OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                                previousValue:oldDeclaration
                                                                 currentValue:newDeclaration];
        [modifications addObject:modification];
    } else if ([self declarationChangedBetweenOldCursor:oldCursor newCursor:newCursor]) {
        OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                                previousValue:[self declarationStringForCursor:oldCursor]
                                                                 currentValue:[self declarationStringForCursor:newCursor]];
        [modifications addObject:modification];
    }

    if (oldCursor.kind == PLClangCursorKindObjCInterfaceDeclaration) {
        PLClangCursor *oldSuperclass = [self superclassCursorForClassAtCursor:oldCursor];
        PLClangCursor *newSuperclass = [self superclassCursorForClassAtCursor:newCursor];
        if (oldSuperclass != newSuperclass && [oldSuperclass.USR isEqual:newSuperclass.USR] == NO) {
            OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeSuperclass
                                                                    previousValue:oldSuperclass.spelling
                                                                     currentValue:newSuperclass.spelling];
            [modifications addObject:modification];
        }
    }

    if (oldCursor.kind == PLClangCursorKindObjCInterfaceDeclaration || oldCursor.kind == PLClangCursorKindObjCCategoryDeclaration || oldCursor.kind == PLClangCursorKindObjCProtocolDeclaration) {
        NSArray *oldProtocols = [self protocolCursorsForCursor:oldCursor];
        NSArray *newProtocols = [self protocolCursorsForCursor:newCursor];
        BOOL protocolsChanged = NO;
        if ([oldProtocols count] != [newProtocols count]) {
            protocolsChanged = YES;
        } else {
            for (NSUInteger protocolIndex = 0; protocolIndex < [oldProtocols count]; protocolIndex++) {
                PLClangCursor *oldProtocol = oldProtocols[protocolIndex];
                PLClangCursor *newProtocol = newProtocols[protocolIndex];
                if ([oldProtocol.USR isEqual:newProtocol.USR] == NO) {
                    protocolsChanged = YES;
                    break;
                }
            }
        }

        if (protocolsChanged) {
            OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeProtocols
                                                                    previousValue:[self stringForProtocolCursors:oldProtocols]
                                                                     currentValue:[self stringForProtocolCursors:newProtocols]];
            [modifications addObject:modification];
        }
    }

    if (oldCursor.isObjCOptional != newCursor.isObjCOptional) {
        OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeOptional
                                                                previousValue:oldCursor.isObjCOptional ? @"Optional" : @"Required"
                                                                 currentValue:newCursor.isObjCOptional ? @"Optional" : @"Required"];
        [modifications addObject:modification];
    }

    if (oldCursor.availability.availabilityKind != newCursor.availability.availabilityKind) {
        OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeAvailability
                                                                previousValue:[self stringForAvailabilityKind:oldCursor.availability.availabilityKind]
                                                                 currentValue:[self stringForAvailabilityKind:newCursor.availability.availabilityKind]];
        [modifications addObject:modification];

        if (newCursor.availability.availabilityKind == PLClangAvailabilityKindDeprecated && [newCursor.availability.deprecationMessage length] > 0) {
            modification = [OCDModification modificationWithType:OCDModificationTypeDeprecationMessage
                                                   previousValue:nil
                                                    currentValue:newCursor.availability.deprecationMessage];
            [modifications addObject:modification];
        }
    }

    if ([modifications count] > 0) {
        NSMutableArray *differences = [NSMutableArray array];
        OCDifference *difference;

        if (reportDifferenceForOldLocation) {
            NSString *relativePath = [self pathForFile:oldCursor.location.path relativeToDirectory:_oldBaseDirectory];
            difference = [OCDifference modificationDifferenceWithName:[self displayNameForCursor:oldCursor]
                                                                 path:relativePath
                                                           lineNumber:oldCursor.location.lineNumber
                                                        modifications:modifications];
            [differences addObject:difference];
        }

        NSString *relativePath = [self pathForFile:newCursor.location.path relativeToDirectory:_newBaseDirectory];
        difference = [OCDifference modificationDifferenceWithName:[self displayNameForCursor:oldCursor]
                                                             path:relativePath
                                                       lineNumber:newCursor.location.lineNumber
                                                    modifications:modifications];
        [differences addObject:difference];

        return differences;
    }

    return nil;
}

- (PLClangCursor *)superclassCursorForClassAtCursor:(PLClangCursor *)classCursor {
    __block PLClangCursor *superclassCursor = nil;
    [classCursor visitChildrenUsingBlock:^PLClangCursorVisitResult(PLClangCursor *cursor) {
        if (cursor.kind == PLClangCursorKindObjCSuperclassReference) {
            superclassCursor = cursor.referencedCursor ?: cursor;
            return PLClangCursorVisitBreak;
        }

        return PLClangCursorVisitContinue;
    }];

    return superclassCursor;
}

- (PLClangCursor *)classCursorForCategoryAtCursor:(PLClangCursor *)categoryCursor {
    __block PLClangCursor *classCursor = nil;
    [categoryCursor visitChildrenUsingBlock:^PLClangCursorVisitResult(PLClangCursor *cursor) {
        if (cursor.kind == PLClangCursorKindObjCClassReference) {
            classCursor = cursor.referencedCursor ?: cursor;
            return PLClangCursorVisitBreak;
        }

        return PLClangCursorVisitContinue;
    }];

    return classCursor;
}

- (NSArray *)protocolCursorsForCursor:(PLClangCursor *)classCursor {
    NSMutableArray *protocols = [NSMutableArray array];
    [classCursor visitChildrenUsingBlock:^PLClangCursorVisitResult(PLClangCursor *cursor) {
        if (cursor.kind == PLClangCursorKindObjCProtocolReference) {
            [protocols addObject:cursor.referencedCursor ?: cursor];
        }

        return PLClangCursorVisitContinue;
    }];

    return protocols;
}

- (BOOL)declarationChangedBetweenOldCursor:(PLClangCursor *)oldCursor newCursor:(PLClangCursor *)newCursor {
    switch (oldCursor.kind) {
        case PLClangCursorKindObjCInstanceMethodDeclaration:
        case PLClangCursorKindObjCClassMethodDeclaration:
        {
            if (!OCDEqualTypes(oldCursor.resultType, newCursor.resultType)) {
                return YES;
            }

            if (oldCursor.isVariadic != newCursor.isVariadic) {
                return YES;
            }

            if ([oldCursor.arguments count] != [newCursor.arguments count]) {
                return YES;
            }

            for (NSUInteger argIndex = 0; argIndex < [oldCursor.arguments count]; argIndex++) {
                PLClangCursor *oldArgument = oldCursor.arguments[argIndex];
                PLClangCursor *newArgument = newCursor.arguments[argIndex];
                if (!OCDEqualTypes(oldArgument.type, newArgument.type)) {
                    return YES;
                }
            }

            break;
        }

        case PLClangCursorKindObjCPropertyDeclaration:
        {
            if (oldCursor.objCPropertyAttributes != newCursor.objCPropertyAttributes) {
                return YES;
            }

            if (!OCDEqualTypes(oldCursor.type, newCursor.type)) {
                return YES;
            }

            if (oldCursor.objCPropertyAttributes & PLClangObjCPropertyAttributeGetter && [oldCursor.objCPropertyGetter.USR isEqual:newCursor.objCPropertyGetter.USR] == NO) {
                return YES;
            }

            if (oldCursor.objCPropertyAttributes & PLClangObjCPropertyAttributeSetter && [oldCursor.objCPropertySetter.USR isEqual:newCursor.objCPropertySetter.USR] == NO) {
                return YES;
            }

            break;
        }

        case PLClangCursorKindFunctionDeclaration:
        case PLClangCursorKindVariableDeclaration:
        {
            return !OCDEqualTypes(oldCursor.type, newCursor.type);
        }

        case PLClangCursorKindTypedefDeclaration:
        {
            // Report changes to block and function pointer typedefs

            if (oldCursor.underlyingType.kind == PLClangTypeKindBlockPointer && oldCursor.underlyingType.kind == PLClangTypeKindBlockPointer) {
                return !OCDEqualTypes(oldCursor.underlyingType, newCursor.underlyingType);
            }

            if (oldCursor.underlyingType.kind == PLClangTypeKindPointer && oldCursor.underlyingType.pointeeType.canonicalType.kind == PLClangTypeKindFunctionPrototype &&
                newCursor.underlyingType.kind == PLClangTypeKindPointer && newCursor.underlyingType.pointeeType.canonicalType.kind == PLClangTypeKindFunctionPrototype) {
                return !OCDEqualTypes(oldCursor.underlyingType, newCursor.underlyingType);
            }

            break;
        }

        default:
        {
            break;
        }
    }

    return NO;
}


/**
 * Returns a Boolean value indicating whether a header change should be reported for the specified cursor.
 *
 * If the cursor's parent is a container type such as an Objective-C class or protocol it is unnecessary to
 * report a separate relocation difference for each of its children. Relocation of the children is implied by
 * the relocation of the parent.
 */
- (BOOL)shouldReportHeaderChangeForCursor:(PLClangCursor *)cursor {
    switch (cursor.semanticParent.kind) {
        case PLClangCursorKindObjCInterfaceDeclaration:
        case PLClangCursorKindObjCCategoryDeclaration:
        case PLClangCursorKindObjCProtocolDeclaration:
        case PLClangCursorKindStructDeclaration:
            return NO;
        default:
            return YES;
    }
}

/**
 * Returns a declaration string for the specified cursor.
 *
 * The source extent for function and method declarations includes all of their annotating attributes as well.
 * For our purposes we want an undecorated declaration that just communicates the changed type information. To
 * achieve this a declaration is constructed from the cursor's type information. This avoids parsing an
 * extracted full declaration to exclude the attributes.
 *
 * TODO: See if Clang can be enhanced to provide the range of the declaration we're interested in. From the
 * tool's perspective this would be simpler, less fragile, and include whitespace as written.
 */
- (NSString *)declarationStringForCursor:(PLClangCursor *)cursor {
    NSMutableString *decl = [NSMutableString string];

    switch (cursor.kind) {
        case PLClangCursorKindObjCInstanceMethodDeclaration:
        case PLClangCursorKindObjCClassMethodDeclaration:
        {
            [decl appendString:(cursor.kind == PLClangCursorKindObjCClassMethodDeclaration ? @"+" : @"-")];
            [decl appendString:@" ("];
            [decl appendString:cursor.resultType.spelling];
            [decl appendString:@")"];

            // TODO: Is there a better way to get the keywords for the method name?
            if (cursor.arguments.count > 0) {
                NSArray *keywords = [cursor.spelling componentsSeparatedByString:@":"];
                NSAssert(keywords.count == (cursor.arguments.count + 1), @"Method name parts do not match argument count");

                [cursor.arguments enumerateObjectsUsingBlock:^(PLClangCursor *argument, NSUInteger index, BOOL *stopArguments) {
                    if (index > 0) {
                        [decl appendString:@" "];
                    }
                    [decl appendFormat:@"%@:(%@)%@", keywords[index], argument.type.spelling, argument.spelling];
                }];

                if (cursor.isVariadic) {
                    [decl appendString:@", ..."];
                }

            } else {
                [decl appendString:cursor.spelling];
            }

            break;
        }

        case PLClangCursorKindObjCPropertyDeclaration:
        {
            [decl appendString:@"@property "];

            if (cursor.objCPropertyAttributes != PLClangObjCPropertyAttributeNone) {
                [decl appendString:@"("];
                [decl appendString:[self propertyAttributeStringForCursor:cursor]];
                [decl appendString:@") "];
            }

            [decl appendString:cursor.type.spelling];

            if (![cursor.type.spelling hasSuffix:@" *"]) {
                [decl appendString:@" "];
            }

            [decl appendString:cursor.spelling];

            break;
        }

        case PLClangCursorKindFunctionDeclaration:
        {
            [decl appendString:cursor.resultType.spelling];

            if (![cursor.resultType.spelling hasSuffix:@" *"]) {
                [decl appendString:@" "];
            }

            [decl appendString:cursor.spelling];
            [decl appendString:@"("];

            if (cursor.arguments.count > 0) {
                [cursor.arguments enumerateObjectsUsingBlock:^(PLClangCursor *argument, NSUInteger index, BOOL *stopArguments) {
                    if (index > 0) {
                        [decl appendString:@", "];
                    }

                    NSMutableString *typeSpelling = [NSMutableString stringWithString:argument.type.spelling];
                    if (![typeSpelling hasSuffix:@" *"] && [argument.spelling length] > 0) {
                        [typeSpelling appendString:@" "];
                    }

                    [decl appendFormat:@"%@%@", typeSpelling, argument.spelling];
                }];

                if (cursor.isVariadic) {
                    [decl appendString:@", ..."];
                }
            } else {
                [decl appendString:@"void"];
            }

            [decl appendString:@")"];

            break;
        }

        default:
        {
            return [self stringForSourceRange:cursor.extent];
        }
    }

    return decl;
}

- (NSString *)propertyAttributeStringForCursor:(PLClangCursor *)cursor {
    NSMutableArray *attributeStrings = [NSMutableArray array];
    PLClangObjCPropertyAttributes attributes = cursor.objCPropertyAttributes;

    if (attributes & PLClangObjCPropertyAttributeAtomic) {
        [attributeStrings addObject:@"atomic"];
    }

    if (attributes & PLClangObjCPropertyAttributeNonAtomic) {
        [attributeStrings addObject:@"nonatomic"];
    }

    if (attributes & PLClangObjCPropertyAttributeReadOnly) {
        [attributeStrings addObject:@"readonly"];
    }

    if (attributes & PLClangObjCPropertyAttributeReadWrite) {
        [attributeStrings addObject:@"readwrite"];
    }

    if (attributes & PLClangObjCPropertyAttributeAssign) {
        [attributeStrings addObject:@"assign"];
    }

    if (attributes & PLClangObjCPropertyAttributeCopy) {
        [attributeStrings addObject:@"copy"];
    }

    if (attributes & PLClangObjCPropertyAttributeRetain) {
        [attributeStrings addObject:@"retain"];
    }

    if (attributes & PLClangObjCPropertyAttributeStrong) {
        [attributeStrings addObject:@"strong"];
    }

    if (attributes & PLClangObjCPropertyAttributeUnsafeUnretained) {
        [attributeStrings addObject:@"unsafe_unretained"];
    }

    if (attributes & PLClangObjCPropertyAttributeWeak) {
        [attributeStrings addObject:@"weak"];
    }

    if (attributes & PLClangObjCPropertyAttributeGetter) {
        [attributeStrings addObject:[NSString stringWithFormat:@"getter=%@", cursor.objCPropertyGetter.spelling]];
    }

    if (attributes & PLClangObjCPropertyAttributeSetter) {
        [attributeStrings addObject:[NSString stringWithFormat:@"setter=%@", cursor.objCPropertySetter.spelling]];
    }

    return [attributeStrings componentsJoinedByString:@", "];
}

- (NSString *)stringForSourceRange:(PLClangSourceRange *)range {
    NSData *data;
    NSString *path = range.startLocation.path;

    data = _unsavedFileData[path];
    if (data != nil) {
        data = [data subdataWithRange:NSMakeRange((NSUInteger)range.startLocation.fileOffset, ((NSUInteger)range.endLocation.fileOffset - (NSUInteger)range.startLocation.fileOffset))];
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

    NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    NSMutableCharacterSet *characterSet = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    [characterSet addCharactersInString:@";"];
    return [result stringByTrimmingCharactersInSet:characterSet];
}

- (NSString *)displayNameForObjCParentCursor:(PLClangCursor *)cursor {
    if (cursor.kind == PLClangCursorKindObjCCategoryDeclaration) {
        return [self classCursorForCategoryAtCursor:cursor].spelling;
    }

    return cursor.spelling;
}

- (NSString *)displayNameForCursor:(PLClangCursor *)cursor {
    switch (cursor.kind) {
        case PLClangCursorKindObjCCategoryDeclaration:
            return [NSString stringWithFormat:@"%@ (%@)", [self displayNameForObjCParentCursor:cursor], cursor.spelling];
        case PLClangCursorKindObjCInstanceMethodDeclaration:
            return [NSString stringWithFormat:@"-[%@ %@]", [self displayNameForObjCParentCursor:cursor.semanticParent], cursor.spelling];
        case PLClangCursorKindObjCClassMethodDeclaration:
            return [NSString stringWithFormat:@"+[%@ %@]", [self displayNameForObjCParentCursor:cursor.semanticParent], cursor.spelling];
        case PLClangCursorKindObjCPropertyDeclaration:
            return [NSString stringWithFormat:@"%@.%@", [self displayNameForObjCParentCursor:cursor.semanticParent], cursor.spelling];
        case PLClangCursorKindFunctionDeclaration:
            return [NSString stringWithFormat:@"%@()", cursor.spelling];
        case PLClangCursorKindMacroDefinition:
            return [NSString stringWithFormat:@"#def %@", cursor.spelling];
        default:
            return cursor.displayName;
    }
}

- (NSString *)stringForProtocolCursors:(NSArray *)cursors {
    NSMutableArray *protocolNames = [NSMutableArray array];
    for (PLClangCursor *cursor in cursors) {
        [protocolNames addObject:cursor.spelling];
    }

    return [protocolNames count] > 0 ? [protocolNames componentsJoinedByString:@", "] : nil;
}

- (NSString *)stringForAvailabilityKind:(PLClangAvailabilityKind)kind {
    switch (kind) {
        case PLClangAvailabilityKindAvailable:
            return @"Available";
        case PLClangAvailabilityKindDeprecated:
            return @"Deprecated";
        case PLClangAvailabilityKindUnavailable:
            return @"Unavailable";
        case PLClangAvailabilityKindInaccessible:
            return @"Inaccessible";
    }

    abort();
}

/**
 * Returns a relative path to a file from the specified directory.
 */
- (NSString *)pathForFile:(NSString *)path relativeToDirectory:(NSString *)directory {
    if (path == nil) {
        return nil;
    }

    if (directory == nil) {
        return path;
    }

    NSUInteger index = 0;
    NSMutableArray *baseComponents = [[directory pathComponents] mutableCopy];
	NSMutableArray *pathComponents = [[path pathComponents] mutableCopy];
	if ([[baseComponents lastObject] isEqualToString:@"/"]) {
        [baseComponents removeLastObject];
    }

	while (index < [baseComponents count] && index < [pathComponents count] && [baseComponents[index] isEqualToString:pathComponents[index]]) {
		index++;
	}

	[baseComponents removeObjectsInRange:NSMakeRange(0, index)];
	[pathComponents removeObjectsInRange:NSMakeRange(0, index)];

	for (index = 0; index < [baseComponents count]; index++) {
		[pathComponents insertObject:@".." atIndex:0];
	}

	return [NSString pathWithComponents:pathComponents];
}

/**
 * Returns a Boolean value indicating whether two types are equal.
 *
 * Clang types cannot be compared across translation units, so -[PLClangType isEqual:] is unsuitable for API comparison
 * purposes. To work around this compare the type's spelling, which includes its qualifiers.
 */
static BOOL OCDEqualTypes(PLClangType *type1, PLClangType* type2) {
    return [type1.spelling isEqual:type2.spelling];
}

@end
