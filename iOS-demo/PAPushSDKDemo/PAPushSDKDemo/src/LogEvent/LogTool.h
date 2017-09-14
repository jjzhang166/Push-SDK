//
//  LogTool.h
//  anchor
//
//  Created by wangweishun on 8/16/16.
//  Copyright © 2016 PAJK. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LogTool : NSObject

// 获取设备当前网络IP地址
+ (NSString *)getIPAddress:(BOOL)preferIPv4;

// 获取公网IP地址
+ (NSString *)getPublicIPAdress;
+ (NSDictionary *)getPublicIPInfo;

@end
