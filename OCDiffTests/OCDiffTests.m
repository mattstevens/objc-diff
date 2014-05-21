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

    XCTAssertEqualObjects(differences, @[]);
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

    XCTAssertEqualObjects(differences, @[]);
}

- (void)testProtocolAddition {
    NSArray *differences = [self differencesBetweenOldSource:@""
                                                   newSource:@"@protocol Test @end"];

    NSArray *expectedDifferences = @[[OCDifference differenceWithType:OCDifferenceTypeAddition name:@"Test"]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testProtocolRemoval {
    NSArray *differences = [self differencesBetweenOldSource:@"@protocol Test @end"
                                                   newSource:@""];

    NSArray *expectedDifferences = @[[OCDifference differenceWithType:OCDifferenceTypeRemoval name:@"Test"]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testProtocolUnchanged {
    NSArray *differences = [self differencesBetweenOldSource:@"@protocol Test @end"
                                                   newSource:@"@protocol Test @end"];

    XCTAssertEqualObjects(differences, @[]);
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

    XCTAssertEqualObjects(differences, @[]);
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

    XCTAssertEqualObjects(differences, @[]);
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

- (void)testProtocolMethodModificationMadeOptional {
    NSArray *differences = [self differencesBetweenOldSource:@"@protocol Test - (void)testMethod; @end"
                                                   newSource:@"@protocol Test @optional - (void)testMethod; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeOptional
                                                            previousValue:@"NO"
                                                             currentValue:@"YES"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"-[Test testMethod]" modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testProtocolMethodModificationMadeRequired {
    NSArray *differences = [self differencesBetweenOldSource:@"@protocol Test @optional - (void)testMethod; @end"
                                                   newSource:@"@protocol Test - (void)testMethod; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeOptional
                                                            previousValue:@"YES"
                                                             currentValue:@"NO"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"-[Test testMethod]" modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testPropertyAddition {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test @end"
                                                   newSource:@"@interface Test @property int testProperty; @end"];

    NSArray *expectedDifferences = @[[OCDifference differenceWithType:OCDifferenceTypeAddition name:@"Test.testProperty"]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testPropertyRemoval {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test @property int testProperty; @end"
                                                   newSource:@"@interface Test @end"];

    NSArray *expectedDifferences = @[[OCDifference differenceWithType:OCDifferenceTypeRemoval name:@"Test.testProperty"]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testPropertyUnchanged {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test @property int testProperty; @end"
                                                   newSource:@"@interface Test @property int testProperty; @end"];

    XCTAssertEqualObjects(differences, @[]);
}

- (void)testPropertyModificationType {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test @property int testProperty; @end"
                                                   newSource:@"@interface Test @property long testProperty; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"@property int testProperty"
                                                             currentValue:@"@property long testProperty"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"Test.testProperty" modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testPropertyModificationTypeAndAttributes {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test @property int testProperty; @end"
                                                   newSource:@"@interface Test @property (nonatomic) long testProperty; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"@property int testProperty"
                                                             currentValue:@"@property (nonatomic) long testProperty"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"Test.testProperty" modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testPropertyModificationAttributes {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test @property (atomic) int testProperty; @end"
                                                   newSource:@"@interface Test @property (nonatomic) int testProperty; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"@property (atomic) int testProperty"
                                                             currentValue:@"@property (nonatomic) int testProperty"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"Test.testProperty" modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

/**
 * Tests that a conversion from explicit accessors to a property is reported only as the addition of the
 * property declaration and not removal of the accessor methods.
 */
- (void)testConversionToProperty {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test - (int)testProperty; - (void)setTestProperty:(int)val; @end"
                                                   newSource:@"@interface Test @property int testProperty; @end"];

    NSArray *expectedDifferences = @[[OCDifference differenceWithType:OCDifferenceTypeAddition name:@"Test.testProperty"]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

/**
 * Tests that a conversion from explicit accessors to a property with a different implicit accessor reports
 * removal of the previous explicit accessor.
 */
- (void)testConversionToPropertyWithRemovedMethod {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test - (BOOL)isTestProperty; - (void)setTestProperty:(BOOL)val; @end"
                                                   newSource:@"@interface Test @property BOOL testProperty; @end"];

    NSArray *expectedDifferences = @[
        [OCDifference differenceWithType:OCDifferenceTypeRemoval name:@"-[Test isTestProperty]"],
        [OCDifference differenceWithType:OCDifferenceTypeAddition name:@"Test.testProperty"]
    ];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testPropertyConversionFromProperty {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test @property int testProperty; @end"
                                                   newSource:@"@interface Test @property - (int)testProperty; - (void)setTestProperty:(int)val; @end"];

    NSArray *expectedDifferences = @[[OCDifference differenceWithType:OCDifferenceTypeRemoval name:@"Test.testProperty"]];
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

    XCTAssertEqualObjects(differences, @[]);
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

    XCTAssertEqualObjects(differences, @[]);
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

- (void)testEnumAddition {
    NSArray *differences = [self differencesBetweenOldSource:@""
                                                   newSource:@"enum Test { TEST };"];

    NSArray *expectedDifferences = @[[OCDifference differenceWithType:OCDifferenceTypeAddition name:@"TEST"]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testAnonymousEnumAddition {
    NSArray *differences = [self differencesBetweenOldSource:@""
                                                   newSource:@"enum { TEST };"];

    NSArray *expectedDifferences = @[[OCDifference differenceWithType:OCDifferenceTypeAddition name:@"TEST"]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

/**
 * Tests the behavior of NS_ENUM when typed enums are not available.
 */
- (void)testEnumWithIntegerTypedefAddition {
    NSArray *differences = [self differencesBetweenOldSource:@""
                                                   newSource:@"typedef int TestEnum; enum { TestEnumValue };"];

    NSArray *expectedDifferences = @[
        [OCDifference differenceWithType:OCDifferenceTypeAddition name:@"TestEnum"],
        [OCDifference differenceWithType:OCDifferenceTypeAddition name:@"TestEnumValue"]
    ];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

/**
 * Tests the behavior of NS_ENUM when typed enums are available.
 */
- (void)testEnumWithTypedefAddition {
    NSArray *differences = [self differencesBetweenOldSource:@""
                                                   newSource:@"typedef enum TestEnum : int TestEnum; enum TestEnum : int { TestEnumValue };"];

    NSArray *expectedDifferences = @[
        [OCDifference differenceWithType:OCDifferenceTypeAddition name:@"TestEnum"],
        [OCDifference differenceWithType:OCDifferenceTypeAddition name:@"TestEnumValue"]
    ];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testEnumWithTypedefRemoval {
    NSArray *differences = [self differencesBetweenOldSource:@"typedef enum TestEnum : int TestEnum; enum TestEnum : int { TestEnumValue };"
                                                   newSource:@""];

    NSArray *expectedDifferences = @[
        [OCDifference differenceWithType:OCDifferenceTypeRemoval name:@"TestEnum"],
        [OCDifference differenceWithType:OCDifferenceTypeRemoval name:@"TestEnumValue"]
    ];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testEnumWithTypedefUnchanged {
    NSArray *differences = [self differencesBetweenOldSource:@"typedef enum TestEnum : int TestEnum; enum TestEnum : int { TestEnumValue };"
                                                   newSource:@"typedef enum TestEnum : int TestEnum; enum TestEnum : int { TestEnumValue };"];

    XCTAssertEqualObjects(differences, @[]);
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

    XCTAssertEqualObjects(differences, @[]);
}

- (void)testEmptyMacroIgnored {
    NSArray *differences = [self differencesBetweenOldSource:@""
                                                   newSource:@"#define TEST "];

    XCTAssertEqualObjects(differences, @[]);
}

- (void)testMacroAddition {
    NSArray *differences = [self differencesBetweenOldSource:@""
                                                   newSource:@"#define TEST 1"];

    NSArray *expectedDifferences = @[[OCDifference differenceWithType:OCDifferenceTypeAddition name:@"#def TEST"]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testMacroRemoval {
    NSArray *differences = [self differencesBetweenOldSource:@"#define TEST 1"
                                                   newSource:@""];

    NSArray *expectedDifferences = @[[OCDifference differenceWithType:OCDifferenceTypeRemoval name:@"#def TEST"]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testMacroUnchanged {
    NSArray *differences = [self differencesBetweenOldSource:@"#define TEST 1"
                                                   newSource:@"#define TEST 1"];

    XCTAssertEqualObjects(differences, @[]);
}

/**
 * Tests that a macro moved to a different line number does not result in any any differences.
 */
- (void)testMacroUnchangedDifferentLineNumber {
    NSArray *differences = [self differencesBetweenOldSource:@"#define TEST 1"
                                                   newSource:@"\n#define TEST 1"];

    XCTAssertEqualObjects(differences, @[]);
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
