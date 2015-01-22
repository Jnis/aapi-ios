//
//  NSURL+AlterAPI.h
//  AALibrary
//
//  Created by Andrew Kopanev on 3/17/14.
//  Copyright (c) 2014 Moqod. All rights reserved.
//

#import <Foundation/Foundation.h>

// Category for AAPI integration
// More information available at: http://aapi.io
// Supports both http and https

@interface NSURL (AlterAPI)

// default is aapi.io/request
+ (void)setAaRequestURL:(NSString *)requestURL;

// default is aapi.io/request
+ (NSString *)aaRequestURL;

// sets aapi project id
// if aapi project is nil then no modifications on url applied
// copies given projectId
+ (void)setAaProjectId:(NSString *)projectId;

// return project id
+ (NSString *)aaProjectId;

// excludes URLs from aapi
// checking rule: [url hasPrefix]
// example:
// [NSURL aaaaExcludeURLs:@"http://google.com", @"https://somedomain.org/path/"];
// Then any URL started with provided params will be ignored
+ (void)aaExcludeURLs:(NSString *)urls, ... NS_REQUIRES_NIL_TERMINATION;

// includes only for these urls. By default includes every urls
// checking rule: [url hasPrefix]
+ (void)aaIncludeURLs:(NSString *)urls, ... NS_REQUIRES_NIL_TERMINATION;

// returns YES if URL contains aapi URL
@property (nonatomic, readonly) BOOL			aaIsInjected;

@end
