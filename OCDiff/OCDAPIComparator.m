#import "OCDAPIComparator.h"
#import "NSString+OCDPathUtilities.h"
#import "PLClangCursor+OCDExtensions.h"
#import <ObjectDoc/ObjectDoc.h>

@implementation OCDAPIComparator {
    OCDAPISource *_oldAPISource;
    OCDAPISource *_newAPISource;
    NSString *_oldBaseDirectory;
    NSString *_newBaseDirectory;

    /**
     * Keys for property declarations that have been converted to or from explicit accessor declarations.
     *
     * This is used to suppress reporting of the addition or removal of the property declaration, as this change is
     * instead reported as a modification to the declaration of the accessor methods.
     */
    NSMutableSet *_convertedProperties;
}

- (instancetype)initWithOldAPISource:(OCDAPISource *)oldAPISource newAPISource:(OCDAPISource *)newAPISource {
    if (!(self = [super init]))
        return nil;

    _oldAPISource = oldAPISource;
    _newAPISource = newAPISource;
    _oldBaseDirectory = [[oldAPISource.translationUnit.spelling stringByDeletingLastPathComponent] ocd_absolutePath];
    _newBaseDirectory = [[newAPISource.translationUnit.spelling stringByDeletingLastPathComponent] ocd_absolutePath];
    _convertedProperties = [[NSMutableSet alloc] init];

    return self;
}

+ (NSArray<OCDifference *> *)differencesBetweenOldAPISource:(OCDAPISource *)oldAPISource newAPISource:(OCDAPISource *)newAPISource {
    OCDAPIComparator *comparator = [[self alloc] initWithOldAPISource:oldAPISource newAPISource:newAPISource];
    return [comparator differences];
}

+ (NSArray<OCDifference *> *)differencesBetweenOldTranslationUnit:(PLClangTranslationUnit *)oldTranslationUnit newTranslationUnit:(PLClangTranslationUnit *)newTranslationUnit {
    return [self differencesBetweenOldAPISource:[OCDAPISource APISourceWithTranslationUnit:oldTranslationUnit]
                                   newAPISource:[OCDAPISource APISourceWithTranslationUnit:newTranslationUnit]];
}

- (NSArray<OCDifference *> *)differences {
    NSMutableArray *differences = [NSMutableArray array];
    NSDictionary *oldAPI = [self APIForSource:_oldAPISource];
    NSDictionary *newAPI = [self APIForSource:_newAPISource];
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

        NSString *relativePath = [cursor.location.path ocd_stringWithPathRelativeToDirectory:_oldBaseDirectory];
        OCDifference *difference = [OCDifference differenceWithType:OCDifferenceTypeRemoval name:[self displayNameForCursor:cursor] path:relativePath lineNumber:cursor.location.lineNumber USR:cursor.USR];
        [differences addObject:difference];
    }

    for (NSString *USR in additions) {
        PLClangCursor *cursor = newAPI[USR];
        if (cursor.isImplicit || [_convertedProperties containsObject:USR])
            continue;

        NSString *relativePath = [cursor.location.path ocd_stringWithPathRelativeToDirectory:_newBaseDirectory];
        OCDifference *difference = [OCDifference differenceWithType:OCDifferenceTypeAddition name:[self displayNameForCursor:cursor] path:relativePath lineNumber:cursor.location.lineNumber USR:cursor.USR];
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

- (NSDictionary *)APIForSource:(OCDAPISource *)source {
    NSMutableDictionary *api = [NSMutableDictionary dictionary];

    [source.translationUnit.cursor visitChildrenUsingBlock:^PLClangCursorVisitResult(PLClangCursor *cursor) {
        if (source.includeSystemHeaders == NO && cursor.location.isInSystemHeader)
            return PLClangCursorVisitContinue;

        if (cursor.location.path == nil)
            return PLClangCursorVisitContinue;

        if (source.containingPath.length > 0 && [cursor.location.path hasPrefix:source.containingPath] == NO)
            return PLClangCursorVisitContinue;

        if ([self shouldIncludeEntityAtCursor:cursor] == NO) {
            if (cursor.kind == PLClangCursorKindEnumDeclaration) {
                // Enum declarations are excluded, but enum constants are included.
                return PLClangCursorVisitRecurse;
            } else {
                return PLClangCursorVisitContinue;
            }
        }

        // If a category or class extension is extending a class within this
        // module (always the case for a class extension), exclude the category
        // declaration itself but include its childen and register the category
        // against its class. Modifications the category makes to the class
        // (e.g. extending protocol conformance) will then be reported as
        // modifications of the class.
        if (cursor.kind == PLClangCursorKindObjCCategoryDeclaration) {
            PLClangCursor *classCursor = [self classCursorForCategoryAtCursor:cursor];
            classCursor = classCursor ? api[[self keyForCursor:classCursor]] : nil;
            if (classCursor != nil) {
                [classCursor ocd_addCategory:cursor];
                return PLClangCursorVisitRecurse;
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
            prefix = @"ocd_F_";
            break;

        case PLClangCursorKindVariableDeclaration:
            prefix = @"ocd_V_";
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
        {
            BOOL isCanonical = [cursor.canonicalCursor isEqual:cursor];
            if (isCanonical == NO && cursor.kind == PLClangCursorKindFunctionDeclaration) {
                // TODO: Clang has an issue with declarations for functions that exist in its builtin function database
                // (e.g., NSLog, objc_msgSend). The canonical cursor for these functions has an identical source
                // location as the declaration in the file we're parsing, but an extent that covers only the function's
                // name, so libclang does not consider them equal. See if this can be fixed in Clang so we don't need a
                // hack here to include them.
                isCanonical = [cursor.location isEqual:cursor.canonicalCursor.location];
            }

            return isCanonical;
        }
    }
}

/**
 * Returns a Boolean value indicating whether the entity at the specified cursor should be included in the API.
 */
- (BOOL)shouldIncludeEntityAtCursor:(PLClangCursor *)cursor {
    if ((cursor.isDeclaration && [self shouldIncludeDeclarationAtCursor:cursor]) ||
        (cursor.kind == PLClangCursorKindMacroDefinition && [self shouldIncludeMacroDefinitionAtCursor:cursor])) {
        // Exclude private APIs indicated by name
        if ([cursor.spelling hasPrefix:@"_"]) {
            return NO;
        }

        // Class extensions have an empty spelling but should be included
        if (cursor.kind == PLClangCursorKindObjCCategoryDeclaration) {
            return YES;
        }

        return ([cursor.spelling length] > 0);
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
        // Exclude declarations that are typically accessed through an appropriate typedef.
        case PLClangCursorKindStructDeclaration:
        case PLClangCursorKindUnionDeclaration:
        case PLClangCursorKindEnumDeclaration:
            return NO;

        case PLClangCursorKindObjCInstanceVariableDeclaration:
            return NO;

        case PLClangCursorKindTemplateTypeParameter:
            return NO;

        case PLClangCursorKindModuleImportDeclaration:
            return NO;

        default:
            break;
    }

    if (cursor.availability.kind == PLClangAvailabilityKindUnavailable ||
        cursor.availability.kind == PLClangAvailabilityKindInaccessible) {
        return NO;
    }

    return YES;
}

/**
 * Returns a Boolean value indicating whether the macro definition at the specified cursor should be included in the API.
 */
- (BOOL)shouldIncludeMacroDefinitionAtCursor:(PLClangCursor *)cursor {
    if ([self isEmptyMacroDefinitionAtCursor:cursor]) {
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
    NSString *newUSR = newCursor.USR;

    // Ignore changes to implicit declarations like synthesized property accessors
    if (oldCursor.isImplicit && newCursor.isImplicit)
        return nil;

    if (oldCursor.isImplicit != newCursor.isImplicit) {
        // Report conversions between properties and explicit accessor methods as modifications to the declaration
        // rather than additions or removals. This is less straightforward to identify but is a more accurate
        // difference - the methods have not been added or removed, only their declaration has changed.
        NSString *oldDeclaration;
        NSString *newDeclaration;
        PLClangCursor *propertyCursor;

        if (newCursor.isImplicit) {
            propertyCursor = [_newAPISource.translationUnit cursorForSourceLocation:newCursor.location];
            NSAssert(propertyCursor != nil, @"Failed to locate property cursor for conversion from explicit accessor");

            oldDeclaration = [self declarationStringForCursor:oldCursor];
            newDeclaration = [self declarationStringForCursor:propertyCursor];
            newUSR = propertyCursor.USR;
        } else {
            propertyCursor = [_oldAPISource.translationUnit cursorForSourceLocation:oldCursor.location];
            NSAssert(propertyCursor != nil, @"Failed to locate property cursor for conversion to explicit accessor");

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
        NSOrderedSet *oldProtocols = [self protocolCursorsForCursor:oldCursor];
        NSOrderedSet *newProtocols = [self protocolCursorsForCursor:newCursor];
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

    PLClangAvailabilityKind oldAvailabilityKind = [self availabilityKindForCursor:oldCursor];
    PLClangAvailabilityKind newAvailabilityKind = [self availabilityKindForCursor:newCursor];
    if (oldAvailabilityKind != newAvailabilityKind) {
        OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeAvailability
                                                                previousValue:[self stringForAvailabilityKind:oldAvailabilityKind]
                                                                 currentValue:[self stringForAvailabilityKind:newAvailabilityKind]];
        [modifications addObject:modification];

        PLClangPlatformAvailability *newPlatformAvailability = [self platformAvailabilityForCursor:newCursor
                                                                                targetPlatformName:_newAPISource.translationUnit.targetPlatformName];

        NSString *deprecationMessage = newCursor.availability.unconditionalDeprecationMessage;
        if ([deprecationMessage length] == 0 && newPlatformAvailability != nil) {
            deprecationMessage = newPlatformAvailability.message;
        }

        NSString *replacement = newCursor.availability.unconditionalDeprecationReplacement;
        if ([replacement length] == 0 && newPlatformAvailability != nil) {
            replacement = newPlatformAvailability.replacement;
        }

        if (newAvailabilityKind == PLClangAvailabilityKindDeprecated && [deprecationMessage length] > 0) {
            modification = [OCDModification modificationWithType:OCDModificationTypeDeprecationMessage
                                                   previousValue:nil
                                                    currentValue:deprecationMessage];
            [modifications addObject:modification];
        } else if (newAvailabilityKind == PLClangAvailabilityKindDeprecated && [replacement length] > 0) {
            modification = [OCDModification modificationWithType:OCDModificationTypeReplacement
                                                   previousValue:nil
                                                    currentValue:replacement];
            [modifications addObject:modification];
        }
    }

    if ([modifications count] > 0) {
        NSMutableArray *differences = [NSMutableArray array];
        OCDifference *difference;

        NSString *relativePath = [newCursor.location.path ocd_stringWithPathRelativeToDirectory:_newBaseDirectory];
        difference = [OCDifference modificationDifferenceWithName:[self displayNameForCursor:oldCursor]
                                                             path:relativePath
                                                       lineNumber:newCursor.location.lineNumber
                                                              USR:newUSR
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

- (NSOrderedSet *)protocolCursorsForCursor:(PLClangCursor *)classCursor {
    NSMutableOrderedSet *protocols = [NSMutableOrderedSet orderedSet];
    [classCursor visitChildrenUsingBlock:^PLClangCursorVisitResult(PLClangCursor *cursor) {
        if (cursor.kind == PLClangCursorKindObjCProtocolReference) {
            [protocols addObject:cursor.referencedCursor ?: cursor];
        }

        return PLClangCursorVisitContinue;
    }];

    for (PLClangCursor *categoryCursor in classCursor.ocd_categories) {
        [protocols addObjectsFromArray:[self protocolCursorsForCursor:categoryCursor].array];
    }

    [protocols sortUsingComparator:^NSComparisonResult(PLClangCursor *obj1, PLClangCursor *obj2) {
        return [obj1.spelling localizedStandardCompare:obj2.spelling];
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
 * Returns a declaration string for the specified cursor suitable for display.
 *
 * The source extent for function and method declarations includes all of their annotating attributes as well.
 * For our purposes we want an undecorated declaration that just communicates the changed type information. To
 * achieve this a declaration is constructed from the cursor's type information. This avoids parsing an
 * extracted full declaration to exclude the attributes. This also results in a single-line declaration
 * stripped of inline comments.
 *
 * TODO: Clang's printers have the ability to generate this type of string using the PolishForDeclaration
 * option. See if this capability can be exposed, as using the Clang implementation would be simpler and less
 * fragile.
 */
- (NSString *)declarationStringForCursor:(PLClangCursor *)cursor {
    NSMutableString *decl = [NSMutableString string];

    switch (cursor.kind) {
        case PLClangCursorKindObjCInstanceMethodDeclaration:
        case PLClangCursorKindObjCClassMethodDeclaration:
        {
            [decl appendString:(cursor.kind == PLClangCursorKindObjCClassMethodDeclaration ? @"+" : @"-")];
            [decl appendString:@" ("];
            [decl appendString:[self spellingForTypeInObjectiveCMethod:cursor.resultType]];
            [decl appendString:@")"];

            // TODO: Is there a better way to get the keywords for the method name?
            if (cursor.arguments.count > 0) {
                NSArray *keywords = [cursor.spelling componentsSeparatedByString:@":"];
                NSAssert(keywords.count == (cursor.arguments.count + 1), @"Method name parts do not match argument count");

                [cursor.arguments enumerateObjectsUsingBlock:^(PLClangCursor *argument, NSUInteger index, BOOL *stopArguments) {
                    if (index > 0) {
                        [decl appendString:@" "];
                    }
                    NSString *typeSpelling = [self spellingForTypeInObjectiveCMethod:argument.type];
                    [decl appendFormat:@"%@:(%@)%@", keywords[index], typeSpelling, argument.spelling];
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

            if (cursor.objCPropertyAttributes != PLClangObjCPropertyAttributeNone || cursor.type.nullability != PLClangNullabilityNone) {
                [decl appendString:@"("];
                [decl appendString:[self propertyAttributeStringForCursor:cursor]];
                [decl appendString:@") "];
            }

            PLClangType *propertyType = [cursor.type typeByRemovingOuterNullability];
            [decl appendString:propertyType.spelling];

            if (![propertyType.spelling hasSuffix:@"*"]) {
                [decl appendString:@" "];
            }

            [decl appendString:cursor.spelling];

            break;
        }

        case PLClangCursorKindFunctionDeclaration:
        {
            [decl appendString:cursor.resultType.spelling];

            if (![cursor.resultType.spelling hasSuffix:@"*"]) {
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
                    if (![typeSpelling hasSuffix:@"*"] && [argument.spelling length] > 0) {
                        [typeSpelling appendString:@" "];
                    }

                    [decl appendFormat:@"%@%@", typeSpelling, argument.spelling];
                }];

                if (cursor.isVariadic) {
                    [decl appendString:@", ..."];
                }
            } else {
                // TODO: Need a way to determine if the function has a prototype
                if ([cursor.type.spelling rangeOfString:@"(void)"].location != NSNotFound) {
                    [decl appendString:@"void"];
                }
            }

            [decl appendString:@")"];

            break;
        }

        case PLClangCursorKindVariableDeclaration:
        {
            NSMutableString *typeSpelling = [NSMutableString stringWithString:cursor.type.spelling];
            if (![typeSpelling hasSuffix:@"*"]) {
                [typeSpelling appendString:@" "];
            }

            [decl appendFormat:@"%@%@", typeSpelling, cursor.spelling];

            break;
        }

        case PLClangCursorKindTypedefDeclaration:
        {
            [decl appendString:@"typedef "];

            PLClangType *underlyingType = cursor.underlyingType;

            if ((underlyingType.kind == PLClangTypeKindPointer && underlyingType.pointeeType.canonicalType.kind == PLClangTypeKindFunctionPrototype) ||
                underlyingType.kind == PLClangTypeKindBlockPointer) {
                BOOL isBlockPointer = (underlyingType.kind == PLClangTypeKindBlockPointer);
                PLClangType *functionType = underlyingType.pointeeType;
                [decl appendString:functionType.resultType.spelling];

                if (![functionType.spelling hasSuffix:@"*"]) {
                    [decl appendString:@" "];
                }

                [decl appendString:@"("];
                [decl appendString:(isBlockPointer ? @"^" : @"*")];
                [decl appendString:cursor.spelling];
                [decl appendString:@")("];

                NSArray *parameterTypes = functionType.argumentTypes;
                if ([parameterTypes count] > 0) {
                    NSMutableArray *parameterNames = [NSMutableArray array];
                    [cursor visitChildrenUsingBlock:^PLClangCursorVisitResult(PLClangCursor *childCursor) {
                        if (childCursor.kind == PLClangCursorKindParameterDeclaration) {
                            [parameterNames addObject:childCursor.spelling];
                        }
                        return PLClangCursorVisitContinue;
                    }];
                    NSAssert(parameterTypes.count == parameterNames.count, @"Parameter name count does not match parameter count");

                    [parameterTypes enumerateObjectsUsingBlock:^(PLClangType *parameterType, NSUInteger index, BOOL *stopParameters) {
                        if (index > 0) {
                            [decl appendString:@", "];
                        }

                        NSString *parameterName = [parameterNames objectAtIndex:index];
                        NSMutableString *typeSpelling = [NSMutableString stringWithString:parameterType.spelling];
                        if (![typeSpelling hasSuffix:@"*"] && [parameterName length] > 0) {
                            [typeSpelling appendString:@" "];
                        }

                        [decl appendFormat:@"%@%@", typeSpelling, parameterName];
                    }];

                    if (functionType.isVariadic) {
                        [decl appendString:@", ..."];
                    }

                } else {
                    // TODO: Need a way to determine if the function has a prototype
                    if ([cursor.type.spelling rangeOfString:@"(void)"].location != NSNotFound) {
                        [decl appendString:@"void"];
                    }
                }

                [decl appendString:@")"];
            } else {
                NSMutableString *typeSpelling = [NSMutableString stringWithString:cursor.type.spelling];
                if (![typeSpelling hasSuffix:@"*"]) {
                    [typeSpelling appendString:@" "];
                }

                [decl appendFormat:@"%@%@", typeSpelling, cursor.spelling];
            }

            break;
        }

        default:
        {
            // TODO: Report up as error rather than exiting here
            fprintf(stderr, "No printer available for cursor kind %tu\n", cursor.kind);
            exit(1);
        }
    }

    return decl;
}

- (NSString *)propertyAttributeStringForCursor:(PLClangCursor *)cursor {
    NSMutableArray *attributeStrings = [NSMutableArray array];
    PLClangObjCPropertyAttributes attributes = cursor.objCPropertyAttributes;

    if (attributes & PLClangObjCPropertyAttributeClass) {
        [attributeStrings addObject:@"class"];
    }

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

    // Always represent the nullability of a property's type as property attributes, even if the nullability is assumed
    // via the "clang assume_nonnull begin" pragma.

    switch (cursor.type.nullability) {
        case PLClangNullabilityNone:
            break;

        case PLClangNullabilityNonnull:
            [attributeStrings addObject:@"nonnull"];
            break;

        case PLClangNullabilityNullable:
            [attributeStrings addObject:@"nullable"];
            break;

        case PLClangNullabilityExplicitlyUnspecified:
            if (attributes & PLClangObjCPropertyAttributeNullResettable) {
                [attributeStrings addObject:@"null_resettable"];
            } else {
                [attributeStrings addObject:@"null_unspecified"];
            }
            break;
    }

    if (attributes & PLClangObjCPropertyAttributeGetter) {
        [attributeStrings addObject:[NSString stringWithFormat:@"getter=%@", cursor.objCPropertyGetter.spelling]];
    }

    if (attributes & PLClangObjCPropertyAttributeSetter) {
        [attributeStrings addObject:[NSString stringWithFormat:@"setter=%@", cursor.objCPropertySetter.spelling]];
    }

    return [attributeStrings componentsJoinedByString:@", "];
}

/**
 * Returns the spelling of a nullability kind for use in an Objective-C context.
 *
 * In an Objective-C method parameter type, return type, or Objective-C property attribute it is permitted to use
 * friendlier names than the standard _Nonnull, _Nullable, etc.
 */
- (NSString *)objCSpellingForNullability:(PLClangNullability)nullability {
    switch (nullability) {
        case PLClangNullabilityNone:
            return @"";

        case PLClangNullabilityNonnull:
            return @"nonnull";

        case PLClangNullabilityNullable:
            return @"nullable";

        case PLClangNullabilityExplicitlyUnspecified:
            return @"null_unspecified";
    }

    abort();
}

/**
 * Returns the spelling of a type for use in an Objective-C method's parameter or return type.
 */
- (NSString *)spellingForTypeInObjectiveCMethod:(PLClangType *)type {
    PLClangNullability nullability = type.nullability;
    if (nullability != PLClangNullabilityNone) {
        type = [type typeByRemovingOuterNullability];
        return [NSString stringWithFormat:@"%@ %@",
                [self objCSpellingForNullability:nullability],
                type.spelling];
    } else {
        return type.spelling;
    }
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

- (NSString *)stringForProtocolCursors:(NSOrderedSet *)cursors {
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
 * Returns the availability kind for a cursor.
 *
 * Typically the availability kind is indicated via an availability attribute, but in some cases the platform SDKs use
 * an "NSDeprecated" category to indicate deprecations that they wish to document but not yet add an availability
 * attribute for. Old SDKs also used this method to document deprecated methods prior to the introduction of
 * availability attributes.
 */
- (PLClangAvailabilityKind)availabilityKindForCursor:(PLClangCursor *)cursor {
    PLClangAvailabilityKind availabilityKind = cursor.availability.kind;
    if (availabilityKind == PLClangAvailabilityKindAvailable) {
        switch (cursor.kind) {
            case PLClangCursorKindObjCInstanceMethodDeclaration:
            case PLClangCursorKindObjCClassMethodDeclaration:
            case PLClangCursorKindObjCPropertyDeclaration:
            {
                if (cursor.semanticParent.kind == PLClangCursorKindObjCCategoryDeclaration &&
                    [cursor.semanticParent.spelling rangeOfString:@"Deprecated" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                    // The cursor is deprecated via a "Deprecated" category
                    return PLClangAvailabilityKindDeprecated;
                }

                break;
            }

            default:
                break;
        }
    }

    return availabilityKind;
}

- (PLClangPlatformAvailability *)platformAvailabilityForCursor:(PLClangCursor *)cursor targetPlatformName:(NSString *)targetPlatformName {
    for (PLClangPlatformAvailability *availability in cursor.availability.platformAvailabilityEntries) {
        if ([availability.platformName isEqualToString:targetPlatformName]) {
            return availability;
        }
    }

    return nil;
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
