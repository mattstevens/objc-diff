/*
 * Copyright (c) 2013 Plausible Labs Cooperative, Inc.
 * All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "PLClangAvailability.h"
#import "PLClangComment.h"
#import "PLClangSourceRange.h"
#import "PLClangType.h"
@class PLClangCursor;

/**
 * The kind of a PLClangCursor.
 */
typedef NS_ENUM(NSUInteger, PLClangCursorKind) {
    /* Declarations */

    /**
     * A declaration whose specific kind is not exposed via this
     * interface.
     *
     * Unexposed declarations have the same operations as any
     * other kind of declaration; one can extract their location
     * information, spelling, find their definitions, etc.
     * However, the specific kind of the declaration is not
     * reported.
     */
    PLClangCursorKindUnexposedDeclaration                     = 1,

    /**
     * A struct.
     */
    PLClangCursorKindStructDeclaration                        = 2,

    /**
     * A union.
     */
    PLClangCursorKindUnionDeclaration                         = 3,

    /**
     * A C++ class.
     */
    PLClangCursorKindClassDeclaration                         = 4,

    /**
     * An enumeration.
     */
    PLClangCursorKindEnumDeclaration                          = 5,

    /**
     * A field (in C) or non-static data member (in C++) in a
     * struct, union, or C++ class.
     */
    PLClangCursorKindFieldDeclaration                         = 6,

    /**
     * An enumerator constant.
     */
    PLClangCursorKindEnumConstantDeclaration                  = 7,

    /**
     * A function.
     */
    PLClangCursorKindFunctionDeclaration                      = 8,

    /**
     * A variable.
     */
    PLClangCursorKindVariableDeclaration                      = 9,

    /**
     * A function or method parameter.
     */
    PLClangCursorKindParameterDeclaration                     = 10,

    /**
     * An Objective-C \@interface.
     */
    PLClangCursorKindObjCInterfaceDeclaration                 = 11,

    /**
     * An Objective-C \@interface for a category.
     */
    PLClangCursorKindObjCCategoryDeclaration                  = 12,

    /**
     * An Objective-C \@protocol declaration.
     */
    PLClangCursorKindObjCProtocolDeclaration                  = 13,

    /**
     * An Objective-C \@property declaration.
     */
    PLClangCursorKindObjCPropertyDeclaration                  = 14,

    /**
     * An Objective-C instance variable.
     */
    PLClangCursorKindObjCInstanceVariableDeclaration          = 15,

    /**
     * An Objective-C instance method.
     */
    PLClangCursorKindObjCInstanceMethodDeclaration            = 16,

    /**
     * An Objective-C class method.
     */
    PLClangCursorKindObjCClassMethodDeclaration               = 17,

    /**
     * An Objective-C \@implementation.
     */
    PLClangCursorKindObjCImplementationDeclaration            = 18,

    /**
     * An Objective-C \@implementation for a category.
     */
    PLClangCursorKindObjCCategoryImplementationDeclaration    = 19,

    /**
     * A typedef.
     */
    PLClangCursorKindTypedefDeclaration                       = 20,

    /**
     * A C++ class method.
     */
    PLClangCursorKindCXXMethod                                = 21,

    /**
     * A C++ namespace.
     */
    PLClangCursorKindNamespace                                = 22,

    /**
     * A linkage specification such as 'extern "C"'.
     */
    PLClangCursorKindLinkageSpecification                     = 23,

    /**
     * A C++ constructor.
     */
    PLClangCursorKindConstructor                              = 24,

    /**
     * A C++ destructor.
     */
    PLClangCursorKindDestructor                               = 25,

    /**
     * A C++ conversion function.
     */
    PLClangCursorKindConversionFunction                       = 26,

    /**
     * A C++ template type parameter.
     */
    PLClangCursorKindTemplateTypeParameter                    = 27,

    /**
     * A C++ non-type template parameter.
     */
    PLClangCursorKindNonTypeTemplateParameter                 = 28,

    /**
     * A C++ template template parameter.
     */
    PLClangCursorKindTemplateTemplateParameter                = 29,

    /**
     * A C++ function template.
     */
    PLClangCursorKindFunctionTemplate                         = 30,

    /**
     * A C++ class template.
     */
    PLClangCursorKindClassTemplate                            = 31,

    /**
     * A C++ class template partial specialization.
     */
    PLClangCursorKindClassTemplatePartialSpecialization       = 32,

    /**
     * A C++ namespace alias declaration.
     */
    PLClangCursorKindNamespaceAlias                           = 33,

    /**
     * A C++ using directive.
     */
    PLClangCursorKindUsingDirective                           = 34,

    /**
     * A C++ using declaration.
     */
    PLClangCursorKindUsingDeclaration                         = 35,

    /**
     * A C++ alias declaration.
     */
    PLClangCursorKindTypeAliasDeclaration                     = 36,

    /**
     * An Objective-C \@synthesize declaration.
     */
    PLClangCursorKindObjCSynthesizeDeclaration                = 37,

    /**
     * An Objective-C \@dynamic declaration.
     */
    PLClangCursorKindObjCDynamicDeclaration                   = 38,

    /**
     * An access specifier.
     */
    PLClangCursorKindCXXAccessSpecifier                       = 39,

    /* References */

    /**
     * A reference to an Objective-C superclass.
     */
    PLClangCursorKindObjCSuperclassReference                  = 40,

    /**
     * A reference to an Objective-C protocol.
     */
    PLClangCursorKindObjCProtocolReference                    = 41,

    /**
     * A reference to an Objective-C class.
     */
    PLClangCursorKindObjCClassReference                       = 42,

    /**
     * A reference to a type declaration.
     *
     * A type reference occurs anywhere a type is named but not
     * declared. For example, given:
     *
     * @code
     * typedef unsigned size_type;
     * size_type size;
     * @endcode
     *
     * The typedef is a declaration of @c size_type
     * (PLClangCursorKindTypedefDeclaration), while the type of
     * the variable @c size is referenced. The cursor referenced by
     * the type of @c size is the typedef for @c size_type.
     */
    PLClangCursorKindTypeReference                            = 43,

    /**
     * A C++ base class (or struct) specifier.
     */
    PLClangCursorKindCXXBaseSpecifier                         = 44,

    /**
     * A reference to a class template, function template, template
     * template parameter, or class template partial specialization.
     */
    PLClangCursorKindTemplateReference                        = 45,

    /**
     * A reference to a namespace or namespace alias.
     */
    PLClangCursorKindNamespaceReference                       = 46,

    /**
     * A reference to a member of a struct, union, or class that
     * occurs in some non-expression context, e.g., a designated
     * initializer.
     */
    PLClangCursorKindMemberReference                          = 47,

    /**
     * A reference to a labeled statement.
     *
     * This cursor kind is used to describe the jump to @c start_over
     * in the goto statement in the following example:
     *
     * @code
     * start_over:
     *   ++counter;
     *
     *   goto start_over;
     * @endcode
     */
    PLClangCursorKindLabelReference                           = 48,

    /**
     * A reference to a set of overloaded functions or function
     * templates that has not yet been resolved to a specific function
     * or function template.
     *
     * An overloaded declaration reference cursor occurs in C++
     * templates where a dependent name refers to a function.
     * For example:
     *
     * @code
     * template<typename T> void swap(T&, T&);
     *
     * struct X { ... };
     * void swap(X&, X&);
     *
     * template<typename T>
     * void reverse(T* first, T* last) {
     *   while (first < last - 1) {
     *     swap(*first, *--last);
     *     ++first;
     *   }
     * }
     *
     * struct Y { };
     * void swap(Y&, Y&);
     * @endcode
     *
     * Here, the identifier @c swap is associated with an overloaded
     * declaration reference. In the template definition, @c swap
     * refers to either of the two @c swap functions declared above,
     * so both results will be available. At instantiation time,
     * @c swap may also refer to other functions found via
     * argument-dependent lookup (e.g., the @c swap function at the
     * end of the example).
     *
     * The @c overloadedDeclarations property can be used to
     * retrieve the definitions referenced by this cursor.
     */
    PLClangCursorKindOverloadedDeclarationReference           = 49,

    /**
     * A reference to a variable that occurs in some non-expression
     * context, e.g., a C++ lambda capture list.
     */
    PLClangCursorKindVariableReference                        = 50,

    /* Expressions */

    /**
     * An expression whose specific kind is not exposed via this
     * interface.
     *
     * Unexposed expressions have the same operations as any other kind
     * of expression; one can extract their location information,
     * spelling, children, etc. However, the specific kind of the
     * expression is not reported.
     */
    PLClangCursorKindUnexposedExpression                      = 100,

    /**
     * An expression that refers to some value declaration, such
     * as a function, varible, or enumerator.
     */
    PLClangCursorKindDeclarationReferenceExpression           = 101,

    /**
     * An expression that refers to a member of a struct, union,
     * class, Objective-C class, etc.
     */
    PLClangCursorKindMemberReferenceExpression                = 102,

    /**
     * An expression that calls a function.
     */
    PLClangCursorKindCallExpression                           = 103,

    /**
     * An expression that sends a message to an Objective-C
     * object or class.
     */
    PLClangCursorKindObjCMessageExpression                    = 104,

    /**
     * A block expression.
     */
    PLClangCursorKindBlockExpression                          = 105,

    /**
     * An integer literal.
     */
    PLClangCursorKindIntegerLiteral                           = 106,

    /**
     * A floating point number literal.
     */
    PLClangCursorKindFloatingLiteral                          = 107,

    /**
     * An imaginary number literal.
     */
    PLClangCursorKindImaginaryLiteral                         = 108,

    /**
     * A string literal.
     */
    PLClangCursorKindStringLiteral                            = 109,

    /**
     * A character literal.
     */
    PLClangCursorKindCharacterLiteral                         = 110,

    /**
     * A parenthesized expression, e.g. "(1)".
     *
     * This AST node is only formed if full location information
     * is requested.
     */
    PLClangCursorKindParenthesizedExpression                  = 111,

    /**
     * A unary operator expression.
     */
    PLClangCursorKindUnaryOperator                            = 112,

    /**
     * An array subscripting expression.
     */
    PLClangCursorKindArraySubscriptExpression                 = 113,

    /**
     * A builtin binary operation expression such as "x + y" or
     * "x <= y".
     */
    PLClangCursorKindBinaryOperator                           = 114,

    /**
     * A compound assignment such as "+=".
     */
    PLClangCursorKindCompoundAssignmentOperator               = 115,

    /**
     * The ?: ternary operator.
     */
    PLClangCursorKindConditionalOperator                      = 116,

    /**
     * An explicit cast in C or a C-style cast in C++ that uses the
     * syntax (type)expression.
     *
     * For example: (int)f.
     */
    PLClangCursorKindCStyleCastExpression                     = 117,

    /**
     * A compound literal expression.
     */
    PLClangCursorKindCompoundLiteralExpression                = 118,

    /**
     * A C or C++ initializer list.
     */
    PLClangCursorKindInitializerListExpression                = 119,

    /**
     * A GNU address of label extension, representing &&label.
     */
    PLClangCursorKindAddressLabelExpression                   = 120,

    /**
     * A GNU statement expression extension: ({int X=4; X;})
     */
    PLClangCursorKindStatementExpression                      = 121,

    /**
     * A C11 generic selection.
     */
    PLClangCursorKindGenericSelectionExpression               = 122,

    /**
     * The GNU __null extension, which is a name for a null pointer
     * constant that has integral type (e.g., int or long) and is the
     * same size and alignment as a pointer.
     *
     * The __null extension is typically only used by system headers,
     * which define NULL as __null in C++ rather than using 0 (which
     * is an integer that may not match the size of a pointer).
     */
    PLClangCursorKindGNUNullExpression                        = 123,

    /**
     * A C++ static_cast<> expression.
     */
    PLClangCursorKindCXXStaticCastExpression                  = 124,

    /**
     * A C++ dynamic_cast<> expression.
     */
    PLClangCursorKindCXXDynamicCastExpression                 = 125,

    /**
     * A C++ reinterpret_cast<> expression.
     */
    PLClangCursorKindCXXReinterpretCastExpression             = 126,

    /**
     * A C++ const_cast<> expression.
     */
    PLClangCursorKindCXXConstCastExpression                   = 127,

    /**
     * An explicit C++ type conversion that uses "functional"
     * notion (C++ [expr.type.conv]). For example:
     *
     * @code
     * x = int(0.5);
     * @endcode
     */
    PLClangCursorKindCXXFunctionalCastExpression              = 128,

    /**
     * A C++ typeid expression (C++ [expr.typeid]).
     */
    PLClangCursorKindCXXTypeidExpression                      = 129,

    /**
     * A C++ Boolean literal ([C++ 2.13.5]).
     */
    PLClangCursorKindCXXBoolLiteralExpression                 = 130,

    /**
     * A C++ nullptr literal ([C++0x 2.14.7]).
     */
    PLClangCursorKindCXXNullPtrLiteralExpression              = 131,

    /**
     * A C++ this expression.
     */
    PLClangCursorKindCXXThisExpression                        = 132,

    /**
     * A C++ throw expression.
     *
     * This handles 'throw' and 'throw' assignment-expression. When
     * assignment-expression isn't present, Op will be null.
     */
    PLClangCursorKindCXXThrowExpression                       = 133,

    /**
     * A new expression for memory allocation and constructor calls,
     * e.g., "new CXXNewExpr(foo)".
     */
    PLClangCursorKindCXXNewExpression                         = 134,

    /**
     * A delete expression for memory deallocation and destructor
     * calls, e.g. "delete[] pArray".
     */
    PLClangCursorKindCXXDeleteExpression                      = 135,

    /**
     * A unary expression.
     */
    PLClangCursorKindUnaryExpression                          = 136,

    /**
     * An Objective-C string literal i.e. @"foo".
     */
    PLClangCursorKindObjCStringLiteral                        = 137,

    /**
     * An Objective-C \@encode expression.
     */
    PLClangCursorKindObjCEncodeExpression                     = 138,

    /**
     * An Objective-C \@selector expression.
     */
    PLClangCursorKindObjCSelectorExpression                   = 139,

    /**
     * An Objective-C \@protocol expression.
     */
    PLClangCursorKindObjCProtocolExpression                   = 140,

    /**
     * An Objective-C "bridged" cast expression, which casts between
     * Objective-C pointers and C pointers, transferring ownership
     * in the process.
     *
     * @code
     * NSString *str = (__bridge_transfer NSString *)CFCreateString();
     * @endcode
     */
    PLClangCursorKindObjCBridgedCastExpression                = 141,

    /**
     * A C++0x pack expansion that produces a sequence of expressions.
     *
     * A pack expansion expression contains a pattern (which itself is
     * an expression) followed by an ellipsis. For example:
     *
     * @code
     * template<typename F, typename ...Types>
     * void forward(F f, Types &&...args) {
     *  f(static_cast<Types&&>(args)...);
     * }
     * @endcode
     */
    PLClangCursorKindPackExpansionExpression                  = 142,

    /**
     * An expression that computes the length of a parameter pack.
     *
     * @code
     * template<typename ...Types>
     * struct count {
     *   static const unsigned value = sizeof...(Types);
     * };
     * @endcode
     */
    PLClangCursorKindSizeOfPackExpression                     = 143,

    /**
     * A C++ lambda expression that produces a local function object.
     *
     * @code
     * void abssort(float *x, unsigned N) {
     *   std::sort(x, x + N,
     *             [](float a, float b) {
     *               return std::abs(a) < std::abs(b);
     *             });
     * }
     * @endcode
     */
    PLClangCursorKindLambdaExpression                         = 144,

    /**
     * An Objective-C Boolean literal.
     */
    PLClangCursorKindObjCBoolLiteralExpression                = 145,

    /**
     * An Objective-C self expression.
     */
    PLClangCursorKindObjCSelfExpression                       = 146,

    /**
     * An OpenMP array section expression.
     */
    PLClangCursorKindOMPArraySectionExpression                = 147,

    /**
     * An Objective-C an @available() check.
     */
    PLClangCursorKindObjCAvailabilityCheckExpression          = 148,

    /* Statements */

    /**
     * A statement whose specific kind is not exposed via this
     * interface.
     *
     * Unexposed statements have the same operations as any other kind of
     * statement; one can extract their location information, spelling,
     * children, etc. However, the specific kind of the statement is not
     * reported.
     */
    PLClangCursorKindUnexposedStatement                       = 200,

    /**
     * A labeled statement in a function.
     *
     * This cursor kind is used to describe the @c start_over: label
     * statement in the following example:
     *
     * @code
     * start_over:
     *   ++counter;
     * @endcode
     *
     */
    PLClangCursorKindLabelStatement                           = 201,

    /**
     * A group of statements like { stmt stmt }.
     *
     * This cursor kind is used to describe compound statements,
     * e.g. function bodies.
     */
    PLClangCursorKindCompoundStatement                        = 202,

    /**
     * A case statment.
     */
    PLClangCursorKindCaseStatement                            = 203,

    /**
     * A default statement.
     */
    PLClangCursorKindDefaultStatement                         = 204,

    /**
     * An if statement
     */
    PLClangCursorKindIfStatement                              = 205,

    /**
     * A switch statement.
     */
    PLClangCursorKindSwitchStatement                          = 206,

    /**
     * A while statement.
     */
    PLClangCursorKindWhileStatement                           = 207,

    /**
     * A do statement.
     */
    PLClangCursorKindDoStatement                              = 208,

    /**
     * A for statement.
     */
    PLClangCursorKindForStatement                             = 209,

    /**
     * A goto statement.
     */
    PLClangCursorKindGotoStatement                            = 210,

    /**
     * An indirect goto statement.
     */
    PLClangCursorKindIndirectGotoStatement                    = 211,

    /**
     * A continue statement.
     */
    PLClangCursorKindContinueStatement                        = 212,

    /**
     * A break statement.
     */
    PLClangCursorKindBreakStatement                           = 213,

    /**
     * A return statement.
     */
    PLClangCursorKindReturnStatement                          = 214,

    /**
     * An inline assembly statement.
     */
    PLClangCursorKindAsmStatement                             = 215,

    /**
     * An Objective-C overall \@try-\@catch-\@finally statement.
     */
    PLClangCursorKindObjCAtTryStatement                       = 216,

    /**
     * An Objective-C \@catch statement.
     */
    PLClangCursorKindObjCAtCatchStatement                     = 217,

    /**
     * An Objective-C \@finally statement.
     */
    PLClangCursorKindObjCAtFinallyStatement                   = 218,

    /**
     * An Objective-C \@throw statement.
     */
    PLClangCursorKindObjCAtThrowStatement                     = 219,

    /**
     * An Objective-C \@synchronized statement.
     */
    PLClangCursorKindObjCAtSynchronizedStatement              = 220,

    /**
     * An Objective-C \@autoreleasepool statement.
     */
    PLClangCursorKindObjCAutoreleasePoolStatement             = 221,

    /**
     * An Objective-C for (element in collection) statement.
     */
    PLClangCursorKindObjCForCollectionStatement               = 222,

    /**
     * A C++ catch statement.
     */
    PLClangCursorKindCXXCatchStatement                        = 223,

    /**
     * A C++ try statement.
     */
    PLClangCursorKindCXXTryStatement                          = 224,

    /**
     * A C++ for (* : *) statement.
     */
    PLClangCursorKindCXXForRangeStatement                     = 225,

    /**
     * A Windows Structured Exception Handling try statement.
     */
    PLClangCursorKindSEHTryStatement                          = 226,

    /**
     * A Windows Structured Exception Handling except statement.
     */
    PLClangCursorKindSEHExceptStatement                       = 227,

    /**
     * A Windows Structured Exception Handling finally statement.
     */
    PLClangCursorKindSEHFinallyStatement                      = 228,

    /**
     * An MS inline assembly statement extension.
     */
    PLClangCursorKindMSAsmStatement                           = 229,

    /**
     * A null statement ";": C99 6.8.3p3.
     */
    PLClangCursorKindNullStatement                            = 230,

    /**
     * An adaptor class for mixing declarations with statements and
     * expressions.
     */
    PLClangCursorKindDeclarationStatement                     = 231,

    /**
     * An OpenMP parallel directive.
     */
    PLClangCursorKindOMPParallelDirective                     = 232,

    /**
     * An OpenMP SIMD directive.
     */
    PLClangCursorKindOMPSimdDirective                         = 233,

    /**
     * An OpenMP for directive.
     */
    PLClangCursorKindOMPForDirective                          = 234,

    /**
     * An OpenMP sections directive.
     */
    PLClangCursorKindOMPSectionsDirective                     = 235,

    /**
     * An OpenMP section directive.
     */
    PLClangCursorKindOMPSectionDirective                      = 236,

    /**
     * An OpenMP single directive.
     */
    PLClangCursorKindOMPSingleDirective                       = 237,

    /**
     * An OpenMP parallel for directive.
     */
    PLClangCursorKindOMPParallelForDirective                  = 238,

    /**
     * An OpenMP parallel sections directive.
     */
    PLClangCursorKindOMPParallelSectionsDirective             = 239,

    /**
     * An OpenMP task directive.
     */
    PLClangCursorKindOMPTaskDirective                         = 240,

    /**
     * An OpenMP master directive.
     */
    PLClangCursorKindOMPMasterDirective                       = 241,

    /**
     * An OpenMP critical directive.
     */
    PLClangCursorKindOMPCriticalDirective                     = 242,

    /**
     * An OpenMP taskyield directive.
     */
    PLClangCursorKindOMPTaskyieldDirective                    = 243,

    /**
     * An OpenMP barrier directive.
     */
    PLClangCursorKindOMPBarrierDirective                      = 244,

    /**
     * An OpenMP taskwait directive.
     */
    PLClangCursorKindOMPTaskwaitDirective                     = 245,

    /**
     * An OpenMP flush directive.
     */
    PLClangCursorKindOMPFlushDirective                        = 246,

    /**
     * A Windows Structured Exception Handling's leave statement.
     */
    PLClangCursorKindSEHLeaveStatement                        = 247,

    /**
     * An OpenMP ordered directive.
     */
    PLClangCursorKindOMPOrderedDirective                      = 248,

    /**
     * An OpenMP atomic directive.
     */
    PLClangCursorKindOMPAtomicDirective                       = 249,

    /**
     * An OpenMP for SIMD directive.
     */
    PLClangCursorKindOMPForSimdDirective                      = 250,

    /**
     * An OpenMP parallel for SIMD directive.
     */
    PLClangCursorKindOMPParallelForSimdDirective              = 251,

    /**
     * An OpenMP target directive.
     */
    PLClangCursorKindOMPTargetDirective                       = 252,

    /**
     * An OpenMP teams directive.
     */
    PLClangCursorKindOMPTeamsDirective                        = 253,

    /**
     * An OpenMP taskgroup directive.
     */
    PLClangCursorKindOMPTaskgroupDirective                    = 254,

    /**
     * An OpenMP cancellation point directive.
     */
    PLClangCursorKindOMPCancellationPointDirective            = 255,

    /**
     * An OpenMP cancel directive.
     */
    PLClangCursorKindOMPCancelDirective                       = 256,

    /**
     * An OpenMP target data directive.
     */
    PLClangCursorKindOMPTargetDataDirective                   = 257,

    /**
     * An OpenMP taskloop directive.
     */
    PLClangCursorKindOMPTaskLoopDirective                     = 258,

    /**
     * An OpenMP taskloop directive.
     */
    PLClangCursorKindOMPTaskLoopSimdDirective                 = 259,

    /**
     * An OpenMP distribute directive.
     */
    PLClangCursorKindOMPDistributeDirective                   = 260,

    /**
     * An OpenMP target enter data directive.
     */
    PLClangCursorKindOMPTargetEnterDataDirective              = 261,

    /**
     * An OpenMP target exit data directive.
     */
    PLClangCursorKindOMPTargetExitDataDirective               = 262,

    /**
     * An OpenMP target parallel directive.
     */
    PLClangCursorKindOMPTargetParallelDirective               = 263,

    /**
     * An OpenMP target parallel for directive.
     */
    PLClangCursorKindOMPTargetParallelForDirective            = 264,

    /**
     * An OpenMP target update directive.
     */
    PLClangCursorKindOMPTargetUpdateDirective                 = 265,

    /**
     * An OpenMP distribute parallel for directive.
     */
    PLClangCursorKindOMPDistributeParallelForDirective        = 266,

    /**
     * An OpenMP distribute parallel for simd directive.
     */
    PLClangCursorKindOMPDistributeParallelForSimdDirective    = 267,

    /**
     * An OpenMP distribute simd directive.
     */
    PLClangCursorKindOMPDistributeSimdDirective               = 268,

    /**
     * An OpenMP target parallel for simd directive.
     */
    PLClangCursorKindOMPTargetParallelForSimdDirective        = 269,

    /**
     * An OpenMP target simd directive.
     */
    PLClangCursorKindOMPTargetSimdDirective                   = 270,

    /**
     * An OpenMP teams distribute directive.
     */
    PLClangCursorKindOMPTeamsDistributeDirective              = 271,

    /**
     * An OpenMP teams distribute simd directive.
     */
    PLClangCursorKindOMPTeamsDistributeSimdDirective          = 272,

    /**
     * An OpenMP teams distribute parallel for simd directive.
     */
    PLClangCursorKindOMPTeamsDistributeParallelForSimdDirective = 273,

    /**
     * An OpenMP teams distribute parallel for directive.
     */
    PLClangCursorKindOMPTeamsDistributeParallelForDirective   = 274,

    /**
     * An OpenMP target teams directive.
     */
    PLClangCursorKindOMPTargetTeamsDirective                  = 275,

    /**
     * An OpenMP target teams distribute directive.
     */
    PLClangCursorKindOMPTargetTeamsDistributeDirective        = 276,

    /**
     * An OpenMP target teams distribute parallel for directive.
     */
    PLClangCursorKindOMPTargetTeamsDistributeParallelForDirective = 277,

    /**
     * An OpenMP target teams distribute parallel for simd directive.
     */
    PLClangCursorKindOMPTargetTeamsDistributeParallelForSimdDirective = 278,

    /**
     * An OpenMP target teams distribute simd directive.
     */
    PLClangCursorKindOMPTargetTeamsDistributeSimdDirective    = 279,

    /**
     * The translation unit itself.
     *
     * The translation unit cursor exists primarily to act as the root
     * cursor for traversing the contents of a translation unit.
     */
    PLClangCursorKindTranslationUnit                          = 300,

    /* Attributes */

    /**
     * An attribute whose specific kind is not exposed via this
     * interface.
     */
    PLClangCursorKindUnexposedAttribute                       = 400,

    /**
     * An IBAction attribute.
     */
    PLClangCursorKindIBActionAttribute                        = 401,

    /**
     * An IBOutlet attribute.
     */
    PLClangCursorKindIBOutletAttribute                        = 402,

    /**
     * An IBOutletCollection attribute.
     */
    PLClangCursorKindIBOutletCollectionAttribute              = 403,

    /**
     * A C++ final specifier.
     */
    PLClangCursorKindCXXFinalAttribute                        = 404,

    /**
     * A C++ override specifier.
     */
    PLClangCursorKindCXXOverrideAttribute                     = 405,

    /**
     * An annotate attribute.
     */
    PLClangCursorKindAnnotateAttribute                        = 406,

    /**
     * An assembler label.
     */
    PLClangCursorKindAsmLabelAttribute                        = 407,

    /**
     * A packed attribute.
     */
    PLClangCursorKindPackedAttribute                          = 408,

    /**
     * A pure attribute.
     */
    PLClangCursorKindPureAttribute                            = 409,

    /**
     * A const attribute.
     */
    PLClangCursorKindConstAttribute                           = 410,

    /**
     * A noduplicate attribute.
     */
    PLClangCursorKindNoDuplicateAttribute                     = 411,

    /**
     * A CUDA constant attribute.
     */
    PLClangCursorKindCUDAConstantAttribute                    = 412,

    /**
     * A CUDA device attribute.
     */
    PLClangCursorKindCUDADeviceAttribute                      = 413,

    /**
     * A CUDA global attribute.
     */
    PLClangCursorKindCUDAGlobalAttribute                      = 414,

    /**
     * A CUDA host attribute.
     */
    PLClangCursorKindCUDAHostAttribute                        = 415,

    /**
     * A CUDA shared attribute.
     */
    PLClangCursorKindCUDASharedAttribute                      = 416,

    /**
     * A visibility attribute.
     */
    PLClangCursorKindVisibilityAttribute                      = 417,

    /**
     * A dllexport attribute.
     */
    PLClangCursorKindDLLExportAttribute                       = 418,

    /**
     * A dllimport attribute.
     */
    PLClangCursorKindDLLImportAttribute                       = 419,

    /* Preprocessing */

    /**
     * A preprocessing directive.
     */
    PLClangCursorKindPreprocessingDirective                   = 500,

    /**
     * A macro definition.
     */
    PLClangCursorKindMacroDefinition                          = 501,

    /**
     * A macro expansion.
     */
    PLClangCursorKindMacroExpansion                           = 502,

    /**
     * An inclusion directive.
     */
    PLClangCursorKindInclusionDirective                       = 503,

    /* Extra Declarations */

    /**
     * A module import declaration.
     */
    PLClangCursorKindModuleImportDeclaration                  = 600,

    /**
     * An alias template declaration.
     *
     * For example:
     *
     * @code
     * template \<typename T> using V = std::map<T*, int, MyCompare<T>>;
     * @endcode
     */
    PLClangCursorKindTypeAliasTemplateDeclaration             = 601,

    /**
     * A static_assert or _Static_assert node.
     */
    PLClangCursorKindStaticAssert                             = 602,

    /**
     * A friend declaration.
     */
    PLClangCursorKindFriendDeclaration                        = 603,

    /**
     * A code completion overload candidate.
     */
    PLClangCursorKindOverloadCandidate                        = 700,
};

/**
 * The linkage of an entity represented by a PLClangCursor.
 */
typedef NS_ENUM(NSUInteger, PLClangLinkage) {
    /**
     * Indicates that linkage information is not available for this entity.
     */
    PLClangLinkageInvalid        = 0,

    /**
     * No linkage, which means that the entity can only be referenced
     * from within its scope.
     */
    PLClangLinkageNone           = 1,

    /**
     * Internal linkage, which means that the entity can be referenced
     * from within its translation unit but not from other translation
     * units.
     */
    PLClangLinkageInternal       = 2,

    /**
     * External linkage within a C++ anonymous namespace.
     */
    PLClangLinkageUniqueExternal = 3,

    /**
     * External linkage, which means that the entity can be referenced
     * from other translation units.
     */
    PLClangLinkageExternal       = 4
};

/**
 * The language of an entity represented by a PLClangCursor.
 */
typedef NS_ENUM(NSUInteger, PLClangLanguage) {
    /**
     * Indicates that no language information is available.
     */
    PLClangLanguageInvalid   = 0,

    /** C */
    PLClangLanguageC         = 1,

    /** Objective-C */
    PLClangLanguageObjC      = 2,

    /** C++ */
    PLClangLanguageCPlusPlus = 3
};

/**
 * The attributes of an Objective-C property represented by a PLClangCursor.
 */
typedef NS_OPTIONS(NSUInteger, PLClangObjCPropertyAttributes) {
    /**
     * The property has no attributes, or the cursor does not
     * represent a property.
     */
    PLClangObjCPropertyAttributeNone             = 0,

    /** The property is atomic. */
    PLClangObjCPropertyAttributeAtomic           = 1UL << 0,

    /** The property is nonatomic. */
    PLClangObjCPropertyAttributeNonAtomic        = 1UL << 1,

    /** The property is readonly. */
    PLClangObjCPropertyAttributeReadOnly         = 1UL << 2,

    /** The property is readwrite. */
    PLClangObjCPropertyAttributeReadWrite        = 1UL << 3,

    /** The property has assign semantics. */
    PLClangObjCPropertyAttributeAssign           = 1UL << 4,

    /** The property has copy semantics. */
    PLClangObjCPropertyAttributeCopy             = 1UL << 5,

    /** The property has retain semantics. */
    PLClangObjCPropertyAttributeRetain           = 1UL << 6,

    /** The property has __strong semantics. */
    PLClangObjCPropertyAttributeStrong           = 1UL << 7,

    /** The property has __unsafe_unretained semantics. */
    PLClangObjCPropertyAttributeUnsafeUnretained = 1UL << 8,

    /** The property has __weak semantics. */
    PLClangObjCPropertyAttributeWeak             = 1UL << 9,

    /** The property has an explicit getter method. */
    PLClangObjCPropertyAttributeGetter           = 1UL << 10,

    /** The property has an explicit setter method. */
    PLClangObjCPropertyAttributeSetter           = 1UL << 11,

    /** The property's value can never be null. */
    PLClangObjCPropertyAttributeNonnull          = 1UL << 12,

    /** The property's value can be null. */
    PLClangObjCPropertyAttributeNullable         = 1UL << 13,

    /** The property is reset to a default value when null is assigned. */
    PLClangObjCPropertyAttributeNullResettable   = 1UL << 14,

    /** Whether the property's value can be null is explicitly unspecified. */
    PLClangObjCPropertyAttributeNullUnspecified  = 1UL << 15,

    /** The property is a class property. */
    PLClangObjCPropertyAttributeClass            = 1UL << 16,
};

/**
 * Describes how the traversal of the children of a PLClangCursor
 * should proceed after visiting a child cursor.
 */
typedef NS_ENUM(NSUInteger, PLClangCursorVisitResult) {
    /**
     * Ends the cursor traversal.
     */
    PLClangCursorVisitBreak    = 0,

    /**
     * Continues the cursor traversal with the next sibling of
     * the cursor just visited, without visiting its children.
     */
    PLClangCursorVisitContinue = 1,

    /**
     * Recursively traverses the children of this cursor.
     */
    PLClangCursorVisitRecurse  = 2
};

/**
 * Block used when visiting child cursors.
 *
 * @param cursor The cursor being visited.
 * @return A PLClangCursorVisitResult directing the traversal.
 * @sa visitChildrenUsingBlock:
 */
typedef PLClangCursorVisitResult (^PLClangCursorVisitorBlock)(PLClangCursor *cursor);

@interface PLClangCursor : NSObject

@property(nonatomic, readonly) PLClangCursorKind kind;
@property(nonatomic, readonly) PLClangLanguage language;
@property(nonatomic, readonly) PLClangLinkage linkage;

/**
 * The Unified Symbol Resolution (USR) for the entity represented by this cursor.
 *
 * A Unified Symbol Resolution (USR) is a string that identifies a particular
 * entity (function, class, variable, etc.) within a program. USRs can be
 * compared across translation units to determine, e.g., when references in
 * one translation refer to an entity defined in another translation unit.
 */
@property(nonatomic, readonly) NSString *USR;

/**
 * The name of the entity represented by this cursor.
 */
@property(nonatomic, readonly) NSString *spelling;

/**
 * The display name of the entity represented by this cursor.
 *
 * The display name contains extra information that helps identify the cursor,
 * such as the parameters of a function or template or the arguments of a
 * class template specialization.
 */
@property(nonatomic, readonly) NSString *displayName;

@property(nonatomic, readonly) PLClangSourceLocation *location;
@property(nonatomic, readonly) PLClangSourceRange *extent;

@property(nonatomic, readonly) BOOL isAttribute;
@property(nonatomic, readonly) BOOL isDeclaration;
@property(nonatomic, readonly) BOOL isDefinition;
@property(nonatomic, readonly) BOOL isExpression;
@property(nonatomic, readonly) BOOL isPreprocessing;
@property(nonatomic, readonly) BOOL isReference;
@property(nonatomic, readonly) BOOL isStatement;
@property(nonatomic, readonly) BOOL isUnexposed;
@property(nonatomic, readonly) BOOL isObjCOptional;
@property(nonatomic, readonly) BOOL isVariadic;
@property(nonatomic, readonly) BOOL isImplicit;

@property(nonatomic, readonly) PLClangCursor *canonicalCursor;
@property(nonatomic, readonly) PLClangCursor *semanticParent;
@property(nonatomic, readonly) PLClangCursor *lexicalParent;
@property(nonatomic, readonly) PLClangCursor *referencedCursor;
@property(nonatomic, readonly) PLClangCursor *definition;

@property(nonatomic, readonly) PLClangType *type;
@property(nonatomic, readonly) PLClangType *underlyingType;
@property(nonatomic, readonly) PLClangType *resultType;
@property(nonatomic, readonly) PLClangType *receiverType;

@property(nonatomic, readonly) PLClangType *enumIntegerType;
@property(nonatomic, readonly) long long enumConstantValue;
@property(nonatomic, readonly) unsigned long long enumConstantUnsignedValue;

/**
 * The non-variadic arguments for this cursor.
 */
@property(nonatomic, readonly) NSArray *arguments;

/**
 * The overloaded declarations for this cursor.
 */
@property(nonatomic, readonly) NSArray *overloadedDeclarations;

@property(nonatomic, readonly) int bitFieldWidth;

@property(nonatomic, readonly) PLClangObjCPropertyAttributes objCPropertyAttributes;
@property(nonatomic, readonly) PLClangCursor *objCPropertyGetter;
@property(nonatomic, readonly) PLClangCursor *objCPropertySetter;
@property(nonatomic, readonly) int objCSelectorIndex;
@property(nonatomic, readonly) NSString *objCTypeEncoding;

@property(nonatomic, readonly) PLClangAvailability *availability;

@property(nonatomic, readonly) PLClangComment *comment;
@property(nonatomic, readonly) NSString *briefComment;

- (void) visitChildrenUsingBlock: (PLClangCursorVisitorBlock) block;

@end
