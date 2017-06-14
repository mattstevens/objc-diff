#import <Foundation/Foundation.h>
#import "OCDModule.h"

@interface OCDAPIDifferences : NSObject

+ (instancetype)APIDifferencesWithModules:(NSArray<OCDModule *> *)modules;

@property (nonatomic, readonly) NSArray<OCDModule *> *modules;

@end

