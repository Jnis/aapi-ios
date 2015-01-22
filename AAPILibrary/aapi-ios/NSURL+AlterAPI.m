//
//  NSURL+AlterAPI.m
//  AALibrary
//
//  Created by Andrew Kopanev on 3/17/14.
//  Copyright (c) 2014 Moqod. All rights reserved.
//

#import "NSURL+AlterAPI.h"
#import <objc/runtime.h>

NSString *const NSURLAlterAPIKey					= @"NSURLAlterAPIKey";

// global variables
static NSString             *aaProjectId			= nil;
static NSString             *aaRequestURL			= @"aapi.io/request";;
static NSMutableSet			*aaExcludedURLSet		= nil;
static NSMutableSet			*aaIncludedURLSet		= nil;

@implementation NSURL (AlterAPI)

#pragma mark - initialization

+ (void)load {
	aaExcludedURLSet = [NSMutableSet new];
    aaIncludedURLSet = [NSMutableSet new];
	
	// swizzle NSURL constructors
	// TODO: support relativeToURL: method
	method_exchangeImplementations(class_getInstanceMethod(self, @selector(initWithString:relativeToURL:)), class_getInstanceMethod(self, @selector(aaInitWithString:relativeToURL:)));
}

#pragma mark - public

+ (void)aaExcludeURLs:(NSString *)urls, ... NS_REQUIRES_NIL_TERMINATION {
	va_list argsList;
    va_start(argsList, urls);
    for (NSString *arg = urls; arg != nil; arg = va_arg(argsList, NSString *)) {
        [aaExcludedURLSet addObject:arg];
    }
    va_end(argsList);
}

+ (void)aaIncludeURLs:(NSString *)urls, ... NS_REQUIRES_NIL_TERMINATION {
    va_list argsList;
    va_start(argsList, urls);
    for (NSString *arg = urls; arg != nil; arg = va_arg(argsList, NSString *)) {
        [aaIncludedURLSet addObject:arg];
    }
    va_end(argsList);
}

+ (void)setAaProjectId:(NSString *)projectId {
#if !__has_feature(objc_arc)
	[aaProjectId autorelease];
#endif
	aaProjectId = [projectId copy];
}

+ (NSString *)aaProjectId {
	return aaProjectId;
}

// default is aapi.io/request
+ (void)setAaRequestURL:(NSString *)requestURL {
#if !__has_feature(objc_arc)
	[aaRequestURL autorelease];
#endif
	aaRequestURL = [requestURL copy];
}

// default is aapi.io/request
+ (NSString *)aaRequestURL {
	return aaRequestURL;
}


#pragma mark - properties

- (void)aaMarkAsInjected {
#if !__has_feature(objc_arc)
    objc_setAssociatedObject(self, NSURLAlterAPIKey, [NSNumber numberWithBool:YES], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
#else
    objc_setAssociatedObject(self, (__bridge const void *)(NSURLAlterAPIKey), [NSNumber numberWithBool:YES], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
#endif
}

- (BOOL)aaIsInjected {
#if !__has_feature(objc_arc)
	NSNumber *inj = objc_getAssociatedObject(self, NSURLAlterAPIKey);
    return [inj boolValue];
#else
    NSNumber *inj = objc_getAssociatedObject(self, (__bridge const void *)(NSURLAlterAPIKey));
	return [inj boolValue];
#endif
}

#pragma mark - swizzled constructors

- (id)aaInitWithString:(NSString *)URLString relativeToURL:(NSURL *)baseURL {
	BOOL injected = NO;
	URLString = [[self class] aaURLStringByInjectingAlterAPI:URLString injected:&injected];
	NSURL *url = [self aaInitWithString:URLString relativeToURL:baseURL];
	if (injected) {
		[url aaMarkAsInjected];
	}
	return url;
}

#pragma mark - magic

+ (BOOL)aaIsURLExcluded:(NSString *)url {
    if(aaIncludedURLSet.count){
        BOOL isExistInList = NO;
        for (NSString *excludedHost in aaIncludedURLSet) {
            if ([url hasPrefix:excludedHost]) {
                isExistInList = YES;
                break;
            }
        }
        if(!isExistInList){
            return YES;
        }
    }
    
	for (NSString *excludedHost in aaExcludedURLSet) {
		if ([url hasPrefix:excludedHost]) {
			return YES;
		}
	}
	return NO;
}

+ (NSString *)aaQueryParamsStringForURL:(NSString *)url {
	NSMutableDictionary *queryDict = [NSMutableDictionary dictionary];
	[queryDict setValue:[self aaProjectId] forKey:@"pid"];	// pid could be changed
	
	static NSMutableDictionary *deviceParams = nil;
	if (!deviceParams) {
		deviceParams = [NSMutableDictionary new];
		[deviceParams setValue:[[UIDevice currentDevice] name] forKey:@"dname"];
		[deviceParams setValue:[[UIDevice currentDevice] model] forKey:@"model"];
		[deviceParams setValue:[[UIDevice currentDevice] systemName] forKey:@"os"];
		[deviceParams setValue:[[UIDevice currentDevice] systemVersion] forKey:@"osv"];
		[deviceParams setValue:[[[UIDevice currentDevice] identifierForVendor] UUIDString] forKey:@"did"];
	}
	[queryDict addEntriesFromDictionary:deviceParams];

	NSMutableString *queryString = [NSMutableString string];
	for (NSString *key in queryDict.allKeys) {
		[queryString appendFormat:@"/%@/%@", key, [queryDict[key] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	}
	[queryString appendFormat:@"/url/%@", url];
	return queryString;
}

+ (NSString *)aaURLStringByInjectingAlterAPI:(NSString *)urlString injected:(BOOL *)injected {
	BOOL hasHTTPScheme = [urlString hasPrefix:@"http"];
	BOOL hasHTTPSScheme = [urlString hasPrefix:@"https"];
	
	*injected = NO;
	if (nil != aaProjectId && (hasHTTPSScheme || hasHTTPScheme) && [urlString rangeOfString:aaRequestURL].location == NSNotFound) {
		BOOL isExcluded = [self aaIsURLExcluded:urlString];
		if (!isExcluded) {
			// aapi parameters:
			// @required
			// pid — project id
			// did - device id
			// url - original url
			//
			// @optional
			// dname - display name
			// os - OS name
			// osv - OS version
			// model - device model name (iPod Touch, etc)
			// type - not used at the moment
			NSString *scheme = hasHTTPScheme ? @"http" : @"https";
			urlString = [NSString stringWithFormat:@"%@://%@%@", scheme, aaRequestURL, [self aaQueryParamsStringForURL:urlString]];
			*injected = YES;
		}
	}
	return urlString;
}

@end
