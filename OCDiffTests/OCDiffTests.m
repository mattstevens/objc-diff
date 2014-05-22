#import <XCTest/XCTest.h>
#import <ObjectDoc/ObjectDoc.h>
#import "OCDAPIComparator.h"

static NSString * const OCDOldTestPath = @"old/test.h";
static NSString * const OCDNewTestPath = @"new/test.h";

@interface OCDiffTests : XCTestCase
@end

@implementation OCDiffTests

- (void)testFunction {
    [self testAddRemoveForName:@"Test()"
                          base:@""
                      addition:@"void Test(void);"];
}

- (void)testFunctionModificationReturnType {
    NSArray *differences = [self differencesBetweenOldSource:@"void Test(void);"
                                                   newSource:@"int Test(void);"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"void Test(void)"
                                                             currentValue:@"int Test(void)"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"Test()" path:OCDNewTestPath lineNumber:1 modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testFunctionModificationParameterType {
    NSArray *differences = [self differencesBetweenOldSource:@"void Test(void);"
                                                   newSource:@"void Test(int);"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"void Test(void)"
                                                             currentValue:@"void Test(int)"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"Test()" path:OCDNewTestPath lineNumber:1 modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testModificationDeprecation {
    NSArray *differences = [self differencesBetweenOldSource:@"void Test(void);"
                                                   newSource:@"void Test(void) __attribute__((deprecated));"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeprecation
                                                            previousValue:@"NO"
                                                             currentValue:@"YES"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"Test()" path:OCDNewTestPath lineNumber:1 modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testClass {
    [self testAddRemoveForName:@"Test"
                          base:@""
                      addition:@"@interface Test @end"];
}

- (void)testInstanceMethod {
    [self testAddRemoveForName:@"-[Test testMethod]"
                          base:@"@interface Test @end"
                      addition:@"@interface Test - (void)testMethod; @end"];
}

- (void)testInstanceMethodModificationReturnType {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test - (void)testMethod; @end"
                                                   newSource:@"@interface Test - (int)testMethod; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"- (void)testMethod"
                                                             currentValue:@"- (int)testMethod"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"-[Test testMethod]" path:OCDNewTestPath lineNumber:1 modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testInstanceMethodModificationParameterType {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test - (void)testMethodWithParameter:(int)param; @end"
                                                   newSource:@"@interface Test - (void)testMethodWithParameter:(long)param; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"- (void)testMethodWithParameter:(int)param"
                                                             currentValue:@"- (void)testMethodWithParameter:(long)param"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"-[Test testMethodWithParameter:]" path:OCDNewTestPath lineNumber:1 modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testClassMethod {
    [self testAddRemoveForName:@"+[Test testMethod]"
                          base:@"@interface Test @end"
                      addition:@"@interface Test + (void)testMethod; @end"];
}

- (void)testClassMethodModificationReturnType {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test + (void)testMethod; @end"
                                                   newSource:@"@interface Test + (int)testMethod; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"+ (void)testMethod"
                                                             currentValue:@"+ (int)testMethod"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"+[Test testMethod]" path:OCDNewTestPath lineNumber:1 modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testClassMethodModificationParameterType {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test + (void)testMethodWithParameter:(int)param; @end"
                                                   newSource:@"@interface Test + (void)testMethodWithParameter:(long)param; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"+ (void)testMethodWithParameter:(int)param"
                                                             currentValue:@"+ (void)testMethodWithParameter:(long)param"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"+[Test testMethodWithParameter:]" path:OCDNewTestPath lineNumber:1 modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testProtocol {
    [self testAddRemoveForName:@"Test"
                          base:@""
                      addition:@"@protocol Test @end"];
}

- (void)testProtocolMethodMadeOptional {
    NSArray *differences = [self differencesBetweenOldSource:@"@protocol Test - (void)testMethod; @end"
                                                   newSource:@"@protocol Test @optional - (void)testMethod; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeOptional
                                                            previousValue:@"NO"
                                                             currentValue:@"YES"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"-[Test testMethod]" path:OCDNewTestPath lineNumber:1 modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testProtocolMethodMadeRequired {
    NSArray *differences = [self differencesBetweenOldSource:@"@protocol Test @optional - (void)testMethod; @end"
                                                   newSource:@"@protocol Test - (void)testMethod; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeOptional
                                                            previousValue:@"YES"
                                                             currentValue:@"NO"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"-[Test testMethod]" path:OCDNewTestPath lineNumber:1 modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testProtocolPropertyMadeOptional {
    NSArray *differences = [self differencesBetweenOldSource:@"@protocol Test @property int testProperty; @end"
                                                   newSource:@"@protocol Test @optional @property int testProperty; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeOptional
                                                            previousValue:@"NO"
                                                             currentValue:@"YES"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"Test.testProperty" path:OCDNewTestPath lineNumber:1 modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testProtocolPropertyMadeRequired {
    NSArray *differences = [self differencesBetweenOldSource:@"@protocol Test @optional @property int testProperty; @end"
                                                   newSource:@"@protocol Test @property int testProperty; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeOptional
                                                            previousValue:@"YES"
                                                             currentValue:@"NO"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"Test.testProperty" path:OCDNewTestPath lineNumber:1 modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testProperty {
    [self testAddRemoveForName:@"Test.testProperty"
                          base:@"@interface Test @end"
                      addition:@"@interface Test @property int testProperty; @end"];
}

- (void)testPropertyModificationType {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test @property int testProperty; @end"
                                                   newSource:@"@interface Test @property long testProperty; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"@property int testProperty"
                                                             currentValue:@"@property long testProperty"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"Test.testProperty" path:OCDNewTestPath lineNumber:1 modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testPropertyModificationTypeAndAttributes {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test @property int testProperty; @end"
                                                   newSource:@"@interface Test @property (nonatomic) long testProperty; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"@property int testProperty"
                                                             currentValue:@"@property (nonatomic) long testProperty"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"Test.testProperty" path:OCDNewTestPath lineNumber:1 modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testPropertyModificationAttributes {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test @property (atomic) int testProperty; @end"
                                                   newSource:@"@interface Test @property (nonatomic) int testProperty; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"@property (atomic) int testProperty"
                                                             currentValue:@"@property (nonatomic) int testProperty"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"Test.testProperty" path:OCDNewTestPath lineNumber:1 modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

/**
 * Tests that a conversion from explicit accessors to a property is reported only as the addition of the
 * property declaration and not removal of the accessor methods.
 */
- (void)testConversionToProperty {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test - (int)testProperty; - (void)setTestProperty:(int)val; @end"
                                                   newSource:@"@interface Test @property int testProperty; @end"];

    XCTAssertEqualObjects(differences, [self additionArrayWithName:@"Test.testProperty"]);
}

/**
 * Tests that a conversion from explicit accessors to a property with a different implicit accessor reports
 * removal of the previous explicit accessor.
 */
- (void)testConversionToPropertyWithRemovedMethod {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test - (BOOL)isTestProperty; - (void)setTestProperty:(BOOL)val; @end"
                                                   newSource:@"@interface Test @property BOOL testProperty; @end"];

    NSArray *expectedDifferences = @[
        [OCDifference differenceWithType:OCDifferenceTypeRemoval name:@"-[Test isTestProperty]" path:OCDOldTestPath lineNumber:1],
        [OCDifference differenceWithType:OCDifferenceTypeAddition name:@"Test.testProperty" path:OCDNewTestPath lineNumber:1]
    ];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testConversionFromProperty {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test @property int testProperty; @end"
                                                   newSource:@"@interface Test @property - (int)testProperty; - (void)setTestProperty:(int)val; @end"];

    NSArray *expectedDifferences = @[[OCDifference differenceWithType:OCDifferenceTypeRemoval name:@"Test.testProperty" path:OCDOldTestPath lineNumber:1]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testVariable {
    [self testAddRemoveForName:@"Test"
                          base:@""
                      addition:@"int Test;"];
}

- (void)testVariableModificationType {
    NSArray *differences = [self differencesBetweenOldSource:@"int Test;"
                                                   newSource:@"long Test;"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"int Test"
                                                             currentValue:@"long Test"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"Test" path:OCDNewTestPath lineNumber:1 modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testVariableModificationConstQualification {
    NSArray *differences = [self differencesBetweenOldSource:@"int Test;"
                                                   newSource:@"const int Test;"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"int Test"
                                                             currentValue:@"const int Test"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"Test" path:OCDNewTestPath lineNumber:1 modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testVariableModificationPointerType {
    NSArray *differences = [self differencesBetweenOldSource:@"int *Test;"
                                                   newSource:@"long *Test;"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"int *Test"
                                                             currentValue:@"long *Test"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"Test" path:OCDNewTestPath lineNumber:1 modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testVariableModificationConstPointerQualification {
    NSArray *differences = [self differencesBetweenOldSource:@"int * Test;"
                                                   newSource:@"int * const Test;"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"int * Test"
                                                             currentValue:@"int * const Test"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"Test" path:OCDNewTestPath lineNumber:1 modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testBlockTypedef {
    [self testAddRemoveForName:@"Test"
                          base:@""
                      addition:@"typedef void (^Test)(id param);"];
}

- (void)testBlockTypedefModificationReturnType {
    NSArray *differences = [self differencesBetweenOldSource:@"typedef void (^Test)(id param);"
                                                   newSource:@"typedef int (^Test)(id param);"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"typedef void (^Test)(id param)"
                                                             currentValue:@"typedef int (^Test)(id param)"];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"Test" path:OCDNewTestPath lineNumber:1 modifications:@[modification]]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

/**
 * Tests that addition / removal of the enum constant is reported, but not the enum declaration.
 */
- (void)testEnum {
    [self testAddRemoveForName:@"TEST"
                          base:@""
                      addition:@"enum Test { TEST };"];
}

/**
 * Tests that addition / removal of the enum constant is reported, but not the anonymous enum declaration.
 */
- (void)testAnonymousEnum {
    [self testAddRemoveForName:@"TEST"
                          base:@""
                      addition:@"enum { TEST };"];
}

/**
 * Tests the behavior of NS_ENUM when typed enums are not available.
 */
- (void)testEnumWithIntegerTypedefAddition {
    NSArray *differences = [self differencesBetweenOldSource:@""
                                                   newSource:@"typedef int TestEnum; enum { TestEnumValue };"];

    NSArray *expectedDifferences = @[
        [OCDifference differenceWithType:OCDifferenceTypeAddition name:@"TestEnum" path:OCDNewTestPath lineNumber:1],
        [OCDifference differenceWithType:OCDifferenceTypeAddition name:@"TestEnumValue" path:OCDNewTestPath lineNumber:1]
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
        [OCDifference differenceWithType:OCDifferenceTypeAddition name:@"TestEnum" path:OCDNewTestPath lineNumber:1],
        [OCDifference differenceWithType:OCDifferenceTypeAddition name:@"TestEnumValue" path:OCDNewTestPath lineNumber:1]
    ];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testEnumWithTypedefRemoval {
    NSArray *differences = [self differencesBetweenOldSource:@"typedef enum TestEnum : int TestEnum; enum TestEnum : int { TestEnumValue };"
                                                   newSource:@""];

    NSArray *expectedDifferences = @[
        [OCDifference differenceWithType:OCDifferenceTypeRemoval name:@"TestEnum" path:OCDOldTestPath lineNumber:1],
        [OCDifference differenceWithType:OCDifferenceTypeRemoval name:@"TestEnumValue" path:OCDOldTestPath lineNumber:1]
    ];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testEnumWithTypedefUnchanged {
    NSArray *differences = [self differencesBetweenOldSource:@"typedef enum TestEnum : int TestEnum; enum TestEnum : int { TestEnumValue };"
                                                   newSource:@"typedef enum TestEnum : int TestEnum; enum TestEnum : int { TestEnumValue };"];

    XCTAssertEqualObjects(differences, @[]);
}

- (void)testEnumConstant {
    [self testAddRemoveForName:@"#def TEST"
                          base:@""
                      addition:@"#define TEST 1"];
}

- (void)testMacro {
    [self testAddRemoveForName:@"TEST"
                          base:@"enum Test {};"
                      addition:@"enum Test { TEST };"];
}

- (void)testEmptyMacroIgnored {
    NSArray *differences = [self differencesBetweenOldSource:@""
                                                   newSource:@"#define TEST "];

    XCTAssertEqualObjects(differences, @[]);
}

/**
 * Tests that a macro moved to a different line number does not result in any differences.
 */
- (void)testMacroUnchangedDifferentLineNumber {
    NSArray *differences = [self differencesBetweenOldSource:@"#define TEST 1"
                                                   newSource:@"\n#define TEST 1"];

    XCTAssertEqualObjects(differences, @[]);
}

- (void)testAddRemoveForName:(NSString *)name base:(NSString *)base addition:(NSString *)addition {
    NSArray *differences;
    NSArray *expectedDifferences;

    // Addition
    differences = [self differencesBetweenOldSource:base newSource:addition];
    expectedDifferences = @[[OCDifference differenceWithType:OCDifferenceTypeAddition name:name path:OCDNewTestPath lineNumber:1]];
    XCTAssertEqualObjects(differences, expectedDifferences, @"Addition test failed for %@", name);

    // Removal
    differences = [self differencesBetweenOldSource:addition newSource:base];
    expectedDifferences = @[[OCDifference differenceWithType:OCDifferenceTypeRemoval name:name path:OCDOldTestPath lineNumber:1]];
    XCTAssertEqualObjects(differences, expectedDifferences, @"Removal test failed for %@", name);

    // Unchanged
    differences = [self differencesBetweenOldSource:addition newSource:addition];
    XCTAssertEqualObjects(differences, @[], @"Unchanged test failed for %@", name);
}

- (NSArray *)additionArrayWithName:(NSString *)name {
    return @[[OCDifference differenceWithType:OCDifferenceTypeAddition name:name path:OCDNewTestPath lineNumber:1]];
}

- (NSArray *)removalArrayWithName:(NSString *)name {
    return @[[OCDifference differenceWithType:OCDifferenceTypeRemoval name:name path:OCDOldTestPath lineNumber:1]];
}

- (NSArray *)differencesBetweenOldSource:(NSString *)oldSource newSource:(NSString *)newSource {
    PLClangSourceIndex *index = [PLClangSourceIndex indexWithOptions:0];

    PLClangUnsavedFile *oldFile = [PLClangUnsavedFile unsavedFileWithPath:OCDOldTestPath data:[oldSource dataUsingEncoding:NSUTF8StringEncoding]];
    PLClangUnsavedFile *newFile = [PLClangUnsavedFile unsavedFileWithPath:OCDNewTestPath data:[newSource dataUsingEncoding:NSUTF8StringEncoding]];


    NSError *error;
    PLClangTranslationUnit *oldTU = [index addTranslationUnitWithSourcePath:OCDOldTestPath
                                                               unsavedFiles:@[oldFile]
                                                          compilerArguments:@[@"-x", @"objective-c-header"]
                                                                    options:PLClangTranslationUnitCreationDetailedPreprocessingRecord
                                                                      error:&error];
    XCTAssertNotNil(oldTU, @"Failed to parse: %@", error);

    PLClangTranslationUnit *newTU = [index addTranslationUnitWithSourcePath:OCDNewTestPath
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
