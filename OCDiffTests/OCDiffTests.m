#import <XCTest/XCTest.h>
#import <ObjectDoc/ObjectDoc.h>
#import "OCDAPIComparator.h"

@interface OCDiffTests : XCTestCase
@end

@implementation OCDiffTests

- (void)testFunctionAddition {
    NSArray *differences = [self differencesBetweenOldSource:@""
                                                   newSource:@"void Test(void);"];

    NSArray *expectedDifferences = @[[OCDifference differenceWithType:OCDifferenceTypeAddition name:@"Test()"]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testFunctionRemoval {
    NSArray *differences = [self differencesBetweenOldSource:@"void Test(void);"
                                                   newSource:@""];

    NSArray *expectedDifferences = @[[OCDifference differenceWithType:OCDifferenceTypeRemoval name:@"Test()"]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testFunctionUnchanged {
    NSArray *differences = [self differencesBetweenOldSource:@"void Test(void);"
                                                   newSource:@"void Test(void);"];

    NSArray *expectedDifferences = @[];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testFunctionModificationReturnType {
    NSArray *differences = [self differencesBetweenOldSource:@"void Test(void);"
                                                   newSource:@"int Test(void);"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"void Test(void)"
                                                             currentValue:@"int Test(void)"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"Test()" modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testFunctionModificationParameterType {
    NSArray *differences = [self differencesBetweenOldSource:@"void Test(void);"
                                                   newSource:@"void Test(int);"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"void Test(void)"
                                                             currentValue:@"void Test(int)"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"Test()" modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testModificationDeprecation {
    NSArray *differences = [self differencesBetweenOldSource:@"void Test(void);"
                                                   newSource:@"void Test(void) __attribute__((deprecated));"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeprecation
                                                            previousValue:@"NO"
                                                             currentValue:@"YES"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"Test()" modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testClassAddition {
    NSArray *differences = [self differencesBetweenOldSource:@""
                                                   newSource:@"@interface Test @end"];

    NSArray *expectedDifferences = @[[OCDifference differenceWithType:OCDifferenceTypeAddition name:@"Test"]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testClassRemoval {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test @end"
                                                   newSource:@""];

    NSArray *expectedDifferences = @[[OCDifference differenceWithType:OCDifferenceTypeRemoval name:@"Test"]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testClassUnchanged {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test @end"
                                                   newSource:@"@interface Test @end"];

    NSArray *expectedDifferences = @[];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testInstanceMethodAddition {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test @end"
                                                   newSource:@"@interface Test - (void)testMethod; @end"];

    NSArray *expectedDifferences = @[[OCDifference differenceWithType:OCDifferenceTypeAddition name:@"-[Test testMethod]"]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testInstanceMethodRemoval {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test - (void)testMethod; @end"
                                                   newSource:@"@interface Test @end"];

    NSArray *expectedDifferences = @[[OCDifference differenceWithType:OCDifferenceTypeRemoval name:@"-[Test testMethod]"]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testInstanceMethodUnchanged {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test - (void)testMethod; @end"
                                                   newSource:@"@interface Test - (void)testMethod; @end"];

    NSArray *expectedDifferences = @[];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testInstanceMethodModificationReturnType {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test - (void)testMethod; @end"
                                                   newSource:@"@interface Test - (int)testMethod; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"- (void)testMethod"
                                                             currentValue:@"- (int)testMethod"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"-[Test testMethod]" modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testInstanceMethodModificationParameterType {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test - (void)testMethodWithParameter:(int)param; @end"
                                                   newSource:@"@interface Test - (void)testMethodWithParameter:(long)param; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"- (void)testMethodWithParameter:(int)param"
                                                             currentValue:@"- (void)testMethodWithParameter:(long)param"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"-[Test testMethodWithParameter:]" modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testClassMethodAddition {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test @end"
                                                   newSource:@"@interface Test + (void)testMethod; @end"];

    NSArray *expectedDifferences = @[[OCDifference differenceWithType:OCDifferenceTypeAddition name:@"+[Test testMethod]"]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testClassMethodRemoval {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test + (void)testMethod; @end"
                                                   newSource:@"@interface Test @end"];

    NSArray *expectedDifferences = @[[OCDifference differenceWithType:OCDifferenceTypeRemoval name:@"+[Test testMethod]"]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testClassMethodUnchanged {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test + (void)testMethod; @end"
                                                   newSource:@"@interface Test + (void)testMethod; @end"];

    NSArray *expectedDifferences = @[];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testClassMethodModificationReturnType {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test + (void)testMethod; @end"
                                                   newSource:@"@interface Test + (int)testMethod; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"+ (void)testMethod"
                                                             currentValue:@"+ (int)testMethod"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"+[Test testMethod]" modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testClassMethodModificationParameterType {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test + (void)testMethodWithParameter:(int)param; @end"
                                                   newSource:@"@interface Test + (void)testMethodWithParameter:(long)param; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"+ (void)testMethodWithParameter:(int)param"
                                                             currentValue:@"+ (void)testMethodWithParameter:(long)param"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"+[Test testMethodWithParameter:]" modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testVariableAddition {
    NSArray *differences = [self differencesBetweenOldSource:@""
                                                   newSource:@"int Test;"];

    NSArray *expectedDifferences = @[[OCDifference differenceWithType:OCDifferenceTypeAddition name:@"Test"]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testVariableRemoval {
    NSArray *differences = [self differencesBetweenOldSource:@"int Test;"
                                                   newSource:@""];

    NSArray *expectedDifferences = @[[OCDifference differenceWithType:OCDifferenceTypeRemoval name:@"Test"]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testVariableUnchanged {
    NSArray *differences = [self differencesBetweenOldSource:@"int Test;"
                                                   newSource:@"int Test;"];

    NSArray *expectedDifferences = @[];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testVariableModificationType {
    NSArray *differences = [self differencesBetweenOldSource:@"int Test;"
                                                   newSource:@"long Test;"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"int Test"
                                                             currentValue:@"long Test"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"Test" modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testVariableModificationPointerType {
    NSArray *differences = [self differencesBetweenOldSource:@"int *Test;"
                                                   newSource:@"long *Test;"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"int *Test"
                                                             currentValue:@"long *Test"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"Test" modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testVariableModificationConstQualification {
    NSArray *differences = [self differencesBetweenOldSource:@"int * Test;"
                                                   newSource:@"int * const Test;"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"int * Test"
                                                             currentValue:@"int * const Test"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"Test" modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testBlockTypedefAddition {
    NSArray *differences = [self differencesBetweenOldSource:@""
                                                   newSource:@"typedef void (^Test)(id param);"];

    NSArray *expectedDifferences = @[[OCDifference differenceWithType:OCDifferenceTypeAddition name:@"Test"]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testBlockTypedefRemoval {
    NSArray *differences = [self differencesBetweenOldSource:@"typedef void (^Test)(id param);"
                                                   newSource:@""];

    NSArray *expectedDifferences = @[[OCDifference differenceWithType:OCDifferenceTypeRemoval name:@"Test"]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testBlockTypedefUnchanged {
    NSArray *differences = [self differencesBetweenOldSource:@"typedef void (^Test)(id param);"
                                                   newSource:@"typedef void (^Test)(id param);"];

    NSArray *expectedDifferences = @[];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testBlockTypedefModificationReturnType {
    NSArray *differences = [self differencesBetweenOldSource:@"typedef void (^Test)(id param);"
                                                   newSource:@"typedef int (^Test)(id param);"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"typedef void (^Test)(id param)"
                                                             currentValue:@"typedef int (^Test)(id param)"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"Test" modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testEnumConstantAddition {
    NSArray *differences = [self differencesBetweenOldSource:@"enum Test {};"
                                                   newSource:@"enum Test { TEST };"];

    NSArray *expectedDifferences = @[[OCDifference differenceWithType:OCDifferenceTypeAddition name:@"TEST"]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testEnumConstantRemoval {
    NSArray *differences = [self differencesBetweenOldSource:@"enum Test { TEST };"
                                                   newSource:@"enum Test {};"];

    NSArray *expectedDifferences = @[[OCDifference differenceWithType:OCDifferenceTypeRemoval name:@"TEST"]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testEnumConstantUnchanged {
    NSArray *differences = [self differencesBetweenOldSource:@"enum Test { TEST };"
                                                   newSource:@"enum Test { TEST };"];

    NSArray *expectedDifferences = @[];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (NSArray *)differencesBetweenOldSource:(NSString *)oldSource newSource:(NSString *)newSource {
    PLClangSourceIndex *index = [PLClangSourceIndex indexWithOptions:0];

    PLClangUnsavedFile *oldFile = [PLClangUnsavedFile unsavedFileWithPath:@"old/test.h" data:[oldSource dataUsingEncoding:NSUTF8StringEncoding]];
    PLClangUnsavedFile *newFile = [PLClangUnsavedFile unsavedFileWithPath:@"new/test.h" data:[newSource dataUsingEncoding:NSUTF8StringEncoding]];


    NSError *error;
    PLClangTranslationUnit *oldTU = [index addTranslationUnitWithSourcePath:@"old/test.h"
                                                               unsavedFiles:@[oldFile]
                                                          compilerArguments:@[@"-x", @"objective-c-header"]
                                                                    options:PLClangTranslationUnitCreationDetailedPreprocessingRecord
                                                                      error:&error];
    XCTAssertNotNil(oldTU, @"Failed to parse: %@", error);

    PLClangTranslationUnit *newTU = [index addTranslationUnitWithSourcePath:@"new/test.h"
                                                               unsavedFiles:@[newFile]
                                                          compilerArguments:@[@"-x", @"objective-c-header"]
                                                                    options:PLClangTranslationUnitCreationDetailedPreprocessingRecord
                                                                      error:&error];
    XCTAssertNotNil(newTU, @"Failed to parse: %@", error);

    OCDAPIComparator *comparator = [[OCDAPIComparator alloc] initWithOldTranslationUnits:[NSSet setWithObject:oldTU]
                                                                     newTranslationUnits:[NSSet setWithObject:newTU]
                                                                            unsavedFiles:@[oldFile, newFile]];
    return [comparator computeDifferences];
}

@end
