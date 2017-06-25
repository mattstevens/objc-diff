#import "PLClangCursor+OCDExtensions.h"
#import <objc/runtime.h>

static const void * const OCDCategoriesKey = &OCDCategoriesKey;

@interface PLClangCursor ()

@property (nonatomic, readonly) NSMutableArray<PLClangCursor *> *ocd_categories;

@end

@implementation PLClangCursor (OCDExtensions)

- (NSMutableArray<PLClangCursor *> *)ocd_categories {
    NSMutableArray *array = objc_getAssociatedObject(self, OCDCategoriesKey);
    if (array == nil) {
        array = [NSMutableArray new];
        objc_setAssociatedObject(self, OCDCategoriesKey, array, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    return array;
}

- (void)ocd_addCategory:(PLClangCursor *)categoryCursor {
    [self.ocd_categories addObject:categoryCursor];
}

@end
