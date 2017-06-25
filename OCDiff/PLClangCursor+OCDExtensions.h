#import <ObjectDoc/ObjectDoc.h>

@interface PLClangCursor (OCDExtensions)

/**
 * For a cursor representing an Objective-C class declaration, an array of
 * categories declared for the class.
 */
@property (nonatomic, readonly) NSArray<PLClangCursor *> *ocd_categories;

/**
 * Adds a category to the list of cursors returned by ocd_categories.
 */
- (void)ocd_addCategory:(PLClangCursor *)categoryCursor;

@end
