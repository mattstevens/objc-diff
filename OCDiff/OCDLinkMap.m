#import "OCDLinkMap.h"

@implementation OCDLinkMap {
    NSURL *_baseURL;
    NSString *_query;
    NSDictionary *_USRMap;
}

- (instancetype)initWithPath:(NSString *)path {
    self = [super init];
    if (self) {
        NSDictionary *linkMap = [NSDictionary dictionaryWithContentsOfFile:path];
        if (!linkMap) {
            return nil;
        }

        _baseURL = [NSURL URLWithString:linkMap[@"BaseURL"]];
        if (_baseURL == nil) {
            return nil;
        }

        _query = linkMap[@"Query"];

        _USRMap = linkMap[@"USRMap"];
        if (_USRMap == nil) {
            return nil;
        }
    }

    return self;
}

- (NSURL *)URLForUSR:(NSString *)USR {
    NSString *path = _USRMap[USR];
    if (path.length == 0) {
        return nil;
    }

    NSURL *url = [_baseURL URLByAppendingPathComponent:path];
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    components.query = _query;

    return components.URL;
}

@end

