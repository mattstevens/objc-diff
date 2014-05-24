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
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test()" modification:modification]);
}

- (void)testFunctionModificationParameterAdded {
    NSArray *differences = [self differencesBetweenOldSource:@"void Test(void);"
                                                   newSource:@"void Test(int);"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"void Test(void)"
                                                             currentValue:@"void Test(int)"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test()" modification:modification]);
}

- (void)testFunctionModificationParameterType {
    NSArray *differences = [self differencesBetweenOldSource:@"void Test(int);"
                                                   newSource:@"void Test(long);"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"void Test(int)"
                                                             currentValue:@"void Test(long)"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test()" modification:modification]);
}

- (void)testModificationDeprecation {
    NSArray *differences = [self differencesBetweenOldSource:@"void Test(void);"
                                                   newSource:@"void Test(void) __attribute__((deprecated));"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeprecation
                                                            previousValue:@"NO"
                                                             currentValue:@"YES"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test()" modification:modification]);
}

- (void)testClass {
    [self testAddRemoveForName:@"Test"
                          base:@""
                      addition:@"@interface Test @end"];
}

- (void)testClassModificationSuperclass {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface A @end @interface B : A @end @interface Test : A @end"
                                                   newSource:@"@interface A @end @interface B : A @end @interface Test : B @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeSuperclass
                                                            previousValue:@"A"
                                                             currentValue:@"B"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test" modification:modification]);
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
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"-[Test testMethod]" modification:modification]);
}

- (void)testInstanceMethodModificationReturnTypeConstQualitification {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test - (char *)testMethod; @end"
                                                   newSource:@"@interface Test - (const char *)testMethod; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"- (char *)testMethod"
                                                             currentValue:@"- (const char *)testMethod"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"-[Test testMethod]" modification:modification]);
}

- (void)testInstanceMethodModificationReturnTypeDifferentObjectType {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface A @end @interface B : A @end @interface Test - (B *)testMethod; @end"
                                                   newSource:@"@interface A @end @interface B : A @end @interface Test - (A *)testMethod; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"- (B *)testMethod"
                                                             currentValue:@"- (A *)testMethod"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"-[Test testMethod]" modification:modification]);
}

- (void)testInstanceMethodModificationParameterType {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test - (void)testMethodWithParameter:(int)param; @end"
                                                   newSource:@"@interface Test - (void)testMethodWithParameter:(long)param; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"- (void)testMethodWithParameter:(int)param"
                                                             currentValue:@"- (void)testMethodWithParameter:(long)param"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"-[Test testMethodWithParameter:]" modification:modification]);
}

- (void)testInstanceMethodModificationParameterTypeConstQualification {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test - (void)testMethodWithParameter:(char *)param; @end"
                                                   newSource:@"@interface Test - (void)testMethodWithParameter:(const char *)param; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"- (void)testMethodWithParameter:(char *)param"
                                                             currentValue:@"- (void)testMethodWithParameter:(const char *)param"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"-[Test testMethodWithParameter:]" modification:modification]);
}

- (void)testInstanceMethodModificationParameterTypeDifferentObjectType {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface A @end @interface B : A @end @interface Test - (void)testMethodWithParameter:(B *)param; @end"
                                                   newSource:@"@interface A @end @interface B : A @end @interface Test - (void)testMethodWithParameter:(A *)param; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"- (void)testMethodWithParameter:(B *)param"
                                                             currentValue:@"- (void)testMethodWithParameter:(A *)param"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"-[Test testMethodWithParameter:]" modification:modification]);
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
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"+[Test testMethod]" modification:modification]);
}

- (void)testClassMethodModificationParameterType {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test + (void)testMethodWithParameter:(int)param; @end"
                                                   newSource:@"@interface Test + (void)testMethodWithParameter:(long)param; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"+ (void)testMethodWithParameter:(int)param"
                                                             currentValue:@"+ (void)testMethodWithParameter:(long)param"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"+[Test testMethodWithParameter:]" modification:modification]);
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
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"-[Test testMethod]" modification:modification]);
}

- (void)testProtocolMethodMadeRequired {
    NSArray *differences = [self differencesBetweenOldSource:@"@protocol Test @optional - (void)testMethod; @end"
                                                   newSource:@"@protocol Test - (void)testMethod; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeOptional
                                                            previousValue:@"YES"
                                                             currentValue:@"NO"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"-[Test testMethod]" modification:modification]);
}

- (void)testProtocolPropertyMadeOptional {
    NSArray *differences = [self differencesBetweenOldSource:@"@protocol Test @property int testProperty; @end"
                                                   newSource:@"@protocol Test @optional @property int testProperty; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeOptional
                                                            previousValue:@"NO"
                                                             currentValue:@"YES"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test.testProperty" modification:modification]);
}

- (void)testProtocolPropertyMadeRequired {
    NSArray *differences = [self differencesBetweenOldSource:@"@protocol Test @optional @property int testProperty; @end"
                                                   newSource:@"@protocol Test @property int testProperty; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeOptional
                                                            previousValue:@"YES"
                                                             currentValue:@"NO"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test.testProperty" modification:modification]);
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
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test.testProperty" modification:modification]);
}

- (void)testPropertyModificationTypeAndAttributes {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test @property int testProperty; @end"
                                                   newSource:@"@interface Test @property (nonatomic) long testProperty; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"@property int testProperty"
                                                             currentValue:@"@property (nonatomic) long testProperty"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test.testProperty" modification:modification]);
}

- (void)testPropertyModificationAttributes {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test @property (atomic) int testProperty; @end"
                                                   newSource:@"@interface Test @property (nonatomic) int testProperty; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"@property (atomic) int testProperty"
                                                             currentValue:@"@property (nonatomic) int testProperty"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test.testProperty" modification:modification]);
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
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test - (char)isTestProperty; - (void)setTestProperty:(char)val; @end"
                                                   newSource:@"@interface Test @property char testProperty; @end"];

    NSArray *expectedDifferences = @[
        [OCDifference differenceWithType:OCDifferenceTypeRemoval name:@"-[Test isTestProperty]" path:OCDOldTestPath lineNumber:1],
        [OCDifference differenceWithType:OCDifferenceTypeAddition name:@"Test.testProperty" path:OCDNewTestPath lineNumber:1]
    ];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testConversionFromProperty {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test @property int testProperty; @end"
                                                   newSource:@"@interface Test - (int)testProperty; - (void)setTestProperty:(int)val; @end"];

    XCTAssertEqualObjects(differences, [self removalArrayWithName:@"Test.testProperty"]);
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
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test" modification:modification]);
}

- (void)testVariableModificationConstQualification {
    NSArray *differences = [self differencesBetweenOldSource:@"int Test;"
                                                   newSource:@"const int Test;"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"int Test"
                                                             currentValue:@"const int Test"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test" modification:modification]);
}

- (void)testVariableModificationPointerType {
    NSArray *differences = [self differencesBetweenOldSource:@"int *Test;"
                                                   newSource:@"long *Test;"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"int *Test"
                                                             currentValue:@"long *Test"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test" modification:modification]);
}

- (void)testVariableModificationConstPointerQualification {
    NSArray *differences = [self differencesBetweenOldSource:@"int * Test;"
                                                   newSource:@"int * const Test;"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"int * Test"
                                                             currentValue:@"int * const Test"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test" modification:modification]);
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
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test" modification:modification]);
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
    [self testAddRemoveForName:@"TEST"
                          base:@"enum Test { EXISTING };"
                      addition:@"enum Test { EXISTING, TEST };"];
}

- (void)testMacro {
    [self testAddRemoveForName:@"#def TEST"
                          base:@""
                      addition:@"#define TEST 1"];
}

- (void)testEmptyMacroIgnored {
    NSArray *differences = [self differencesBetweenOldSource:@""
                                                   newSource:@"#define TEST "];

    XCTAssertEqualObjects(differences, @[]);
}

/**
 * Tests that a declaration moved between headers is reported as a movement for both the old location and the new one.
 */
- (void)testFunctionMovedToDifferentHeader {
    NSArray *differences = [self differencesBetweenOldPath:@"old.h"
                                                 oldSource:@"void Test(void);"
                                                   newPath:@"new.h"
                                                 newSource:@"void Test(void);"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeHeader previousValue:@"old.h" currentValue:@"new.h"];

    NSArray *expectedDifferences = @[
        [OCDifference modificationDifferenceWithName:@"Test()" path:@"new.h" lineNumber:1 modifications:@[modification]],
        [OCDifference modificationDifferenceWithName:@"Test()" path:@"old.h" lineNumber:1 modifications:@[modification]]
    ];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

/**
 * Tests that movement of a class to a new header is reported only as movement of the class and not all of its contained declarations.
 */
- (void)testClassMovedToDifferentHeader {
    NSArray *differences = [self differencesBetweenOldPath:@"old.h"
                                                 oldSource:@"@interface Test - (void)testMethod; @end"
                                                   newPath:@"new.h"
                                                 newSource:@"@interface Test - (void)testMethod; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeHeader previousValue:@"old.h" currentValue:@"new.h"];

    NSArray *expectedDifferences = @[
        [OCDifference modificationDifferenceWithName:@"Test" path:@"new.h" lineNumber:1 modifications:@[modification]],
        [OCDifference modificationDifferenceWithName:@"Test" path:@"old.h" lineNumber:1 modifications:@[modification]]
    ];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

/**
 * Tests that movement of a protocol to a new header is reported only as movement of the protocol and not all of its contained declarations.
 */
- (void)testProtocolMovedToDifferentHeader {
    NSArray *differences = [self differencesBetweenOldPath:@"old.h"
                                                 oldSource:@"@protocol Test - (void)testMethod; @end"
                                                   newPath:@"new.h"
                                                 newSource:@"@protocol Test - (void)testMethod; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeHeader previousValue:@"old.h" currentValue:@"new.h"];

    NSArray *expectedDifferences = @[
        [OCDifference modificationDifferenceWithName:@"Test" path:@"new.h" lineNumber:1 modifications:@[modification]],
        [OCDifference modificationDifferenceWithName:@"Test" path:@"old.h" lineNumber:1 modifications:@[modification]]
    ];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testClassForwardDeclaration {
    NSArray *differences = [self differencesBetweenOldSource:@""
                                                   newSource:@"@class Test;\n@interface Test\n- (void)testMethod;\n@end"];

    NSArray *expectedDifferences = @[
        [OCDifference differenceWithType:OCDifferenceTypeAddition name:@"Test" path:OCDNewTestPath lineNumber:2],
        [OCDifference differenceWithType:OCDifferenceTypeAddition name:@"-[Test testMethod]" path:OCDNewTestPath lineNumber:3]
    ];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testProtocolForwardDeclaration {
    NSArray *differences = [self differencesBetweenOldSource:@""
                                                   newSource:@"@protocol Test;\n@protocol Test\n- (void)testMethod;\n@end"];

    NSArray *expectedDifferences = @[
        [OCDifference differenceWithType:OCDifferenceTypeAddition name:@"Test" path:OCDNewTestPath lineNumber:2],
        [OCDifference differenceWithType:OCDifferenceTypeAddition name:@"-[Test testMethod]" path:OCDNewTestPath lineNumber:3]
    ];
    XCTAssertEqualObjects(differences, expectedDifferences);
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

    // Unchanged, different line number
    differences = [self differencesBetweenOldSource:addition newSource:[@"\n" stringByAppendingString:addition]];
    XCTAssertEqualObjects(differences, @[], @"Move to different line number test failed for %@", name);
}

- (NSArray *)additionArrayWithName:(NSString *)name {
    return @[[OCDifference differenceWithType:OCDifferenceTypeAddition name:name path:OCDNewTestPath lineNumber:1]];
}

- (NSArray *)removalArrayWithName:(NSString *)name {
    return @[[OCDifference differenceWithType:OCDifferenceTypeRemoval name:name path:OCDOldTestPath lineNumber:1]];
}

- (NSArray *)modificationArrayWithName:(NSString *)name modification:(OCDModification *)modification {
    return @[[OCDifference modificationDifferenceWithName:name path:OCDNewTestPath lineNumber:1 modifications:@[modification]]];
}

- (NSArray *)differencesBetweenOldSource:(NSString *)oldSource newSource:(NSString *)newSource {
    return [self differencesBetweenOldPath:OCDOldTestPath oldSource:oldSource newPath:OCDNewTestPath newSource:newSource];
}

- (NSArray *)differencesBetweenOldPath:(NSString *)oldPath oldSource:(NSString *)oldSource newPath:(NSString *)newPath newSource:(NSString *)newSource {
    PLClangSourceIndex *index = [PLClangSourceIndex indexWithOptions:PLClangIndexCreationDisplayDiagnostics];

    PLClangUnsavedFile *oldFile = [PLClangUnsavedFile unsavedFileWithPath:oldPath data:[oldSource dataUsingEncoding:NSUTF8StringEncoding]];
    PLClangUnsavedFile *newFile = [PLClangUnsavedFile unsavedFileWithPath:newPath data:[newSource dataUsingEncoding:NSUTF8StringEncoding]];


    NSError *error;
    PLClangTranslationUnit *oldTU = [index addTranslationUnitWithSourcePath:oldPath
                                                               unsavedFiles:@[oldFile]
                                                          compilerArguments:@[@"-x", @"objective-c-header"]
                                                                    options:PLClangTranslationUnitCreationDetailedPreprocessingRecord
                                                                      error:&error];
    XCTAssertNotNil(oldTU, @"Failed to parse: %@", error);
    XCTAssertFalse(oldTU.didFail, @"Fatal error encountered during parse");

    PLClangTranslationUnit *newTU = [index addTranslationUnitWithSourcePath:newPath
                                                               unsavedFiles:@[newFile]
                                                          compilerArguments:@[@"-x", @"objective-c-header"]
                                                                    options:PLClangTranslationUnitCreationDetailedPreprocessingRecord
                                                                      error:&error];
    XCTAssertNotNil(newTU, @"Failed to parse: %@", error);
    XCTAssertFalse(newTU.didFail, @"Fatal error encountered during parse");

    OCDAPIComparator *comparator = [[OCDAPIComparator alloc] initWithOldTranslationUnits:[NSSet setWithObject:oldTU]
                                                                     newTranslationUnits:[NSSet setWithObject:newTU]
                                                                            unsavedFiles:@[oldFile, newFile]];
    return [comparator computeDifferences];
}

@end
