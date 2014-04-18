//
//  NSURL+AlterAPI.h
//  AALibrary
//
//  Created by Andrew Kopanev on 3/17/14.
//  Copyright (c) 2014 Moqod. All rights reserved.
//

#import <Foundation/Foundation.h>

// Category for AAPI integration
// More information available at: http://aapi.io or http://alterapi.com
// Requires AdSupport.framework

@interface NSURL (AlterAPI)

// sets aapi project id
// if aapi project is nil then no modifications on url applied
// copies given projectId
+ (void)setAaProjectId:(NSString *)projectId;

// return project id
+ (NSString *)aaProjectId;

// exclude hosts from aapi service
// checking rule: host hasPrefix :excludedHost
+ (void)aaExcludeHosts:(NSString *)hosts, ... NS_REQUIRES_NIL_TERMINATION;

// exclude specific paths from aapi service
// checking rule: path hasPrefix :excludedPath
// for example - you can exclude paths where you post secure data (login / password pair, etc)
+ (void)aaExcludePaths:(NSString *)paths, ... NS_REQUIRES_NIL_TERMINATION;

@end
