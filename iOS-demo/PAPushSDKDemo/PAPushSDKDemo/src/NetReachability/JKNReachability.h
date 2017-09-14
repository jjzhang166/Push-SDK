//
//  JKNReachability.h
//  PAPersonalDoctor
//
//  Created by Perry Xiong on 15/10/22.
//  Copyright © 2015年 Ping An Health Insurance Company of China, Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

// 网络变化发通知
// 参数里面包含一个对象，就是JKNReachability
extern NSString *const JKNReachabilityChangedNotification;


@interface JKNReachability : NSObject

+ (JKNReachability *)reachability;

- (void)startService;
- (void)stopService;

-(BOOL)isReachable;
-(BOOL)isReachableViaWWAN;
-(BOOL)isReachableViaWiFi;

@end
