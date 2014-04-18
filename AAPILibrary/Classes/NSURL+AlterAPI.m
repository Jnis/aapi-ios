//
//  NSURL+AlterAPI.m
//  AALibrary
//
//  Created by Andrew Kopanev on 3/17/14.
//  Copyright (c) 2014 Moqod. All rights reserved.
//

#import "NSURL+AlterAPI.h"
#import <objc/runtime.h>
#import <AdSupport/AdSupport.h>

// temporary local address
static NSString             *aaAlterAPIRequestURL	= @"http://10.0.1.17:3000/request";

// global variables
static NSString             *aaProjectId			= nil;
static NSMutableSet			*aaExcludedHostsSet		= nil;
static NSMutableSet			*aaExcludedPathsSet		= nil;

@implementation NSURL (AlterAPI)

#pragma mark - initialization

+ (void)load {
	NSLog(@"%s", __PRETTY_FUNCTION__);
	
#ifdef DEBUG
	aaExcludedHostsSet = [[NSMutableSet alloc] init];
	aaExcludedPathsSet = [[NSMutableSet alloc] init];
	
	// swizzle NSURL constructors
	// TODO: support relativeToURL: method
	method_exchangeImplementations(class_getInstanceMethod(self, @selector(initWithString:relativeToURL:)), class_getInstanceMethod(self, @selector(aaInitWithString:relativeToURL:)));
#endif
}

#pragma mark - public

+ (void)aaExcludeHosts:(NSString *)hosts, ... NS_REQUIRES_NIL_TERMINATION {
	va_list argsList;
    va_start(argsList, hosts);
    for (NSString *arg = hosts; arg != nil; arg = va_arg(argsList, NSString *)) {
        [aaExcludedHostsSet addObject:arg];
    }
    va_end(argsList);
}

+ (void)aaExcludePaths:(NSString *)paths, ... NS_REQUIRES_NIL_TERMINATION {
	va_list argsList;
    va_start(argsList, paths);
    for (NSString *arg = paths; arg != nil; arg = va_arg(argsList, NSString *)) {
        [aaExcludedPathsSet addObject:arg];
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

#pragma mark - swizzled constructors

- (id)aaInitWithString:(NSString *)URLString relativeToURL:(NSURL *)baseURL {
	URLString = [[self class] aaURLStringByInjectingAlterAPI:URLString];
	return [self aaInitWithString:URLString relativeToURL:baseURL];
}

#pragma mark - magic

+ (BOOL)aaIsHostExcluded:(NSString *)host {
	for (NSString *excludedHost in aaExcludedHostsSet) {
		if ([host hasPrefix:excludedHost]) {
			return YES;
		}
	}
	return NO;
}

+ (BOOL)aaIsPathExcluded:(NSString *)path {
	for (NSString *excludedPath in aaExcludedPathsSet) {
		if ([path hasPrefix:excludedPath]) {
			return YES;
		}
	}
	return NO;
}

+ (NSString *)aaURLStringByInjectingAlterAPI:(NSString *)urlString {
	BOOL hasHTTPScheme = [urlString hasPrefix:@"http"] || [urlString hasPrefix:@"https"];
	if (nil != aaProjectId && YES == hasHTTPScheme) {
		NSURL *originalURL = [[NSURL alloc] aaInitWithString:urlString relativeToURL:nil];
		BOOL isHostExcluded = [self aaIsHostExcluded:originalURL.host];
		BOOL isPathExcluded = [self aaIsPathExcluded:originalURL.path];
#if !__has_feature(objc_arc)
		[originalURL release];
		originalURL = nil;
#endif
		
		if (isPathExcluded || isHostExcluded) {
			// do nothing!
		} else {
			// do the magic
			// pid - project id
			// did - device id
			// dname - device display name
			NSString *displayName = [[[UIDevice currentDevice] name] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			NSString *deviceId = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
			urlString = [NSString stringWithFormat:@"%@/pid/%@/did/%@/dname/%@/url/%@", aaAlterAPIRequestURL, [NSURL aaProjectId], deviceId, displayName, urlString];
		}
	}
	return urlString;
}

@end
