//
//  AppDelegate.m
//  CustomLogFormatting
//
//  Created by Ryan Maloney on 2/26/15.
//  Copyright (c) 2015 Ryan Maloney. All rights reserved.
//

#import <RMLogFormatter/RMLogFormatter.h>

#import "AppDelegate.h"

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    RMLogFormatter *logFormatter = [[RMLogFormatter alloc] init];
    
    [[DDTTYLogger sharedInstance] setLogFormatter:logFormatter];
    
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
    [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor colorWithRed:0.7294 green:0.2078 blue:0.1843 alpha:1.0] backgroundColor:nil forFlag:DDLogFlagError];
    [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor colorWithRed:0.9686 green:0.6627 blue:0.0902 alpha:1.0] backgroundColor:nil forFlag:DDLogFlagWarning];
    [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor colorWithRed:0.2510 green:0.4941 blue:0.7216 alpha:1.0] backgroundColor:nil forFlag:DDLogFlagInfo];
    [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor colorWithRed:0.3765 green:0.2588 blue:0.6314 alpha:1.0] backgroundColor:nil forFlag:DDLogFlagDebug];
    [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor colorWithRed:0.9255 green:0.9412 blue:0.9451 alpha:1.0] backgroundColor:nil forFlag:DDLogFlagVerbose];
    
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    DDLogVerbose(@"Verbose");
    DDLogDebug(@"Debug");
    DDLogInfo(@"Info");
    DDLogWarn(@"Warn");
    DDLogError(@"Error");
    
    DDLogVerbose(@"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.");
    
    return YES;
}

@end
