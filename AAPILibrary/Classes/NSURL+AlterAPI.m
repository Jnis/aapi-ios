//
//  NSURL+AlterAPI.m
//  AALibrary
//
//  Created by Andrew Kopanev on 3/17/14.
//  Copyright (c) 2014 Moqod. All rights reserved.
//

#import "NSURL+AlterAPI.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

NSString *const NSURLAlterAPIKey					= @"NSURLAlterAPIKey";

// temporary local address
static NSString				*aaRequestAPI			= @"aapi.io/request";

// global variables
static NSString             *aaProjectId			= nil;
static NSMutableSet			*aaExcludedURLSet		= nil;

@implementation NSURL (AlterAPI)

#pragma mark - initialization

+ (void)load {
	aaExcludedURLSet = [NSMutableSet new];
	
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

+ (void)setAaProjectId:(NSString *)projectId {
#if !__has_feature(objc_arc)
	[aaProjectId autorelease];
#endif
	aaProjectId = [projectId copy];
}

+ (NSString *)aaProjectId {
	return aaProjectId;
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
	for (NSString *excludedHost in aaExcludedURLSet) {
		if ([url hasPrefix:excludedHost]) {
			return YES;
		}
	}
	return NO;
}

+ (NSString *)aaURLStringByInjectingAlterAPI:(NSString *)urlString injected:(BOOL *)injected {
	BOOL hasHTTPScheme = [urlString hasPrefix:@"http"];
	BOOL hasHTTPSScheme = [urlString hasPrefix:@"https"];
	
	*injected = NO;
	if (nil != aaProjectId && (hasHTTPSScheme || hasHTTPScheme) && [urlString rangeOfString:aaRequestAPI].location == NSNotFound) {
		BOOL isExcluded = [self aaIsURLExcluded:urlString];
		if (!isExcluded) {
			// do the magic
			// pid - project id
			// did - device id
			// dname - device display name
			// url - original URL
			NSString *displayName = [[[UIDevice currentDevice] name] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			NSString *deviceId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
			NSString *scheme = hasHTTPScheme ? @"http" : @"https";
			urlString = [NSString stringWithFormat:@"%@://%@/pid/%@/did/%@/dname/%@/url/%@", scheme, aaRequestAPI, [NSURL aaProjectId], deviceId, displayName, urlString];
			
			*injected = YES;
		}
	}
	return urlString;
}

@end
