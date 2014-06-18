/*
 * Copyright (c) 2013 Plausible Labs Cooperative, Inc.
 * All rights reserved.
 */

#import <Foundation/Foundation.h>

/**
 * The kind of a PLClangComment.
 */
typedef NS_ENUM(NSUInteger, PLClangCommentKind) {
    /** Inline text. */
    PLClangCommentKindText                 = 1,

    /** An inline command with word-like arguments, such as "\@c command". */
    PLClangCommentKindInlineCommand        = 2,

    /** An HTML start tag. */
    PLClangCommentKindHTMLStartTag         = 3,

    /** An HTML end tag. */
    PLClangCommentKindHTMLEndTag           = 4,

    /** A paragraph. */
    PLClangCommentKindParagraph            = 5,

    /**
     * A command that has zero or more word-like arguments and a paragraph argument.
     *
     * For example, \@brief has zero word-like arguments and a paragraph argument.
     */
    PLClangCommentKindBlockCommand         = 6,

    /** A \@param command that describes a parameter. */
    PLClangCommentKindParamCommand         = 7,

    /** A \@tparam command that describes a template parameter. */
    PLClangCommentKindTParamCommand        = 8,

    /**
     * A verbatim block command such as preformatted code.
     *
     * A verbatim block has opening and closing commands and contains multiple
     * lines of text as child nodes. For example:
     *
     * \@verbatim
     * text
     * \@endverbatim
     */
    PLClangCommentKindVerbatimBlockCommand = 9,

    /** A line of text contained within a verbatim block command. */
    PLClangCommentKindVerbatimBlockLine    = 10,

    /**
     * A verbatim line command.
     *
     * A verbatim line has an opening command and a single line of text.
     * It does not have a closing command.
     */
    PLClangCommentKindVerbatimLine         = 11,

    /** A full comment attached to an entity. */
    PLClangCommentKindFullComment          = 12
};

/**
 * A rendering hint for a PLClangComment.
 */
typedef NS_ENUM(NSUInteger, PLClangCommentRenderKind) {
    PLClangCommentRenderKindNormal     = 1,
    PLClangCommentRenderKindBold       = 2,
    PLClangCommentRenderKindMonospaced = 3,
    PLClangCommentRenderKindEmphasized = 4
};

@interface PLClangComment : NSObject

@property(nonatomic, readonly) PLClangCommentKind kind;
@property(nonatomic, readonly) PLClangCommentRenderKind renderKind;

/**
 * The name of an inline or block command, or nil if this comment has no command name.
 */
@property(nonatomic, readonly) NSString *commandName;

/**
 * The arguments for an inline or block command.
 */
@property(nonatomic, readonly) NSArray *arguments;

/**
 * The paragraph comment node for a block command, or nil if this comment does not represent a block command.
 */
@property(nonatomic, readonly) PLClangComment *paragraph;

/**
 * A Boolean value indicating whether the parameter that this comment node represents
 * was found in the function or method.
 */
@property(nonatomic, readonly) BOOL isParameterIndexValid;

/**
 * The zero-based index of the parameter in the function or method.
 */
@property(nonatomic, readonly) NSUInteger parameterIndex;

/**
 * The parameter's name, or nil if this comment does not represent a parameter.
 */
@property(nonatomic, readonly) NSString *parameterName;

/**
 * The text content of this comment, or nil if the comment has no text content.
 */
@property(nonatomic, readonly) NSString *text;

/**
 * A Boolean value indicating whether or not this comment contains only whitespace.
 */
@property(nonatomic, readonly) BOOL isWhitespace;

/**
 * The children of this comment node.
 */
@property(nonatomic, readonly) NSArray *children;

@end
