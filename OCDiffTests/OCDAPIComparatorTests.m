#import <XCTest/XCTest.h>
#import <ObjectDoc/ObjectDoc.h>
#import "OCDAPIComparator.h"

static NSString * const OCDOldTestPath = @"old/test.h";
static NSString * const OCDNewTestPath = @"new/test.h";
static NSString * const OCDTestPath = @"test.h";

@interface OCDAPIComparatorTests : XCTestCase
@end

@implementation OCDAPIComparatorTests

- (void)testFunction {
    [self testAddRemoveForName:@"Test()"
                          base:@""
                      addition:@"void Test(void);"];
}

- (void)testStaticInlineFunction {
    [self testAddRemoveForName:@"Test()"
                          base:@""
                      addition:@"static __inline__ __attribute__((always_inline)) Test(void) {}"];
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

- (void)testFunctionModificationMadeVariadic {
    NSArray *differences = [self differencesBetweenOldSource:@"void Test(int);"
                                                   newSource:@"void Test(int, ...);"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"void Test(int)"
                                                             currentValue:@"void Test(int, ...)"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test()" modification:modification]);
}

- (void)testFunctionModificationConversionFromUnspecifiedParameters {
    NSArray *differences = [self differencesBetweenOldSource:@"void Test();"
                                                   newSource:@"void Test(void);"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"void Test()"
                                                             currentValue:@"void Test(void)"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test()" modification:modification]);
}

/**
 * Tests that a change to the inline status of a function is not reported as an addition and removal.
 */
- (void)testFunctionModificationInline {
    NSArray *differences = [self differencesBetweenOldSource:@"void Test(void);"
                                                   newSource:@"static __inline__ void Test(void) {}"];

    XCTAssertEqualObjects(differences, @[]);

    differences = [self differencesBetweenOldSource:@"static __inline__ void Test(void) {}"
                                          newSource:@"void Test(void);"];

    XCTAssertEqualObjects(differences, @[]);
}

- (void)testModificationDeprecation {
    NSArray *differences = [self differencesBetweenOldSource:@"void Test(void);"
                                                   newSource:@"void Test(void) __attribute__((deprecated));"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeAvailability
                                                            previousValue:@"Available"
                                                             currentValue:@"Deprecated"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test()" modification:modification]);
}

- (void)testModificationDeprecationWithMessage {
    NSArray *differences = [self differencesBetweenOldSource:@"void Test(void);"
                                                   newSource:@"void Test(void) __attribute__((deprecated(\"Test message\")));"];

    NSArray *modifications = @[
        [OCDModification modificationWithType:OCDModificationTypeAvailability
                               previousValue:@"Available"
                                currentValue:@"Deprecated"],
        [OCDModification modificationWithType:OCDModificationTypeDeprecationMessage
                               previousValue:nil
                                currentValue:@"Test message"]
    ];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"Test()" path:OCDTestPath lineNumber:1 modifications:modifications]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testModificationDeprecationWithReplacement {
    NSArray *differences = [self differencesBetweenOldSource:@"void Test(void);"
                                                   newSource:@"void Test(void) __attribute__((deprecated(\"\",\"NewTest\")));"];

    NSArray *modifications = @[
        [OCDModification modificationWithType:OCDModificationTypeAvailability
                               previousValue:@"Available"
                                currentValue:@"Deprecated"],
        [OCDModification modificationWithType:OCDModificationTypeReplacement
                               previousValue:nil
                                currentValue:@"NewTest"]
    ];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"Test()" path:OCDTestPath lineNumber:1 modifications:modifications]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testModificationDeprecationViaAvailability {
    NSArray *differences = [self differencesBetweenOldSource:@"void Test(void);"
                                                   newSource:@"void Test(void) __attribute__((availability(macos,introduced=10.0,deprecated=10.1)));"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeAvailability
                                                            previousValue:@"Available"
                                                             currentValue:@"Deprecated"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test()" modification:modification]);
}

- (void)testModificationDeprecationViaAvailabilityWithMessage {
    NSArray *differences = [self differencesBetweenOldSource:@"void Test(void);"
                                                   newSource:@"void Test(void) __attribute__((availability(macos,introduced=10.0,deprecated=10.1,message=\"Test message\")));"];

    NSArray *modifications = @[
        [OCDModification modificationWithType:OCDModificationTypeAvailability
                               previousValue:@"Available"
                                currentValue:@"Deprecated"],
        [OCDModification modificationWithType:OCDModificationTypeDeprecationMessage
                               previousValue:nil
                                currentValue:@"Test message"]
    ];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"Test()" path:OCDTestPath lineNumber:1 modifications:modifications]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testModificationDeprecationViaAvailabilityWithReplacement {
    NSArray *differences = [self differencesBetweenOldSource:@"void Test(void);"
                                                   newSource:@"void Test(void) __attribute__((availability(macos,introduced=10.0,deprecated=10.1,replacement=\"NewTest\")));"];

    NSArray *modifications = @[
        [OCDModification modificationWithType:OCDModificationTypeAvailability
                               previousValue:@"Available"
                                currentValue:@"Deprecated"],
        [OCDModification modificationWithType:OCDModificationTypeReplacement
                               previousValue:nil
                                currentValue:@"NewTest"]
    ];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"Test()" path:OCDTestPath lineNumber:1 modifications:modifications]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testModificationDeprecationViaMultiPlatformAvailabilityWithMessage {
    NSArray *differences = [self differencesBetweenOldSource:@"void Test(void);"
                                                   newSource:@"void Test(void) "
                                                             @"__attribute__((availability(ios,introduced=1.0,deprecated=1.1,message=\"iOS test message\"))) "
                                                             @"__attribute__((availability(macos,introduced=10.0,deprecated=10.1,message=\"Test message\")));"];

    NSArray *modifications = @[
        [OCDModification modificationWithType:OCDModificationTypeAvailability
                               previousValue:@"Available"
                                currentValue:@"Deprecated"],
        [OCDModification modificationWithType:OCDModificationTypeDeprecationMessage
                               previousValue:nil
                                currentValue:@"Test message"]
    ];
    NSArray *expectedDifferences = @[[OCDifference modificationDifferenceWithName:@"Test()" path:OCDTestPath lineNumber:1 modifications:modifications]];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testModificationInstanceMethodDeprecationViaCategory {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test - (void)testMethod; @end @interface Test (NSDeprecated) @end"
                                                   newSource:@"@interface Test @end @interface Test (NSDeprecated) - (void)testMethod; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeAvailability
                                                            previousValue:@"Available"
                                                             currentValue:@"Deprecated"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"-[Test testMethod]" modification:modification]);
}

- (void)testModificationClassMethodDeprecationViaCategory {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test + (void)testMethod; @end @interface Test (NSDeprecated) @end"
                                                   newSource:@"@interface Test @end @interface Test (NSDeprecated) + (void)testMethod; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeAvailability
                                                            previousValue:@"Available"
                                                             currentValue:@"Deprecated"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"+[Test testMethod]" modification:modification]);
}

- (void)testModificationPropertyDeprecationViaCategory {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test @property int testProperty; @end @interface Test (NSDeprecated) @end"
                                                   newSource:@"@interface Test @end @interface Test (NSDeprecated) @property int testProperty; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeAvailability
                                                            previousValue:@"Available"
                                                             currentValue:@"Deprecated"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test.testProperty" modification:modification]);
}

/**
 * Tests that a conversion of a deprecation via a category to a deprecation via an attribute does not result in any
 * changes being reported.
 */
- (void)testDeprecationConversionToAttribute {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test @end @interface Test (NSDeprecated) - (void)testMethod; @end"
                                                   newSource:@"@interface Test @end @interface Test (NSDeprecated) - (void)testMethod  __attribute__((deprecated)); @end"];

    XCTAssertEqualObjects(differences, @[]);

    differences = [self differencesBetweenOldSource:@"@interface Test @end @interface Test (NSDeprecated) - (void)testMethod; @end"
                                          newSource:@"@interface Test - (void)testMethod  __attribute__((deprecated)); @end @interface Test (NSDeprecated) @end"];

    XCTAssertEqualObjects(differences, @[]);
}

/**
 * Tests that an unconditionally unavailable declaration is ignored.
 */
- (void)testUnavailable {
    NSArray *differences = [self differencesBetweenOldSource:@""
                                                   newSource:@"void Test(void) __attribute__((unavailable));"];

    XCTAssertEqualObjects(differences, @[]);
}

/**
 * Tests that a declaration unavailable for the target platform is ignored.
 */
- (void)testUnavailableOnPlatform {
    NSArray *differences = [self differencesBetweenOldSource:@""
                                                   newSource:@"void Test(void) __attribute__((availability(macosx,unavailable)));"];

    XCTAssertEqualObjects(differences, @[]);
}

- (void)testClass {
    [self testAddRemoveForName:@"Test"
                          base:@""
                      addition:@"@interface Test @end"];
}

- (void)testClassWithProtocol {
    [self testAddRemoveForName:@"Test"
                          base:@"@protocol A @end"
                      addition:@"@protocol A @end @interface Test <A> @end"];
}

- (void)testParameterizedClass {
    [self testAddRemoveForName:@"Test"
                          base:@""
                      addition:@"@interface Test <__covariant T> @end"];
}

- (void)testClassInstanceVariableIgnored {
    [self testAddRemoveForName:@"Test"
                          base:@""
                      addition:@"@interface Test { int _ivar; } @end"];
}

- (void)testClassModificationSuperclass {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface A @end @interface B : A @end @interface Test : A @end"
                                                   newSource:@"@interface A @end @interface B : A @end @interface Test : B @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeSuperclass
                                                            previousValue:@"A"
                                                             currentValue:@"B"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test" modification:modification]);
}

- (void)testClassModificationAddProtocol {
    NSArray *differences = [self differencesBetweenOldSource:@"@protocol A @end @interface Test @end"
                                                   newSource:@"@protocol A @end @interface Test <A> @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeProtocols
                                                            previousValue:nil
                                                             currentValue:@"A"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test" modification:modification]);
}

- (void)testClassModificationRemoveProtocol {
    NSArray *differences = [self differencesBetweenOldSource:@"@protocol A @end @interface Test <A> @end"
                                                   newSource:@"@protocol A @end @interface Test @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeProtocols
                                                            previousValue:@"A"
                                                             currentValue:nil];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test" modification:modification]);
}

- (void)testClassModificationChangeProtocol {
    NSArray *differences = [self differencesBetweenOldSource:@"@protocol A @end @protocol B @end @interface Test <A> @end"
                                                   newSource:@"@protocol A @end @protocol B @end @interface Test <B> @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeProtocols
                                                            previousValue:@"A"
                                                             currentValue:@"B"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test" modification:modification]);
}

- (void)testClassModificationChangeProtocolList {
    NSArray *differences = [self differencesBetweenOldSource:@"@protocol A @end @protocol B @end @protocol C @end @interface Test <A, B> @end"
                                                   newSource:@"@protocol A @end @protocol B @end @protocol C @end @interface Test <A, C> @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeProtocols
                                                            previousValue:@"A, B"
                                                             currentValue:@"A, C"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test" modification:modification]);
}

/**
 * Tests that no changes are reported for simply reordering a protocol list.
 */
- (void)testClassModificationChangeProtocolOrder {
    NSArray *differences = [self differencesBetweenOldSource:@"@protocol A @end @protocol B @end @interface Test <A, B> @end"
                                                   newSource:@"@protocol A @end @protocol B @end @interface Test <B, A> @end"];

    XCTAssertEqualObjects(differences, @[]);
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

- (void)testInstanceMethodModificationReturnTypeNullability {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test - (nonnull char *)testMethod; @end"
                                                   newSource:@"@interface Test - (nullable char *)testMethod; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"- (nonnull char *)testMethod"
                                                             currentValue:@"- (nullable char *)testMethod"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"-[Test testMethod]" modification:modification]);
}

- (void)testInstanceMethodModificationReturnTypeAssumedNullability {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test - (nullable char *)testMethod; @end"
                                                   newSource:@"_Pragma(\"clang assume_nonnull begin\") @interface Test - (char *)testMethod; @end _Pragma(\"clang assume_nonnull end\")"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"- (nullable char *)testMethod"
                                                             currentValue:@"- (nonnull char *)testMethod"];
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

- (void)testInstanceMethodModificationReturnTypeProtocolList {
    NSArray *differences = [self differencesBetweenOldSource:@"@protocol A @end @protocol B @end @interface Test - (id<A>)testMethod; @end"
                                                   newSource:@"@protocol A @end @protocol B @end @interface Test - (id<B>)testMethod; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"- (id<A>)testMethod"
                                                             currentValue:@"- (id<B>)testMethod"];
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

- (void)testInstanceMethodModificationMadeVariadic {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test - (void)testMethodWithStringAndThings:(const char *)param; @end"
                                                   newSource:@"@interface Test - (void)testMethodWithStringAndThings:(const char *)param, ...; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"- (void)testMethodWithStringAndThings:(const char *)param"
                                                             currentValue:@"- (void)testMethodWithStringAndThings:(const char *)param, ..."];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"-[Test testMethodWithStringAndThings:]" modification:modification]);
}

- (void)testInstanceMethodModificationParameterTypeNullability {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test - (void)testMethodWithParameter:(nullable char *)param; @end"
                                                   newSource:@"@interface Test - (void)testMethodWithParameter:(nonnull char *)param; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"- (void)testMethodWithParameter:(nullable char *)param"
                                                             currentValue:@"- (void)testMethodWithParameter:(nonnull char *)param"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"-[Test testMethodWithParameter:]" modification:modification]);
}

- (void)testInstanceMethodModificationParameterTypeAssumedNullability {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test - (void)testMethodWithParameter:(nullable char *)param; @end"
                                                   newSource:@"_Pragma(\"clang assume_nonnull begin\") @interface Test - (void)testMethodWithParameter:(char *)param; @end _Pragma(\"clang assume_nonnull end\")"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"- (void)testMethodWithParameter:(nullable char *)param"
                                                             currentValue:@"- (void)testMethodWithParameter:(nonnull char *)param"];
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

- (void)testClassMethodModificationMadeVariadic {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test + (void)testMethodWithStringAndThings:(const char *)param; @end"
                                                   newSource:@"@interface Test + (void)testMethodWithStringAndThings:(const char *)param, ...; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"+ (void)testMethodWithStringAndThings:(const char *)param"
                                                             currentValue:@"+ (void)testMethodWithStringAndThings:(const char *)param, ..."];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"+[Test testMethodWithStringAndThings:]" modification:modification]);
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
                                                            previousValue:@"Required"
                                                             currentValue:@"Optional"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"-[Test testMethod]" modification:modification]);
}

- (void)testProtocolMethodMadeRequired {
    NSArray *differences = [self differencesBetweenOldSource:@"@protocol Test @optional - (void)testMethod; @end"
                                                   newSource:@"@protocol Test - (void)testMethod; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeOptional
                                                            previousValue:@"Optional"
                                                             currentValue:@"Required"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"-[Test testMethod]" modification:modification]);
}

- (void)testProtocolPropertyMadeOptional {
    NSArray *differences = [self differencesBetweenOldSource:@"@protocol Test @property int testProperty; @end"
                                                   newSource:@"@protocol Test @optional @property int testProperty; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeOptional
                                                            previousValue:@"Required"
                                                             currentValue:@"Optional"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test.testProperty" modification:modification]);
}

- (void)testProtocolPropertyMadeRequired {
    NSArray *differences = [self differencesBetweenOldSource:@"@protocol Test @optional @property int testProperty; @end"
                                                   newSource:@"@protocol Test @property int testProperty; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeOptional
                                                            previousValue:@"Optional"
                                                             currentValue:@"Required"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test.testProperty" modification:modification]);
}

- (void)testProtocolModificationAddProtocol {
    NSArray *differences = [self differencesBetweenOldSource:@"@protocol A @end @protocol B @end @protocol Test @end"
                                                   newSource:@"@protocol A @end @protocol B @end @protocol Test <A> @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeProtocols
                                                            previousValue:nil
                                                             currentValue:@"A"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test" modification:modification]);
}

- (void)testProtocolModificationRemoveProtocol {
    NSArray *differences = [self differencesBetweenOldSource:@"@protocol A @end @protocol B @end @protocol Test <A> @end"
                                                   newSource:@"@protocol A @end @protocol B @end @protocol Test @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeProtocols
                                                            previousValue:@"A"
                                                             currentValue:nil];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test" modification:modification]);
}

- (void)testProtocolModificationChangeProtocol {
    NSArray *differences = [self differencesBetweenOldSource:@"@protocol A @end @protocol B @end @protocol Test <A> @end"
                                                   newSource:@"@protocol A @end @protocol B @end @protocol Test <B> @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeProtocols
                                                            previousValue:@"A"
                                                             currentValue:@"B"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test" modification:modification]);
}

- (void)testProtocolModificationChangeProtocolList {
    NSArray *differences = [self differencesBetweenOldSource:@"@protocol A @end @protocol B @end @protocol C @end @protocol Test <A, B> @end"
                                                   newSource:@"@protocol A @end @protocol B @end @protocol C @end @protocol Test <A, C> @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeProtocols
                                                            previousValue:@"A, B"
                                                             currentValue:@"A, C"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test" modification:modification]);
}

/**
 * Tests that a category for a class in the same module is not reported.
 *
 * The members of a category are reported, but not the category iself.
 * Modifications that the category makes to the class (e.g. extending protocol
 * conformance) are reported as modifications to the class.
 */
- (void)testCategory {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Base @end"
                                                   newSource:@"@interface Base @end @interface Base (Test) @end"];

    XCTAssertEqualObjects(differences, @[]);
}

- (void)testCategoryMethod {
    [self testAddRemoveForName:@"-[Base testMethod]"
                          base:@"@interface Base @end @interface Base (Test) @end"
                      addition:@"@interface Base @end @interface Base (Test) -(void)testMethod; @end"];
}

- (void)testCategoryProperty {
    [self testAddRemoveForName:@"Base.testProperty"
                          base:@"@interface Base @end @interface Base (Test) @end"
                      addition:@"@interface Base @end @interface Base (Test) @property int testProperty; @end"];
}

- (void)testCategoryModificationAddProtocol {
    NSArray *differences = [self differencesBetweenOldSource:@"@protocol A @end @interface Base @end @interface Base (Test) @end"
                                                   newSource:@"@protocol A @end @interface Base @end @interface Base (Test) <A> @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeProtocols
                                                            previousValue:nil
                                                             currentValue:@"A"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Base" modification:modification]);
}

- (void)testCategoryModificationAddExistingProtocol {
    NSArray *differences = [self differencesBetweenOldSource:@"@protocol A @end @interface Base <A> @end @interface Base (Test) @end"
                                                   newSource:@"@protocol A @end @interface Base <A> @end @interface Base (Test) <A> @end"];

    XCTAssertEqualObjects(differences, @[]);
}

- (void)testCategoryModificationRemoveProtocol {
    NSArray *differences = [self differencesBetweenOldSource:@"@protocol A @end @interface Base @end @interface Base (Test) <A> @end"
                                                   newSource:@"@protocol A @end @interface Base @end @interface Base (Test) @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeProtocols
                                                            previousValue:@"A"
                                                             currentValue:nil];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Base" modification:modification]);
}

- (void)testCategoryModificationChangeProtocol {
    NSArray *differences = [self differencesBetweenOldSource:@"@protocol A @end @protocol B @end @interface Base @end @interface Base (Test) <A> @end"
                                                   newSource:@"@protocol A @end @protocol B @end @interface Base @end @interface Base (Test) <B> @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeProtocols
                                                            previousValue:@"A"
                                                             currentValue:@"B"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Base" modification:modification]);
}

- (void)testCategoryModificationChangeProtocolList {
    NSArray *differences = [self differencesBetweenOldSource:@"@protocol A @end @protocol B @end @protocol C @end @interface Base @end @interface Base (Test) <A, B> @end"
                                                   newSource:@"@protocol A @end @protocol B @end @protocol C @end @interface Base @end @interface Base (Test) <A, C> @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeProtocols
                                                            previousValue:@"A, B"
                                                             currentValue:@"A, C"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Base" modification:modification]);
}

/**
 * Tests that a class extension is not reported.
 *
 * The members of a class extension are reported, but not the extension iself.
 * Modifications that the extension makes to the class (e.g. extending protocol
 * conformance) are reported as modifications to the class.
 */
- (void)testClassExtension {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Base @end"
                                                   newSource:@"@interface Base @end @interface Base () @end"];

    XCTAssertEqualObjects(differences, @[]);
}

- (void)testClassExtensionMethod {
    [self testAddRemoveForName:@"-[Base testMethod]"
                          base:@"@interface Base @end @interface Base () @end"
                      addition:@"@interface Base @end @interface Base () -(void)testMethod; @end"];
}

- (void)testClassExtensionProperty {
    [self testAddRemoveForName:@"Base.testProperty"
                          base:@"@interface Base @end @interface Base () @end"
                      addition:@"@interface Base @end @interface Base () @property int testProperty; @end"];
}

- (void)testClassExtensionModificationAddProtocol {
    NSArray *differences = [self differencesBetweenOldSource:@"@protocol A @end @interface Base @end @interface Base () @end"
                                                   newSource:@"@protocol A @end @interface Base @end @interface Base () <A> @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeProtocols
                                                            previousValue:nil
                                                             currentValue:@"A"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Base" modification:modification]);
}

- (void)testMultipleClassExtensionsMethod {
    [self testAddRemoveForName:@"-[Base testMethod]"
                          base:@"@interface Base @end @interface Base () @end"
                      addition:@"@interface Base @end @interface Base () @end @interface Base () -(void)testMethod; @end"];
}

- (void)testMultipleClassExtensionsProperty {
    [self testAddRemoveForName:@"Base.testProperty"
                          base:@"@interface Base @end @interface Base () @end"
                      addition:@"@interface Base @end @interface Base () @end @interface Base () @property int testProperty; @end"];
}

- (void)testMultipleClassExtensionsModificationAddProtocol {
    NSArray *differences = [self differencesBetweenOldSource:@"@protocol A @end @protocol B @end @interface Base @end @interface Base () @end"
                                                   newSource:@"@protocol A @end @protocol B @end @interface Base @end @interface Base () <A> @end @interface Base () <B> @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeProtocols
                                                            previousValue:nil
                                                             currentValue:@"A, B"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Base" modification:modification]);
}

- (void)testCategoryOnExternalClass {
    NSString *baseSource = @"@interface Base @end\n";
    PLClangUnsavedFile *baseFile = [PLClangUnsavedFile unsavedFileWithPath:@"/system/Base.h" data:[baseSource dataUsingEncoding:NSUTF8StringEncoding]];

    [self testAddRemoveForName:@"Base (Test)"
                    lineNumber:2
                          base:@"#import <Base.h>"
                      addition:@"#import <Base.h>\n@interface Base (Test) @end"
               additionalFiles:@[baseFile]
           additionalArguments:@[@"-isystem", @"/system"]];
}

- (void)testCategoryOnExternalClassMethod {
    NSString *baseSource = @"@interface Base @end\n";
    PLClangUnsavedFile *baseFile = [PLClangUnsavedFile unsavedFileWithPath:@"/system/Base.h" data:[baseSource dataUsingEncoding:NSUTF8StringEncoding]];

    [self testAddRemoveForName:@"-[Base testMethod]"
                    lineNumber:2
                          base:@"#import <Base.h>\n@interface Base (Test) @end"
                      addition:@"#import <Base.h>\n@interface Base (Test) -(void)testMethod; @end"
               additionalFiles:@[baseFile]
           additionalArguments:@[@"-isystem", @"/system"]];
}

- (void)testCategoryOnExternalClassProperty {
    NSString *baseSource = @"@interface Base @end\n";
    PLClangUnsavedFile *baseFile = [PLClangUnsavedFile unsavedFileWithPath:@"/system/Base.h" data:[baseSource dataUsingEncoding:NSUTF8StringEncoding]];

    [self testAddRemoveForName:@"Base.testProperty"
                    lineNumber:2
                          base:@"#import <Base.h>\n@interface Base (Test) @end"
                      addition:@"#import <Base.h>\n@interface Base (Test) @property int testProperty; @end"
               additionalFiles:@[baseFile]
           additionalArguments:@[@"-isystem", @"/system"]];
}

- (void)testCategoryOnExternalClassModificationAddProtocol {
    NSString *baseSource = @"@interface Base @end\n";
    PLClangUnsavedFile *baseFile = [PLClangUnsavedFile unsavedFileWithPath:@"/system/Base.h" data:[baseSource dataUsingEncoding:NSUTF8StringEncoding]];

    NSArray *differences = [self differencesBetweenOldSource:@"#import <Base.h>\n@protocol A @end @interface Base (Test) @end"
                                                   newSource:@"#import <Base.h>\n@protocol A @end @interface Base (Test) <A> @end"
                                             additionalFiles:@[baseFile]
                                         additionalArguments:@[@"-isystem", @"/system"]];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeProtocols
                                                            previousValue:nil
                                                             currentValue:@"A"];
    NSArray *expectedDifferences = @[
        [OCDifference modificationDifferenceWithName:@"Base (Test)" path:OCDTestPath lineNumber:2 modifications:@[modification]]
    ];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testCategoryOnExternalClassModificationRemoveProtocol {
    NSString *baseSource = @"@interface Base @end\n";
    PLClangUnsavedFile *baseFile = [PLClangUnsavedFile unsavedFileWithPath:@"/system/Base.h" data:[baseSource dataUsingEncoding:NSUTF8StringEncoding]];

    NSArray *differences = [self differencesBetweenOldSource:@"#import <Base.h>\n@protocol A @end @interface Base (Test) <A> @end"
                                                   newSource:@"#import <Base.h>\n@protocol A @end @interface Base (Test) @end"
                                             additionalFiles:@[baseFile]
                                         additionalArguments:@[@"-isystem", @"/system"]];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeProtocols
                                                            previousValue:@"A"
                                                             currentValue:nil];
    NSArray *expectedDifferences = @[
        [OCDifference modificationDifferenceWithName:@"Base (Test)" path:OCDTestPath lineNumber:2 modifications:@[modification]]
    ];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testCategoryOnExternalClassModificationChangeProtocolList {
    NSString *baseSource = @"@interface Base @end\n";
    PLClangUnsavedFile *baseFile = [PLClangUnsavedFile unsavedFileWithPath:@"/system/Base.h" data:[baseSource dataUsingEncoding:NSUTF8StringEncoding]];

    NSArray *differences = [self differencesBetweenOldSource:@"#import <Base.h>\n@protocol A @end @protocol B @end @protocol C @end @interface Base (Test) <A, B> @end"
                                                   newSource:@"#import <Base.h>\n@protocol A @end @protocol B @end @protocol C @end @interface Base (Test) <A, C> @end"
                                             additionalFiles:@[baseFile]
                                         additionalArguments:@[@"-isystem", @"/system"]];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeProtocols
                                                            previousValue:@"A, B"
                                                             currentValue:@"A, C"];
    NSArray *expectedDifferences = @[
        [OCDifference modificationDifferenceWithName:@"Base (Test)" path:OCDTestPath lineNumber:2 modifications:@[modification]]
    ];
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
 * Tests that a modification to a property getter method name is reported.
 */
- (void)testPropertyModificationGetterAttribute {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test @property (getter=test1) int testProperty; @end"
                                                   newSource:@"@interface Test @property (getter=test2) int testProperty; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"@property (getter=test1) int testProperty"
                                                             currentValue:@"@property (getter=test2) int testProperty"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test.testProperty" modification:modification]);
}

/**
 * Tests that a modification to a property setter method name is reported.
 */
- (void)testPropertyModificationSetterAttribute {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test @property (setter=setTest1:) int testProperty; @end"
                                                   newSource:@"@interface Test @property (setter=setTest2:) int testProperty; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"@property (setter=setTest1:) int testProperty"
                                                             currentValue:@"@property (setter=setTest2:) int testProperty"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test.testProperty" modification:modification]);
}

- (void)testPropertyModificationNullability {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test @property (nullable) char *testProperty; @end"
                                                   newSource:@"@interface Test @property (nonnull) char *testProperty; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"@property (nullable) char *testProperty"
                                                             currentValue:@"@property (nonnull) char *testProperty"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test.testProperty" modification:modification]);
}

- (void)testPropertyModificationAssumedNullability {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test @property (nullable) char *testProperty; @end"
                                                   newSource:@"_Pragma(\"clang assume_nonnull begin\") @interface Test @property char *testProperty; @end _Pragma(\"clang assume_nonnull end\")"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"@property (nullable) char *testProperty"
                                                             currentValue:@"@property (nonnull) char *testProperty"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test.testProperty" modification:modification]);
}

- (void)testPropertyModificationNullResettable {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test @property (nonnull) char *testProperty; @end"
                                                   newSource:@"@interface Test @property (null_resettable) char *testProperty; @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"@property (nonnull) char *testProperty"
                                                             currentValue:@"@property (null_resettable) char *testProperty"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test.testProperty" modification:modification]);
}

/**
 * Tests that a conversion from explicit accessors to a property is reported as modifications to the declarations of the accessor methods.
 */
- (void)testConversionToProperty {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test - (int)testProperty; - (void)setTestProperty:(int)val; @end"
                                                   newSource:@"@interface Test @property int testProperty; @end"];

    OCDModification *getterModification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                                  previousValue:@"- (int)testProperty"
                                                                   currentValue:@"@property int testProperty"];

    OCDModification *setterModification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                                  previousValue:@"- (void)setTestProperty:(int)val"
                                                                   currentValue:@"@property int testProperty"];

    NSArray *expectedDifferences = @[
        [OCDifference modificationDifferenceWithName:@"-[Test setTestProperty:]" path:OCDTestPath lineNumber:1 modifications:@[setterModification]],
        [OCDifference modificationDifferenceWithName:@"-[Test testProperty]" path:OCDTestPath lineNumber:1 modifications:@[getterModification]]
    ];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testConversionToPropertyWithChangedType {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test - (int)testProperty; - (void)setTestProperty:(int)val; @end"
                                                   newSource:@"@interface Test @property long testProperty; @end"];

    OCDModification *getterModification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                                  previousValue:@"- (int)testProperty"
                                                                   currentValue:@"@property long testProperty"];

    OCDModification *setterModification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                                  previousValue:@"- (void)setTestProperty:(int)val"
                                                                   currentValue:@"@property long testProperty"];

    NSArray *expectedDifferences = @[
        [OCDifference modificationDifferenceWithName:@"-[Test setTestProperty:]" path:OCDTestPath lineNumber:1 modifications:@[setterModification]],
        [OCDifference modificationDifferenceWithName:@"-[Test testProperty]" path:OCDTestPath lineNumber:1 modifications:@[getterModification]]
    ];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

/**
 * Tests that a conversion from explicit accessors to a property with a different implicit accessor reports removal of the previous explicit accessor.
 */
- (void)testConversionToPropertyWithRemovedMethod {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test - (char)isTestProperty; - (void)setTestProperty:(char)val; @end"
                                                   newSource:@"@interface Test @property char testProperty; @end"];

    OCDModification *setterModification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                                  previousValue:@"- (void)setTestProperty:(char)val"
                                                                   currentValue:@"@property char testProperty"];

    NSArray *expectedDifferences = @[
        [OCDifference differenceWithType:OCDifferenceTypeRemoval name:@"-[Test isTestProperty]" path:OCDTestPath lineNumber:1],
        [OCDifference modificationDifferenceWithName:@"-[Test setTestProperty:]" path:OCDTestPath lineNumber:1 modifications:@[setterModification]]
    ];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

/**
 * Tests that a conversion from a property to explicit accessors is reported as modifications to the declarations of the accessor methods.
 */
- (void)testConversionFromProperty {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test @property int testProperty; @end"
                                                   newSource:@"@interface Test - (int)testProperty; - (void)setTestProperty:(int)val; @end"];

    OCDModification *getterModification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                                  previousValue:@"@property int testProperty"
                                                                   currentValue:@"- (int)testProperty"];

    OCDModification *setterModification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                                  previousValue:@"@property int testProperty"
                                                                   currentValue:@"- (void)setTestProperty:(int)val"];

    NSArray *expectedDifferences = @[
        [OCDifference modificationDifferenceWithName:@"-[Test setTestProperty:]" path:OCDTestPath lineNumber:1 modifications:@[setterModification]],
        [OCDifference modificationDifferenceWithName:@"-[Test testProperty]" path:OCDTestPath lineNumber:1 modifications:@[getterModification]]
    ];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testConversionFromPropertyWithAddedMethod {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test @property (readonly) int testProperty; @end"
                                                   newSource:@"@interface Test - (int)testProperty; - (void)setTestProperty:(int)val; @end"];

    OCDModification *getterModification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                                  previousValue:@"@property (readonly) int testProperty"
                                                                   currentValue:@"- (int)testProperty"];

    NSArray *expectedDifferences = @[
        [OCDifference differenceWithType:OCDifferenceTypeAddition name:@"-[Test setTestProperty:]" path:OCDTestPath lineNumber:1],
        [OCDifference modificationDifferenceWithName:@"-[Test testProperty]" path:OCDTestPath lineNumber:1 modifications:@[getterModification]]
    ];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testClassProperty {
    [self testAddRemoveForName:@"Test.testProperty"
                          base:@"@interface Test @end"
                      addition:@"@interface Test @property (class) int testProperty; @end"];
}

/**
 * Tests that a conversion from explicit accessors to a class property is reported as modifications to the declarations of the accessor methods.
 */
- (void)testConversionToClassProperty {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test + (int)testProperty; + (void)setTestProperty:(int)val; @end"
                                                   newSource:@"@interface Test @property (class) int testProperty; @end"];

    OCDModification *getterModification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                                  previousValue:@"+ (int)testProperty"
                                                                   currentValue:@"@property (class) int testProperty"];

    OCDModification *setterModification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                                  previousValue:@"+ (void)setTestProperty:(int)val"
                                                                   currentValue:@"@property (class) int testProperty"];

    NSArray *expectedDifferences = @[
        [OCDifference modificationDifferenceWithName:@"+[Test setTestProperty:]" path:OCDTestPath lineNumber:1 modifications:@[setterModification]],
        [OCDifference modificationDifferenceWithName:@"+[Test testProperty]" path:OCDTestPath lineNumber:1 modifications:@[getterModification]]
    ];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

/**
 * Tests that a conversion from a class property to explicit accessors is reported as modifications to the declarations of the accessor methods.
 */
- (void)testConversionFromClassProperty {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test @property (class) int testProperty; @end"
                                                   newSource:@"@interface Test + (int)testProperty; + (void)setTestProperty:(int)val; @end"];

    OCDModification *getterModification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                                  previousValue:@"@property (class) int testProperty"
                                                                   currentValue:@"+ (int)testProperty"];

    OCDModification *setterModification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                                  previousValue:@"@property (class) int testProperty"
                                                                   currentValue:@"+ (void)setTestProperty:(int)val"];

    NSArray *expectedDifferences = @[
        [OCDifference modificationDifferenceWithName:@"+[Test setTestProperty:]" path:OCDTestPath lineNumber:1 modifications:@[setterModification]],
        [OCDifference modificationDifferenceWithName:@"+[Test testProperty]" path:OCDTestPath lineNumber:1 modifications:@[getterModification]]
    ];
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
    NSArray *differences = [self differencesBetweenOldSource:@"int *Test;"
                                                   newSource:@"int * const Test;"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"int *Test"
                                                             currentValue:@"int *const Test"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test" modification:modification]);
}

- (void)testVariableModificationPointerNullability {
    NSArray *differences = [self differencesBetweenOldSource:@"int * _Nullable Test;"
                                                   newSource:@"int * _Nonnull Test;"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"int * _Nullable Test"
                                                             currentValue:@"int * _Nonnull Test"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test" modification:modification]);
}

- (void)testVariableModificationPointerAssumedNullability {
    NSArray *differences = [self differencesBetweenOldSource:@"int * _Nullable Test;"
                                                   newSource:@"_Pragma(\"clang assume_nonnull begin\") int * Test; _Pragma(\"clang assume_nonnull end\")"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"int * _Nullable Test"
                                                             currentValue:@"int * _Nonnull Test"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test" modification:modification]);
}

- (void)testVariableModificationCovariantType {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface A @end @interface B @end @interface NSArray<__covariant T> @end NSArray<A *> *Test;"
                                                   newSource:@"@interface A @end @interface B @end @interface NSArray<__covariant T> @end NSArray<B *> *Test;"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"NSArray<A *> *Test"
                                                             currentValue:@"NSArray<B *> *Test"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test" modification:modification]);
}

- (void)testStaticVariable {
    [self testAddRemoveForName:@"Test"
                          base:@""
                      addition:@"static int Test = 1;"];
}

- (void)testTypedef {
    [self testAddRemoveForName:@"Test"
                          base:@""
                      addition:@"typedef int Test;"];
}

- (void)testBlockPointerTypedef {
    [self testAddRemoveForName:@"Test"
                          base:@""
                      addition:@"typedef void (^Test)(id param);"];
}

- (void)testBlockPointerTypedefModificationReturnType {
    NSArray *differences = [self differencesBetweenOldSource:@"typedef void (^Test)(id param);"
                                                   newSource:@"typedef int (^Test)(id param);"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"typedef void (^Test)(id param)"
                                                             currentValue:@"typedef int (^Test)(id param)"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test" modification:modification]);
}

- (void)testBlockPointerTypedefModificationReturnTypeUnnamedParameter {
    NSArray *differences = [self differencesBetweenOldSource:@"typedef void (^Test)(id);"
                                                   newSource:@"typedef int (^Test)(id);"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"typedef void (^Test)(id)"
                                                             currentValue:@"typedef int (^Test)(id)"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test" modification:modification]);
}

- (void)testBlockPointerTypedefModificationParameterTypeNullability {
    NSArray *differences = [self differencesBetweenOldSource:@"typedef void (^Test)(id _Nullable param);"
                                                   newSource:@"typedef void (^Test)(id _Nonnull param);"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"typedef void (^Test)(id _Nullable param)"
                                                             currentValue:@"typedef void (^Test)(id _Nonnull param)"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test" modification:modification]);
}

- (void)testBlockPointerTypedefModificationParameterTypeAssumedNullability {
    NSArray *differences = [self differencesBetweenOldSource:@"typedef void (^Test)(id _Nullable param);"
                                                   newSource:@"_Pragma(\"clang assume_nonnull begin\") typedef void (^Test)(id param); _Pragma(\"clang assume_nonnull end\")"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"typedef void (^Test)(id _Nullable param)"
                                                             currentValue:@"typedef void (^Test)(id _Nonnull param)"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test" modification:modification]);
}

- (void)testFunctionPointerTypedef {
    [self testAddRemoveForName:@"Test"
                          base:@""
                      addition:@"typedef void (*Test)(id param);"];
}

- (void)testFunctionPointerTypedefModificationReturnType {
    NSArray *differences = [self differencesBetweenOldSource:@"typedef void (*Test)(id param);"
                                                   newSource:@"typedef int (*Test)(id param);"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"typedef void (*Test)(id param)"
                                                             currentValue:@"typedef int (*Test)(id param)"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test" modification:modification]);
}

- (void)testFunctionPointerTypedefModificationParameterTypeNullability {
    NSArray *differences = [self differencesBetweenOldSource:@"typedef void (*Test)(id _Nullable param);"
                                                   newSource:@"typedef void (*Test)(id _Nonnull param);"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"typedef void (*Test)(id _Nullable param)"
                                                             currentValue:@"typedef void (*Test)(id _Nonnull param)"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test" modification:modification]);
}

- (void)testFunctionPointerTypedefModificationParameterTypeAssumedNullability {
    NSArray *differences = [self differencesBetweenOldSource:@"typedef void (*Test)(id _Nullable param);"
                                                   newSource:@"_Pragma(\"clang assume_nonnull begin\") typedef void (*Test)(id param); _Pragma(\"clang assume_nonnull end\")"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"typedef void (*Test)(id _Nullable param)"
                                                             currentValue:@"typedef void (*Test)(id _Nonnull param)"];
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
        [OCDifference differenceWithType:OCDifferenceTypeAddition name:@"TestEnum" path:OCDTestPath lineNumber:1],
        [OCDifference differenceWithType:OCDifferenceTypeAddition name:@"TestEnumValue" path:OCDTestPath lineNumber:1]
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
        [OCDifference differenceWithType:OCDifferenceTypeAddition name:@"TestEnum" path:OCDTestPath lineNumber:1],
        [OCDifference differenceWithType:OCDifferenceTypeAddition name:@"TestEnumValue" path:OCDTestPath lineNumber:1]
    ];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testEnumWithTypedefRemoval {
    NSArray *differences = [self differencesBetweenOldSource:@"typedef enum TestEnum : int TestEnum; enum TestEnum : int { TestEnumValue };"
                                                   newSource:@""];

    NSArray *expectedDifferences = @[
        [OCDifference differenceWithType:OCDifferenceTypeRemoval name:@"TestEnum" path:OCDTestPath lineNumber:1],
        [OCDifference differenceWithType:OCDifferenceTypeRemoval name:@"TestEnumValue" path:OCDTestPath lineNumber:1]
    ];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (void)testEnumWithTypedefUnchanged {
    NSArray *differences = [self differencesBetweenOldSource:@"typedef enum TestEnum : int TestEnum; enum TestEnum : int { TestEnumValue };"
                                                   newSource:@"typedef enum TestEnum : int TestEnum; enum TestEnum : int { TestEnumValue };"];

    XCTAssertEqualObjects(differences, @[]);
}

- (void)testEnumFixedTypeChange {
    NSArray *differences = [self differencesBetweenOldSource:@"enum TestEnum : int { TestEnumValue };"
                                                   newSource:@"enum TestEnum : long { TestEnumValue };"];

    XCTAssertEqualObjects(differences, @[]);
}

/**
 * Tests that no changes are reported for conversion from an NS_ENUM-style typedef.
 */
- (void)testConversionFromTypedEnum {
    NSArray *differences = [self differencesBetweenOldSource:@"typedef enum TestOptions : int TestOptions; enum TestOptions : int { TEST };"
                                                   newSource:@"enum { TEST }; typedef int TestOptions;"];

    XCTAssertEqualObjects(differences, @[]);
}

/**
 * Tests that no changes are reported for conversion to an NS_ENUM-style typedef.
 */
- (void)testConversionToTypedEnum {
    NSArray *differences = [self differencesBetweenOldSource:@"enum { TEST }; typedef int TestOptions;"
                                                   newSource:@"typedef enum TestOptions : int TestOptions; enum TestOptions : int { TEST };"];

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
- (void)testFunctionHeaderRelocation {
    [self testHeaderRelocationForName:@"Test()" source:@"void Test(void);"];
}

- (void)testStaticInlineFunctionHeaderRelocation {
    [self testHeaderRelocationForName:@"Test()" source:@"static __inline__ __attribute__((always_inline)) void Test(void) {}"];
}

- (void)testEnumHeaderRelocation {
    [self testHeaderRelocationForName:@"TEST" source:@"enum { TEST };"];
}

- (void)testMacroHeaderRelocation {
    [self testHeaderRelocationForName:@"#def TEST" source:@"#define TEST 1"];
}

/**
 * Tests that movement of a class to a new header is reported only as movement of the class and not all of its contained declarations.
 */
- (void)testClassHeaderRelocation {
    [self testHeaderRelocationForName:@"Test" source:@"@interface Test - (void)testMethod; @end"];
}

/**
 * Tests that movement of a protocol to a new header is reported only as movement of the protocol and not all of its contained declarations.
 */
- (void)testProtocolMovedToDifferentHeader {
    [self testHeaderRelocationForName:@"Test" source:@"@protocol Test - (void)testMethod; @end"];
}

/**
 * Tests that movement of a category to a new header is reported only as movement of the category and not all of its contained declarations.
 */
- (void)testCategoryMovedToDifferentHeader {
    NSString *baseSource = @"@interface Base @end\n";
    PLClangUnsavedFile *baseFile = [PLClangUnsavedFile unsavedFileWithPath:@"/system/Base.h" data:[baseSource dataUsingEncoding:NSUTF8StringEncoding]];

    NSArray *differences = [self differencesBetweenOldPath:@"old.h"
                                                 oldSource:@"#import <Base.h>\n@interface Base (Test) -(void)testMethod; @end"
                                                   newPath:@"new.h"
                                                 newSource:@"#import <Base.h>\n@interface Base (Test) -(void)testMethod; @end"
                                           additionalFiles:@[baseFile]
                                       additionalArguments:@[@"-isystem", @"/system"]];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeHeader previousValue:@"old.h" currentValue:@"new.h"];

    NSArray *expectedDifferences = @[
        [OCDifference modificationDifferenceWithName:@"Base (Test)" path:@"new.h" lineNumber:2 modifications:@[modification]],
        [OCDifference modificationDifferenceWithName:@"Base (Test)" path:@"old.h" lineNumber:2 modifications:@[modification]]
    ];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

/**
 * Tests that a class and its children are recognized if a forward declaration of the class preceeds the declaration.
 */
- (void)testClassForwardDeclaration {
    NSArray *differences = [self differencesBetweenOldSource:@""
                                                   newSource:@"@class Test;\n@interface Test\n- (void)testMethod;\n@end"];

    NSArray *expectedDifferences = @[
        [OCDifference differenceWithType:OCDifferenceTypeAddition name:@"Test" path:OCDTestPath lineNumber:2],
        [OCDifference differenceWithType:OCDifferenceTypeAddition name:@"-[Test testMethod]" path:OCDTestPath lineNumber:3]
    ];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

/**
 * Tests that a protocol and its children are recognized if a forward declaration of the protocol preceeds the declaration.
 */
- (void)testProtocolForwardDeclaration {
    NSArray *differences = [self differencesBetweenOldSource:@""
                                                   newSource:@"@protocol Test;\n@protocol Test\n- (void)testMethod;\n@end"];

    NSArray *expectedDifferences = @[
        [OCDifference differenceWithType:OCDifferenceTypeAddition name:@"Test" path:OCDTestPath lineNumber:2],
        [OCDifference differenceWithType:OCDifferenceTypeAddition name:@"-[Test testMethod]" path:OCDTestPath lineNumber:3]
    ];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

/**
 * Tests that a declaration begining with a '_' and all of its children are ignored.
 */
- (void)testExcludeUnderscorePrefix {
    NSArray *differences = [self differencesBetweenOldSource:@""
                                                   newSource:@"struct _private { int test; };"];

    XCTAssertEqualObjects(differences, @[]);
}

/**
 * Tests that anonymous structs are ignored.
 */
- (void)testExcludeAnonymousStruct {
    NSArray *differences = [self differencesBetweenOldSource:@""
                                                   newSource:@"struct { int test; };"];

    XCTAssertEqualObjects(differences, @[]);
}

/**
 * Tests that attributes are excluded from the reported declaration for modifications.
 */
- (void)testFunctionAttributesExcludedFromDeclaration {
    NSArray *differences = [self differencesBetweenOldSource:@"void Test(void) __attribute__((deprecated));"
                                                   newSource:@"int Test(void) __attribute__((deprecated));"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"void Test(void)"
                                                             currentValue:@"int Test(void)"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test()" modification:modification]);
}

- (void)testInstanceMethodAttributesExcludedFromDeclaration {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test - (int)testMethod __attribute__((deprecated)); @end"
                                                   newSource:@"@interface Test - (long)testMethod __attribute__((deprecated)); @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"- (int)testMethod"
                                                             currentValue:@"- (long)testMethod"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"-[Test testMethod]" modification:modification]);
}

- (void)testClassMethodAttributesExcludedFromDeclaration {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test + (int)testMethod __attribute__((deprecated)); @end"
                                                   newSource:@"@interface Test + (long)testMethod __attribute__((deprecated)); @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"+ (int)testMethod"
                                                             currentValue:@"+ (long)testMethod"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"+[Test testMethod]" modification:modification]);
}

- (void)testPropertyAttributesExcludedFromDeclaration {
    NSArray *differences = [self differencesBetweenOldSource:@"@interface Test @property int testProperty __attribute__((deprecated)); @end"
                                                   newSource:@"@interface Test @property long testProperty __attribute__((deprecated)); @end"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"@property int testProperty"
                                                             currentValue:@"@property long testProperty"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test.testProperty" modification:modification]);
}

- (void)testFunctionCommentsExcludedFromDeclaration {
    NSArray *differences = [self differencesBetweenOldSource:@"void Test(int param1 /* a comment */, int param2);"
                                                   newSource:@"int Test(int param1 /* a comment */, int param2);"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"void Test(int param1, int param2)"
                                                             currentValue:@"int Test(int param1, int param2)"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test()" modification:modification]);
}

- (void)testFunctionLineBreaksExcludedFromDeclaration {
    NSArray *differences = [self differencesBetweenOldSource:@"void Test(int param1,\nint param2);"
                                                   newSource:@"int Test(int param1,\nint param2);"];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeDeclaration
                                                            previousValue:@"void Test(int param1, int param2)"
                                                             currentValue:@"int Test(int param1, int param2)"];
    XCTAssertEqualObjects(differences, [self modificationArrayWithName:@"Test()" modification:modification]);
}

/**
 * Tests that macros defined via compiler arguments are ignored.
 */
- (void)testArgumentDefinedMacroExcluded {
    NSError *error;
    PLClangSourceIndex *index = [PLClangSourceIndex indexWithOptions:PLClangIndexCreationDisplayDiagnostics];
    PLClangUnsavedFile *newFile = [PLClangUnsavedFile unsavedFileWithPath:OCDNewTestPath data:[@"" dataUsingEncoding:NSUTF8StringEncoding]];
    PLClangTranslationUnit *newTU = [index addTranslationUnitWithSourcePath:OCDNewTestPath
                                                               unsavedFiles:@[newFile]
                                                          compilerArguments:@[@"-x", @"objective-c-header", @"-DTEST=1"]
                                                                    options:PLClangTranslationUnitCreationDetailedPreprocessingRecord |
                                                                            PLClangTranslationUnitCreationSkipFunctionBodies
                                                                      error:&error];
    XCTAssertNotNil(newTU, @"Failed to parse: %@", error);
    XCTAssertFalse(newTU.didFail, @"Fatal error encountered during parse");

    NSArray *differences = [OCDAPIComparator differencesBetweenOldTranslationUnit:nil newTranslationUnit:newTU];
    XCTAssertEqualObjects(differences, @[]);
}

- (void)testAddRemoveForName:(NSString *)name base:(NSString *)base addition:(NSString *)addition {
    [self testAddRemoveForName:name lineNumber:1 base:base addition:addition additionalFiles:nil additionalArguments:nil];
}

- (void)testAddRemoveForName:(NSString *)name lineNumber:(NSUInteger)lineNumber base:(NSString *)base addition:(NSString *)addition additionalFiles:(NSArray *)additionalFiles additionalArguments:(NSArray *)additionalArguments {
    NSArray *differences;
    NSArray *expectedDifferences;

    // Addition
    differences = [self differencesBetweenOldSource:base newSource:addition additionalFiles:additionalFiles additionalArguments:additionalArguments];
    expectedDifferences = @[[OCDifference differenceWithType:OCDifferenceTypeAddition name:name path:OCDTestPath lineNumber:lineNumber]];
    XCTAssertEqualObjects(differences, expectedDifferences, @"Addition test failed for %@", name);

    // Removal
    differences = [self differencesBetweenOldSource:addition newSource:base additionalFiles:additionalFiles additionalArguments:additionalArguments];
    expectedDifferences = @[[OCDifference differenceWithType:OCDifferenceTypeRemoval name:name path:OCDTestPath lineNumber:lineNumber]];
    XCTAssertEqualObjects(differences, expectedDifferences, @"Removal test failed for %@", name);

    // Unchanged
    differences = [self differencesBetweenOldSource:addition newSource:addition additionalFiles:additionalFiles additionalArguments:additionalArguments];
    XCTAssertEqualObjects(differences, @[], @"Unchanged test failed for %@", name);

    // Unchanged, different line number
    differences = [self differencesBetweenOldSource:addition newSource:[@"\n" stringByAppendingString:addition] additionalFiles:additionalFiles additionalArguments:additionalArguments];
    XCTAssertEqualObjects(differences, @[], @"Move to different line number test failed for %@", name);
}

- (void)testHeaderRelocationForName:(NSString *)name source:(NSString *)source {
    NSArray *differences = [self differencesBetweenOldPath:@"old.h"
                                                 oldSource:source
                                                   newPath:@"new.h"
                                                 newSource:source];

    OCDModification *modification = [OCDModification modificationWithType:OCDModificationTypeHeader previousValue:@"old.h" currentValue:@"new.h"];

    NSArray *expectedDifferences = @[
        [OCDifference modificationDifferenceWithName:name path:@"new.h" lineNumber:1 modifications:@[modification]],
        [OCDifference modificationDifferenceWithName:name path:@"old.h" lineNumber:1 modifications:@[modification]]
    ];
    XCTAssertEqualObjects(differences, expectedDifferences);
}

- (NSArray *)additionArrayWithName:(NSString *)name {
    return @[[OCDifference differenceWithType:OCDifferenceTypeAddition name:name path:OCDTestPath lineNumber:1]];
}

- (NSArray *)removalArrayWithName:(NSString *)name {
    return @[[OCDifference differenceWithType:OCDifferenceTypeRemoval name:name path:OCDTestPath lineNumber:1]];
}

- (NSArray *)modificationArrayWithName:(NSString *)name modification:(OCDModification *)modification {
    return @[[OCDifference modificationDifferenceWithName:name path:OCDTestPath lineNumber:1 modifications:@[modification]]];
}

- (NSArray *)differencesBetweenOldSource:(NSString *)oldSource newSource:(NSString *)newSource {
    return [self differencesBetweenOldPath:OCDOldTestPath oldSource:oldSource newPath:OCDNewTestPath newSource:newSource additionalFiles:nil additionalArguments:nil];
}

- (NSArray *)differencesBetweenOldSource:(NSString *)oldSource newSource:(NSString *)newSource additionalFiles:(NSArray *)additionalFiles additionalArguments:(NSArray *)additionalArguments {
    return [self differencesBetweenOldPath:OCDOldTestPath oldSource:oldSource newPath:OCDNewTestPath newSource:newSource additionalFiles:additionalFiles additionalArguments:additionalArguments];
}

- (NSArray *)differencesBetweenOldPath:(NSString *)oldPath oldSource:(NSString *)oldSource newPath:(NSString *)newPath newSource:(NSString *)newSource {
    return [self differencesBetweenOldPath:oldPath oldSource:oldSource newPath:newPath newSource:newSource additionalFiles:nil additionalArguments:nil];
}

- (NSArray *)differencesBetweenOldPath:(NSString *)oldPath oldSource:(NSString *)oldSource newPath:(NSString *)newPath newSource:(NSString *)newSource additionalFiles:(NSArray *)additionalFiles additionalArguments:(NSArray *)additionalArguments {
    PLClangSourceIndex *index = [PLClangSourceIndex indexWithOptions:PLClangIndexCreationDisplayDiagnostics];

    PLClangUnsavedFile *oldFile = [PLClangUnsavedFile unsavedFileWithPath:oldPath data:[oldSource dataUsingEncoding:NSUTF8StringEncoding]];
    PLClangUnsavedFile *newFile = [PLClangUnsavedFile unsavedFileWithPath:newPath data:[newSource dataUsingEncoding:NSUTF8StringEncoding]];

    NSMutableArray *oldFiles = [NSMutableArray arrayWithObject:oldFile];
    if (additionalFiles != nil){
        [oldFiles addObjectsFromArray:additionalFiles];
    }

    NSMutableArray *newFiles = [NSMutableArray arrayWithObject:newFile];
    if (additionalFiles != nil){
        [newFiles addObjectsFromArray:additionalFiles];
    }

    NSMutableArray *compilerArguments = [@[@"-x", @"objective-c-header"] mutableCopy];
    if (additionalArguments != nil) {
        [compilerArguments addObjectsFromArray:additionalArguments];
    }

    NSError *error;
    PLClangTranslationUnit *oldTU = [index addTranslationUnitWithSourcePath:oldPath
                                                               unsavedFiles:oldFiles
                                                          compilerArguments:compilerArguments
                                                                    options:PLClangTranslationUnitCreationDetailedPreprocessingRecord |
                                                                            PLClangTranslationUnitCreationSkipFunctionBodies
                                                                      error:&error];
    XCTAssertNotNil(oldTU, @"Failed to parse: %@", error);
    XCTAssertFalse(oldTU.didFail, @"Fatal error encountered during parse");

    PLClangTranslationUnit *newTU = [index addTranslationUnitWithSourcePath:newPath
                                                               unsavedFiles:newFiles
                                                          compilerArguments:compilerArguments
                                                                    options:PLClangTranslationUnitCreationDetailedPreprocessingRecord |
                                                                            PLClangTranslationUnitCreationSkipFunctionBodies
                                                                      error:&error];
    XCTAssertNotNil(newTU, @"Failed to parse: %@", error);
    XCTAssertFalse(newTU.didFail, @"Fatal error encountered during parse");

    return [OCDAPIComparator differencesBetweenOldTranslationUnit:oldTU newTranslationUnit:newTU];
}

@end
