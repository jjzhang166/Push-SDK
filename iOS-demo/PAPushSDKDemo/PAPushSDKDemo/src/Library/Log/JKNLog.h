//
//  PALog.h
//  PALog
//
//  Created by Perry on 15/1/8.
//  Copyright (c) 2015年 PAJK. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for PALog.
FOUNDATION_EXPORT double PALogVersionNumber;

//! Project version string for PALog.
FOUNDATION_EXPORT const unsigned char PALogVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <PALog/PublicHeader.h>
#import "CocoaLumberjack.h"

// 重新定义，如果以后换库，使用的地方不用修改
// 兼容之前的方式
#define PAError    DDLogError
#define PAWarning     DDLogWarn
#define PAInfo     DDLogInfo
#define PADebug    DDLogDebug
#define PAVerbose  DDLogVerbose

#define PALogError    DDLogError
#define PALogWarn     DDLogWarn
#define PALogInfo     DDLogInfo
#define PALogDebug    DDLogDebug
#define PALogVerbose  DDLogVerbose
// 新的方式
#define LogError    DDLogError
#define LogWarn     DDLogWarn
#define LogInfo     DDLogInfo
#define LogDebug    DDLogDebug
#define LogVerbose  DDLogVerbose

FOUNDATION_EXPORT const DDLogLevel ddLogLevel;

